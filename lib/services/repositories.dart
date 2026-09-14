import 'package:uuid/uuid.dart';
import '../models/business_profile.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import 'local_store.dart';
import 'sync_queue.dart';

class BusinessRepository {
  static const key = 'ie_business_profile_v2';
  final SyncQueue _queue = SyncQueue();

  Future<BusinessProfile?> get() async {
    final j = await LocalStore.readObject(key);
    return j == null ? null : BusinessProfile.fromJson(j);
  }

  Future<void> save(BusinessProfile business, {bool queue = true}) async {
    final value = business.copyWith(updatedAt: DateTime.now().toUtc());
    await LocalStore.writeObject(key, value.toJson());
    if (queue) {
      await _queue.enqueue(PendingChange(entity: 'business', id: value.id, operation: 'upsert', updatedAt: value.updatedAt, payload: value.toJson()));
    }
  }

  Future<void> replace(BusinessProfile business) => LocalStore.writeObject(key, business.toJson());
}

class CustomerRepository {
  static const key = 'ie_customers_v2';
  final SyncQueue _queue = SyncQueue();

  Future<List<Customer>> all() async => (await LocalStore.readList(key)).map(Customer.fromJson).toList();
  Future<void> saveAll(List<Customer> value) => LocalStore.writeList(key, value.map((e) => e.toJson()).toList());

  Future<void> upsert(Customer customer, {bool queue = true}) async {
    final value = customer.copyWith(updatedAt: DateTime.now().toUtc());
    final allItems = await all();
    final index = allItems.indexWhere((x) => x.id == value.id);
    if (index < 0) {
      allItems.add(value);
    } else {
      allItems[index] = value;
    }
    await saveAll(allItems);
    if (queue) await _queue.enqueue(PendingChange(entity: 'customer', id: value.id, operation: 'upsert', updatedAt: value.updatedAt, payload: value.toJson()));
  }

  Future<void> replace(Customer customer) async {
    final items = await all();
    final index = items.indexWhere((x) => x.id == customer.id);
    if (index < 0) {
      items.add(customer);
    } else {
      items[index] = customer;
    }
    await saveAll(items);
  }

  Future<void> delete(String id, {bool queue = true}) async {
    final items = await all();
    items.removeWhere((x) => x.id == id);
    await saveAll(items);
    if (queue) await _queue.enqueue(PendingChange(entity: 'customer', id: id, operation: 'delete', updatedAt: DateTime.now().toUtc()));
  }
}

class ProductRepository {
  static const key = 'ie_products_v2';
  final SyncQueue _queue = SyncQueue();

  Future<List<ProductItem>> all() async => (await LocalStore.readList(key)).map(ProductItem.fromJson).toList();
  Future<void> saveAll(List<ProductItem> value) => LocalStore.writeList(key, value.map((e) => e.toJson()).toList());

  Future<void> upsert(ProductItem product, {bool queue = true}) async {
    final value = product.copyWith(updatedAt: DateTime.now().toUtc());
    final items = await all();
    final index = items.indexWhere((x) => x.id == value.id);
    if (index < 0) {
      items.add(value);
    } else {
      items[index] = value;
    }
    await saveAll(items);
    if (queue) await _queue.enqueue(PendingChange(entity: 'product', id: value.id, operation: 'upsert', updatedAt: value.updatedAt, payload: value.toJson()));
  }

  Future<void> replace(ProductItem product) async {
    final items = await all();
    final index = items.indexWhere((x) => x.id == product.id);
    if (index < 0) {
      items.add(product);
    } else {
      items[index] = product;
    }
    await saveAll(items);
  }

  Future<void> delete(String id, {bool queue = true}) async {
    final items = await all();
    items.removeWhere((x) => x.id == id);
    await saveAll(items);
    if (queue) await _queue.enqueue(PendingChange(entity: 'product', id: id, operation: 'delete', updatedAt: DateTime.now().toUtc()));
  }
}

class InvoiceRepository {
  static const key = 'ie_invoices_v2';
  final _uuid = const Uuid();
  final SyncQueue _queue = SyncQueue();

  Future<List<Invoice>> all() async {
    final value = (await LocalStore.readList(key)).map(Invoice.fromJson).toList();
    value.sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return value;
  }

  Future<void> saveAll(List<Invoice> value) => LocalStore.writeList(key, value.map((e) => e.toJson()).toList());

  Future<void> upsert(Invoice invoice, {bool queue = true}) async {
    final value = invoice.copyWith(updatedAt: DateTime.now().toUtc());
    final items = await all();
    final index = items.indexWhere((x) => x.id == value.id);
    if (index < 0) {
      items.add(value);
    } else {
      items[index] = value;
    }
    await saveAll(items);
    if (queue) await _queue.enqueue(PendingChange(entity: 'invoice', id: value.id, operation: 'upsert', updatedAt: value.updatedAt, payload: value.toJson()));
  }

  Future<void> replace(Invoice invoice) async {
    final items = await all();
    final index = items.indexWhere((x) => x.id == invoice.id);
    if (index < 0) {
      items.add(invoice);
    } else {
      items[index] = invoice;
    }
    await saveAll(items);
  }

  String newId() => _uuid.v4();

  Future<void> delete(String id, {bool queue = true}) async {
    final items = await all();
    items.removeWhere((x) => x.id == id);
    await saveAll(items);
    if (queue) await _queue.enqueue(PendingChange(entity: 'invoice', id: id, operation: 'delete', updatedAt: DateTime.now().toUtc()));
  }
}
