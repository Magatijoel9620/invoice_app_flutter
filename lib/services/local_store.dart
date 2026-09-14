import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage with account-scoped namespaces.
///
/// Before authentication the app uses the anonymous scope. On first login,
/// [switchToUserScope] can migrate the anonymous workspace into the user's
/// private local namespace. This prevents a second account on the same device
/// from seeing another account's invoices.
class LocalStore {
  static const _scopeKey = 'ie_local_scope_v1';
  static const _anonymousScope = 'anonymous';
  static const _businessKey = 'ie_business_profile_v2';
  static const _customersKey = 'ie_customers_v2';
  static const _productsKey = 'ie_products_v2';
  static const _invoicesKey = 'ie_invoices_v2';

  static String _scope = _anonymousScope;

  static String _storageKey(String key) => '$_scopeKey/$_scope/$key';

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _scope = prefs.getString(_scopeKey) ?? _anonymousScope;

    // Move pre-V3 unscoped local data into the anonymous namespace once.
    for (final key in const [
      _businessKey,
      _customersKey,
      _productsKey,
      _invoicesKey,
      'ie_sync_queue_v1',
    ]) {
      final scoped = '$_scopeKey/$_anonymousScope/$key';
      if (prefs.containsKey(scoped) || !prefs.containsKey(key)) continue;
      final value = prefs.get(key);
      if (value is String) await prefs.setString(scoped, value);
      if (value is int) await prefs.setInt(scoped, value);
      if (value is double) await prefs.setDouble(scoped, value);
      if (value is bool) await prefs.setBool(scoped, value);
    }
  }

  static String get currentScope => _scope;

  static Future<bool> switchToUserScope(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final target = userId.trim();
    if (target.isEmpty) return false;

    final targetScope = target;
    final targetBusiness = '$_scopeKey/$targetScope/$_businessKey';
    final hasTargetData = prefs.containsKey(targetBusiness);
    final anonymousBusiness = '$_scopeKey/$_anonymousScope/$_businessKey';
    final shouldMigrate = !hasTargetData && prefs.containsKey(anonymousBusiness);

    if (shouldMigrate && _scope == _anonymousScope) {
      for (final key in const [
        _businessKey,
        _customersKey,
        _productsKey,
        _invoicesKey,
        'ie_sync_queue_v1',
      ]) {
        final from = '$_scopeKey/$_anonymousScope/$key';
        final to = '$_scopeKey/$targetScope/$key';
        final value = prefs.get(from);
        if (value is String) await prefs.setString(to, value);
        if (value is int) await prefs.setInt(to, value);
        if (value is double) await prefs.setDouble(to, value);
        if (value is bool) await prefs.setBool(to, value);
      }
    }

    _scope = targetScope;
    await prefs.setString(_scopeKey, _scope);
    return shouldMigrate;
  }

  static Future<void> switchToAnonymousScope() async {
    final prefs = await SharedPreferences.getInstance();
    _scope = _anonymousScope;
    await prefs.setString(_scopeKey, _scope);
  }

  static Future<List<Map<String, dynamic>>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(key));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> writeList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(key), jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> readObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeObject(
    String key,
    Map<String, dynamic> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(key), jsonEncode(value));
  }
}
