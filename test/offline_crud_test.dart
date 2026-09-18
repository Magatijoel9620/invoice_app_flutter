import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoice_easy/models/customer.dart';
import 'package:invoice_easy/models/product.dart';
import 'package:invoice_easy/services/local_store.dart';
import 'package:invoice_easy/services/repositories.dart';
import 'package:invoice_easy/services/sync_queue.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.initialize();
  });

  test('customer writes are local-first and queued', () async {
    final repository = CustomerRepository();
    final customer = Customer(id: 'c1', name: 'Offline Customer');

    await repository.upsert(customer);

    expect((await repository.all()).single.name, 'Offline Customer');
    expect((await SyncQueue().all()).single.entity, 'customer');

    await repository.delete('c1');

    expect(await repository.all(), isEmpty);
    expect((await SyncQueue().all()).single.operation, 'delete');
  });

  test('product edits replace local data immediately', () async {
    final repository = ProductRepository();
    await repository.upsert(ProductItem(id: 'p1', name: 'Service', price: 100));
    await repository.upsert(ProductItem(id: 'p1', name: 'Updated Service', price: 250));

    final items = await repository.all();
    expect(items, hasLength(1));
    expect(items.single.name, 'Updated Service');
    expect(items.single.price, 250);
  });
}
