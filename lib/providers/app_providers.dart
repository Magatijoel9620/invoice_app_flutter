import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/business_profile.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../services/account_profile_service.dart';
import '../services/auth_service.dart';
import '../services/repositories.dart';
import '../services/sync_queue.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_status.dart';

final authServiceProvider = Provider((_) => AuthService());
final accountProfileServiceProvider = Provider((_) => AccountProfileService());
final syncStatusProvider = ChangeNotifierProvider((_) => SyncStatus());

final connectivityProvider = ChangeNotifierProvider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  unawaited(service.start());
  ref.onDispose(service.dispose);
  return service;
});

final syncQueueProvider = ChangeNotifierProvider<SyncQueue>((_) => SyncQueue());

final businessRepositoryProvider = Provider((_) => BusinessRepository());
final customerRepositoryProvider = Provider((_) => CustomerRepository());
final productRepositoryProvider = Provider((_) => ProductRepository());
final invoiceRepositoryProvider = Provider((_) => InvoiceRepository());

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    businessRepository: ref.read(businessRepositoryProvider),
    customerRepository: ref.read(customerRepositoryProvider),
    productRepository: ref.read(productRepositoryProvider),
    invoiceRepository: ref.read(invoiceRepositoryProvider),
    queue: ref.read(syncQueueProvider),
    status: ref.read(syncStatusProvider),
    connectivity: ref.read(connectivityProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final businessProvider =
    AsyncNotifierProvider<BusinessNotifier, BusinessProfile>(
      BusinessNotifier.new,
    );

class BusinessNotifier extends AsyncNotifier<BusinessProfile> {
  @override
  Future<BusinessProfile> build() async =>
      await ref.read(businessRepositoryProvider).get() ??
      BusinessProfile(
        id: 'default',
        name: 'My Business',
        businessType: 'Other',
      );
  Future<void> save(BusinessProfile business) async {
    final value = business.copyWith(updatedAt: DateTime.now().toUtc());
    state = AsyncData(value);
    await ref.read(businessRepositoryProvider).save(value);
  }
}

final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
      CustomersNotifier.new,
    );

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() => ref.read(customerRepositoryProvider).all();
  Future<void> upsert(Customer customer) async {
    await ref.read(customerRepositoryProvider).upsert(customer);
    state = AsyncData(await ref.read(customerRepositoryProvider).all());
  }

  Future<void> delete(String id) async {
    await ref.read(customerRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(customerRepositoryProvider).all());
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<ProductItem>>(
      ProductsNotifier.new,
    );

class ProductsNotifier extends AsyncNotifier<List<ProductItem>> {
  @override
  Future<List<ProductItem>> build() =>
      ref.read(productRepositoryProvider).all();
  Future<void> upsert(ProductItem product) async {
    await ref.read(productRepositoryProvider).upsert(product);
    state = AsyncData(await ref.read(productRepositoryProvider).all());
  }

  Future<void> delete(String id) async {
    await ref.read(productRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(productRepositoryProvider).all());
  }
}

final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier, List<Invoice>>(
  InvoicesNotifier.new,
);

class InvoicesNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() => ref.read(invoiceRepositoryProvider).all();
  Future<void> upsert(Invoice invoice) async {
    await ref.read(invoiceRepositoryProvider).upsert(invoice);
    state = AsyncData(await ref.read(invoiceRepositoryProvider).all());
  }

  Future<void> delete(String id) async {
    await ref.read(invoiceRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(invoiceRepositoryProvider).all());
  }
}

final accountProfileProvider = FutureProvider<AccountProfile>(
  (ref) => ref.read(accountProfileServiceProvider).get(),
);
final uuidProvider = Provider((_) => const Uuid());
