import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingChange {
  final String entity;
  final String id;
  final String operation;
  final DateTime updatedAt;
  final Map<String, dynamic>? payload;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;
  final bool permanentFailure;

  const PendingChange({
    required this.entity,
    required this.id,
    required this.operation,
    required this.updatedAt,
    this.payload,
    this.attempts = 0,
    this.lastError,
    this.nextAttemptAt,
    this.permanentFailure = false,
  });

  bool get isWaitingForRetry =>
      nextAttemptAt != null && DateTime.now().toUtc().isBefore(nextAttemptAt!.toUtc());

  PendingChange copyWith({
    int? attempts,
    String? lastError,
    DateTime? nextAttemptAt,
    bool clearLastError = false,
    bool clearNextAttemptAt = false,
    bool? permanentFailure,
  }) {
    return PendingChange(
      entity: entity,
      id: id,
      operation: operation,
      updatedAt: updatedAt,
      payload: payload,
      attempts: attempts ?? this.attempts,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      nextAttemptAt: clearNextAttemptAt ? null : (nextAttemptAt ?? this.nextAttemptAt),
      permanentFailure: permanentFailure ?? this.permanentFailure,
    );
  }

  Map<String, dynamic> toJson() => {
        'entity': entity,
        'id': id,
        'operation': operation,
        'updatedAt': updatedAt.toIso8601String(),
        'payload': payload,
        'attempts': attempts,
        'lastError': lastError,
        'nextAttemptAt': nextAttemptAt?.toIso8601String(),
        'permanentFailure': permanentFailure,
      };

  factory PendingChange.fromJson(Map<String, dynamic> j) => PendingChange(
        entity: j['entity'] as String? ?? '',
        id: j['id'] as String? ?? '',
        operation: j['operation'] as String? ?? 'upsert',
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now().toUtc(),
        payload: j['payload'] == null
            ? null
            : Map<String, dynamic>.from(j['payload'] as Map),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        lastError: j['lastError'] as String?,
        nextAttemptAt: DateTime.tryParse(j['nextAttemptAt'] as String? ?? ''),
        permanentFailure: j['permanentFailure'] as bool? ?? false,
      );
}

class SyncQueue extends ChangeNotifier {
  static const key = 'ie_sync_queue_v2';

  Future<List<PendingChange>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PendingChange.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> pendingCount() async => (await all()).length;

  Future<void> enqueue(PendingChange change) async {
    final items = await all();
    final index = items.indexWhere((e) => e.entity == change.entity && e.id == change.id);
    if (index >= 0) {
      // A newer local mutation replaces an older retry state. This prevents a
      // previous failure from incorrectly blocking a fresh user edit.
      items[index] = change;
    } else {
      items.add(change);
    }
    await _save(items);
    notifyListeners();
  }

  Future<void> remove(PendingChange change) async {
    final items = await all();
    items.removeWhere(
      (e) =>
          e.entity == change.entity &&
          e.id == change.id &&
          e.updatedAt == change.updatedAt,
    );
    await _save(items);
    notifyListeners();
  }

  Future<void> recordFailure(
    PendingChange change, {
    required String error,
    required Duration retryAfter,
    bool permanent = false,
  }) async {
    final items = await all();
    final index = items.indexWhere(
      (e) =>
          e.entity == change.entity &&
          e.id == change.id &&
          e.updatedAt == change.updatedAt,
    );
    if (index < 0) return;

    final attempts = items[index].attempts + 1;
    items[index] = items[index].copyWith(
      attempts: attempts,
      lastError: error,
      nextAttemptAt: permanent ? null : DateTime.now().toUtc().add(retryAfter),
      permanentFailure: permanent,
    );
    await _save(items);
    notifyListeners();
  }

  Future<void> resetFailures() async {
    final items = await all();
    var changed = false;
    for (var i = 0; i < items.length; i++) {
      if (items[i].attempts == 0 && items[i].lastError == null && !items[i].permanentFailure) continue;
      items[i] = items[i].copyWith(
        attempts: 0,
        clearLastError: true,
        clearNextAttemptAt: true,
        permanentFailure: false,
      );
      changed = true;
    }
    if (changed) {
      await _save(items);
      notifyListeners();
    }
  }

  Future<void> resetFailure(PendingChange change) async {
    final items = await all();
    final index = items.indexWhere(
      (e) => e.entity == change.entity && e.id == change.id,
    );
    if (index < 0) return;
    items[index] = items[index].copyWith(
      attempts: 0,
      clearLastError: true,
      clearNextAttemptAt: true,
      permanentFailure: false,
    );
    await _save(items);
    notifyListeners();
  }

  Future<void> clear() async {
    await _save([]);
    notifyListeners();
  }

  Future<void> _save(List<PendingChange> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
