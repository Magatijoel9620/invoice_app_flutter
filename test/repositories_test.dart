import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoice_easy/models/business_profile.dart';
import 'package:invoice_easy/models/invoice.dart';
import 'package:invoice_easy/services/local_store.dart';
import 'package:invoice_easy/services/repositories.dart';
import 'package:invoice_easy/services/sync_queue.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.initialize();
  });

  test('business repository saves local data and queues the mutation', () async {
    final repository = BusinessRepository();
    final business = BusinessProfile(
      id: 'b1',
      name: 'Acme Ltd',
      businessType: 'Services',
    );

    await repository.save(business);

    final stored = await repository.get();
    expect(stored?.name, 'Acme Ltd');
    expect((await SyncQueue().all()).single.entity, 'business');
  });

  test('invoice repository sorts by issue date descending', () async {
    final repository = InvoiceRepository();
    final older = Invoice(
      id: 'old',
      businessId: 'b1',
      customerId: 'c1',
      customerName: 'Customer',
      number: 'INV-1',
      issueDate: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 15),
      lines: const [],
    );
    final newer = older.copyWith(
      id: 'new',
      number: 'INV-2',
      issueDate: DateTime(2026, 10, 5),
    );

    await repository.upsert(older);
    await repository.upsert(newer);

    final invoices = await repository.all();
    expect(invoices.map((invoice) => invoice.id), ['new', 'old']);
  });

  test('invoice deletion is local-first and queues a tombstone mutation', () async {
    final repository = InvoiceRepository();
    final invoice = Invoice(
      id: 'i1',
      businessId: 'b1',
      customerId: 'c1',
      customerName: 'Customer',
      number: 'INV-1',
      issueDate: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 15),
      lines: const [],
    );

    await repository.upsert(invoice);
    await repository.delete(invoice.id);

    expect(await repository.all(), isEmpty);
    final queue = await SyncQueue().all();
    expect(queue, hasLength(1));
    expect(queue.single.operation, 'delete');
    expect(queue.single.entity, 'invoice');
    expect(queue.single.id, 'i1');
  });
}
