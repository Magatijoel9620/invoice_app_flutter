import 'package:flutter/foundation.dart';

enum SyncState { offline, idle, syncing, success, error }

class SyncStatus extends ChangeNotifier {
  SyncState state = SyncState.idle;
  int pending = 0;
  String? message;
  DateTime? lastSyncedAt;

  void setState(SyncState value, {String? message}) {
    state = value;
    this.message = message;
    notifyListeners();
  }

  void setPending(int value) {
    if (pending == value) return;
    pending = value;
    notifyListeners();
  }

  void markSynced() {
    lastSyncedAt = DateTime.now().toUtc();
    state = SyncState.success;
    message = null;
    notifyListeners();
  }
}
