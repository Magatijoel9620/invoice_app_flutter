import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoice_easy/services/sync_queue.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('queue persists mutations and coalesces the same record', () async {
    final queue = SyncQueue();
    final first = PendingChange(
      entity: 'customer',
      id: 'c1',
      operation: 'upsert',
      updatedAt: DateTime(2026, 9, 18, 10),
      payload: {'id': 'c1', 'name': 'Old'},
    );
    final second = PendingChange(
      entity: 'customer',
      id: 'c1',
      operation: 'upsert',
      updatedAt: DateTime(2026, 9, 18, 11),
      payload: {'id': 'c1', 'name': 'New'},
    );

    await queue.enqueue(first);
    await queue.enqueue(second);

    final items = await queue.all();
    expect(items, hasLength(1));
    expect(items.single.payload?['name'], 'New');
  });

  test('failed mutations retain retry metadata and can recover', () async {
    final queue = SyncQueue();
    final change = PendingChange(
      entity: 'invoice',
      id: 'i1',
      operation: 'upsert',
      updatedAt: DateTime.now().toUtc(),
      payload: {'id': 'i1'},
    );

    await queue.enqueue(change);
    await queue.recordFailure(
      change,
      error: 'Temporary network failure',
      retryAfter: const Duration(seconds: 2),
    );

    var current = (await queue.all()).single;
    expect(current.attempts, 1);
    expect(current.lastError, 'Temporary network failure');
    expect(current.nextAttemptAt, isNotNull);
    expect(current.permanentFailure, isFalse);

    await queue.resetFailures();
    current = (await queue.all()).single;
    expect(current.attempts, 0);
    expect(current.lastError, isNull);
    expect(current.nextAttemptAt, isNull);
    expect(current.permanentFailure, isFalse);
  });

  test('permanent failures remain visible instead of being discarded', () async {
    final queue = SyncQueue();
    final change = PendingChange(
      entity: 'product',
      id: 'p1',
      operation: 'upsert',
      updatedAt: DateTime.now().toUtc(),
      payload: {'id': 'p1'},
    );

    await queue.enqueue(change);
    await queue.recordFailure(
      change,
      error: 'Invalid server payload',
      retryAfter: Duration.zero,
      permanent: true,
    );

    final current = (await queue.all()).single;
    expect(current.permanentFailure, isTrue);
    expect(current.lastError, 'Invalid server payload');
  });
}
