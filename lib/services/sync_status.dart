import 'package:flutter/foundation.dart';

import 'sync_queue.dart';

enum SyncState { offline, idle, syncing, success, error }

class SyncStatus extends ChangeNotifier {
  SyncState state = SyncState.idle;
  int pending = 0;
  int failed = 0;
  String? message;
  DateTime? lastSyncedAt;

  void setState(SyncState value, {String? message}) {
    state = value;
    this.message = message;
    notifyListeners();
  }

  void setPending(int value, {int? failed}) {
    final changed = pending != value || (failed != null && this.failed != failed);
    pending = value;
    if (failed != null) this.failed = failed;
    if (changed) notifyListeners();
  }

  Future<void> refreshFromQueue(SyncQueue queue) async {
    final items = await queue.all();
    setPending(
      items.length,
      failed: items.where((item) => item.lastError != null).length,
    );
  }

  void markSynced() {
    lastSyncedAt = DateTime.now().toUtc();
    state = SyncState.success;
    message = null;
    notifyListeners();
  }
}
