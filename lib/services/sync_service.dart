import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_profile.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import 'cloud_mapper.dart';
import 'repositories.dart';
import 'sync_queue.dart';
import 'sync_status.dart';
import 'supabase_service.dart';

/// Offline-first synchronization for InvoiceEasy.
///
/// Conflict policy: last-write-wins using the client model's updatedAt and the
/// cloud row's updated_at. Deletes are represented by cloud tombstones so a
/// deleted record cannot reappear on another device.
class SyncService {
  final BusinessRepository businessRepository;
  final CustomerRepository customerRepository;
  final ProductRepository productRepository;
  final InvoiceRepository invoiceRepository;
  final SyncQueue queue;
  final SyncStatus status;

  bool _running = false;

  SyncService({
    required this.businessRepository,
    required this.customerRepository,
    required this.productRepository,
    required this.invoiceRepository,
    required this.queue,
    required this.status,
  });

  SupabaseClient get client => SupabaseService.client;
  User get user => client.auth.currentUser!;

  Future<void> bootstrap() async {
    await sync(isBootstrap: true);
  }

  Future<void> sync({bool isBootstrap = false}) async {
    if (_running) return;

    if (!SupabaseService.initialized ||
        SupabaseService.tryClient?.auth.currentUser == null) {
      status.setState(SyncState.offline, message: 'Cloud is not connected.');
      status.setPending((await queue.all()).length);
      return;
    }

    _running = true;
    status.setState(SyncState.syncing);
    try {
      Object? lastError;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          await _syncOnce(isBootstrap: isBootstrap);
          lastError = null;
          break;
        } catch (error) {
          lastError = error;
          if (attempt < 3) {
            await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }
      if (lastError != null) throw lastError;

      status.setPending((await queue.all()).length);
      status.markSynced();
    } catch (error) {
      status.setState(SyncState.error, message: _friendlyError(error));
      status.setPending((await queue.all()).length);
      rethrow;
    } finally {
      _running = false;
    }
  }

  Future<void> _syncOnce({required bool isBootstrap}) async {
    final localBusiness = await businessRepository.get();

    // First pull the single cloud business. This is important on a fresh
    // device: an empty local database must bootstrap from the cloud rather
    // than manufacture a local placeholder and overwrite the cloud copy.
    final cloudBusinessRow = await client
        .from('businesses')
        .select()
        .eq('owner_id', user.id)
        .maybeSingle();

    final business = await _resolveBusiness(localBusiness, cloudBusinessRow);
    if (business == null) {
      // No business has been configured yet. There is nothing else to sync.
      return;
    }

    await _mergeChildren(business.id);
    await _pushPending(business);

    // Pull once more after pushing. PostgreSQL triggers may update server
    // timestamps, and this final pull makes every device converge on the
    // server representation after a successful write.
    await _pullBusinessAndChildren(business.id);
  }

  Future<BusinessProfile?> _resolveBusiness(
    BusinessProfile? local,
    dynamic cloudValue,
  ) async {
    final cloud = cloudValue == null
        ? null
        : Map<String, dynamic>.from(cloudValue as Map);

    if (cloud != null && cloud['deleted_at'] != null) {
      // A cloud tombstone wins over an empty/default local profile. Do not
      // recreate a deleted business during first-login bootstrap.
      return null;
    }

    if (cloud != null) {
      final cloudTime = _cloudTime(cloud);
      if (local == null ||
          local.id == 'default' ||
          !local.updatedAt.isAfter(cloudTime)) {
        final data = _map(cloud['data']);
        final pulled = BusinessProfile.fromJson(data);
        await businessRepository.replace(pulled);
        await _removePending('business', local?.id);
        await _rebindLocalInvoices(pulled.id);
        return pulled;
      }
      return local;
    }

    if (local == null) return null;

    // No cloud business exists. Turn the pre-authenticated local identity into
    // the authenticated user's canonical business id and queue it for upload.
    final migrated = local.id != user.id
        ? local.copyWith(id: user.id, updatedAt: DateTime.now().toUtc())
        : local;
    if (migrated.id != local.id || migrated.updatedAt != local.updatedAt) {
      await businessRepository.replace(migrated);
    }
    await _rebindLocalInvoices(migrated.id);
    await _removePending('business', local.id);
    await queue.enqueue(
      PendingChange(
        entity: 'business',
        id: migrated.id,
        operation: 'upsert',
        updatedAt: migrated.updatedAt,
        payload: migrated.toJson(),
      ),
    );
    return migrated;
  }

  Future<void> _rebindLocalInvoices(String businessId) async {
    final invoices = await invoiceRepository.all();
    for (final invoice in invoices.where(
      (item) => item.businessId != businessId,
    )) {
      final rebound = invoice.copyWith(businessId: businessId);
      await invoiceRepository.replace(rebound);
      await _removePending('invoice', invoice.id);
      await queue.enqueue(
        PendingChange(
          entity: 'invoice',
          id: rebound.id,
          operation: 'upsert',
          updatedAt: rebound.updatedAt,
          payload: rebound.toJson(),
        ),
      );
    }
  }

  Future<void> _mergeChildren(String businessId) async {
    await _mergeCustomers(await _rowsFor('customers', businessId));
    await _mergeProducts(await _rowsFor('products', businessId));
    await _mergeInvoices(await _rowsFor('invoices', businessId));
  }

  Future<void> _pullBusinessAndChildren(String businessId) async {
    final businessRow = await client
        .from('businesses')
        .select()
        .eq('owner_id', user.id)
        .maybeSingle();
    if (businessRow != null && businessRow['deleted_at'] == null) {
      final local = await businessRepository.get();
      final row = Map<String, dynamic>.from(businessRow);
      if (local == null || !_isNewer(local.updatedAt, _cloudTime(row))) {
        await businessRepository.replace(
          BusinessProfile.fromJson(_map(row['data'])),
        );
      }
    }
    await _mergeChildren(businessId);
  }

  Future<List<Map<String, dynamic>>> _rowsFor(
    String table,
    String businessId,
  ) async {
    final rows = await client
        .from(table)
        .select()
        .eq('business_id', businessId);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> _mergeCustomers(List<Map<String, dynamic>> rows) async {
    final local = await customerRepository.all();
    final pending = await queue.all();
    final cloudIds = <String>{};

    for (final row in rows) {
      final id = row['id'].toString();
      cloudIds.add(id);
      final localItem = local.where((x) => x.id == id).firstOrNull;
      final localPending = pending
          .where((c) => c.entity == 'customer' && c.id == id)
          .firstOrNull;
      if (_localWins(localItem?.updatedAt, localPending?.updatedAt, row)) {
        continue;
      }

      if (_cloudIsDeleted(row)) {
        await customerRepository.delete(id, queue: false);
      } else {
        await customerRepository.replace(Customer.fromJson(_map(row['data'])));
      }
      if (localPending != null) await queue.remove(localPending);
    }

    for (final item in local) {
      if (!cloudIds.contains(item.id) &&
          !pending.any((c) => c.entity == 'customer' && c.id == item.id)) {
        await queue.enqueue(
          _upsertChange('customer', item.id, item.updatedAt, item.toJson()),
        );
      }
    }
  }

  Future<void> _mergeProducts(List<Map<String, dynamic>> rows) async {
    final local = await productRepository.all();
    final pending = await queue.all();
    final cloudIds = <String>{};

    for (final row in rows) {
      final id = row['id'].toString();
      cloudIds.add(id);
      final localItem = local.where((x) => x.id == id).firstOrNull;
      final localPending = pending
          .where((c) => c.entity == 'product' && c.id == id)
          .firstOrNull;
      if (_localWins(localItem?.updatedAt, localPending?.updatedAt, row)) {
        continue;
      }

      if (_cloudIsDeleted(row)) {
        await productRepository.delete(id, queue: false);
      } else {
        await productRepository.replace(
          ProductItem.fromJson(_map(row['data'])),
        );
      }
      if (localPending != null) await queue.remove(localPending);
    }

    for (final item in local) {
      if (!cloudIds.contains(item.id) &&
          !pending.any((c) => c.entity == 'product' && c.id == item.id)) {
        await queue.enqueue(
          _upsertChange('product', item.id, item.updatedAt, item.toJson()),
        );
      }
    }
  }

  Future<void> _mergeInvoices(List<Map<String, dynamic>> rows) async {
    final local = await invoiceRepository.all();
    final pending = await queue.all();
    final cloudIds = <String>{};

    for (final row in rows) {
      final id = row['id'].toString();
      cloudIds.add(id);
      final localItem = local.where((x) => x.id == id).firstOrNull;
      final localPending = pending
          .where((c) => c.entity == 'invoice' && c.id == id)
          .firstOrNull;
      if (_localWins(localItem?.updatedAt, localPending?.updatedAt, row)) {
        continue;
      }

      if (_cloudIsDeleted(row)) {
        await invoiceRepository.delete(id, queue: false);
      } else {
        await invoiceRepository.replace(Invoice.fromJson(_map(row['data'])));
      }
      if (localPending != null) await queue.remove(localPending);
    }

    for (final item in local) {
      if (!cloudIds.contains(item.id) &&
          !pending.any((c) => c.entity == 'invoice' && c.id == item.id)) {
        await queue.enqueue(
          _upsertChange('invoice', item.id, item.updatedAt, item.toJson()),
        );
      }
    }
  }

  bool _isNewer(DateTime left, DateTime right) =>
      left.toUtc().isAfter(right.toUtc());

  bool _localWins(
    DateTime? localTime,
    DateTime? pendingTime,
    Map<String, dynamic> cloud,
  ) {
    final cloudTime = _cloudTime(cloud);
    final candidate =
        pendingTime != null &&
            (localTime == null || pendingTime.isAfter(localTime))
        ? pendingTime
        : localTime;
    return candidate != null && candidate.toUtc().isAfter(cloudTime);
  }

  Future<void> _pushPending(BusinessProfile business) async {
    final items = await queue.all();
    for (final change in items) {
      if (change.entity != 'business' && change.operation != 'delete') {
        // Ensure child payloads are always scoped to the currently authenticated
        // business. This also prevents stale queues from another identity from
        // crossing account boundaries.
        if (business.id != user.id) continue;
      }

      final row = await _cloudRow(change, business.id);
      final cloudTime = row == null ? null : _cloudTime(row);
      if (cloudTime != null && cloudTime.isAfter(change.updatedAt.toUtc())) {
        await queue.remove(change);
        continue;
      }

      if (change.entity == 'business') {
        if (change.operation == 'delete') {
          await client
              .from('businesses')
              .update({
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
                'updated_at': change.updatedAt.toUtc().toIso8601String(),
              })
              .eq('owner_id', user.id);
        } else {
          final model = BusinessProfile.fromJson(change.payload!);
          await client
              .from('businesses')
              .upsert(
                CloudMapper.business(model, user.id),
                onConflict: 'owner_id',
              );
        }
      } else {
        final table = '${change.entity}s';
        final common = <String, dynamic>{
          'id': change.id,
          'owner_id': user.id,
          'business_id': business.id,
          'updated_at': change.updatedAt.toUtc().toIso8601String(),
        };
        if (change.operation == 'delete') {
          await client.from(table).upsert({
            ...common,
            'data': <String, dynamic>{},
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          await client.from(table).upsert({
            ...common,
            'data': change.payload,
            'deleted_at': null,
          });
        }
      }
      await queue.remove(change);
    }
  }

  Future<Map<String, dynamic>?> _cloudRow(
    PendingChange change,
    String businessId,
  ) async {
    if (change.entity == 'business') {
      final row = await client
          .from('businesses')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    }
    final row = await client
        .from('${change.entity}s')
        .select()
        .eq('id', change.id)
        .eq('business_id', businessId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  PendingChange _upsertChange(
    String entity,
    String id,
    DateTime updatedAt,
    Map<String, dynamic> payload,
  ) => PendingChange(
    entity: entity,
    id: id,
    operation: 'upsert',
    updatedAt: updatedAt,
    payload: payload,
  );

  Future<void> _removePending(String entity, String? id) async {
    if (id == null) return;
    final pending = await queue.all();
    for (final change
        in pending.where((c) => c.entity == entity && c.id == id).toList()) {
      await queue.remove(change);
    }
  }

  DateTime _cloudTime(Map<String, dynamic> row) =>
      DateTime.tryParse(row['updated_at']?.toString() ?? '')?.toUtc() ??
      DateTime(2000);

  bool _cloudIsDeleted(Map<String, dynamic> row) => row['deleted_at'] != null;

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from((value as Map?) ?? <String, dynamic>{});

  String _friendlyError(Object error) {
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    return error.toString();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
