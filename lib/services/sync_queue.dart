import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingChange {
  final String entity;
  final String id;
  final String operation;
  final DateTime updatedAt;
  final Map<String, dynamic>? payload;

  const PendingChange({required this.entity, required this.id, required this.operation, required this.updatedAt, this.payload});

  Map<String, dynamic> toJson() => {
    'entity': entity,
    'id': id,
    'operation': operation,
    'updatedAt': updatedAt.toIso8601String(),
    'payload': payload,
  };

  factory PendingChange.fromJson(Map<String, dynamic> j) => PendingChange(
    entity: j['entity'] as String? ?? '',
    id: j['id'] as String? ?? '',
    operation: j['operation'] as String? ?? 'upsert',
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
    payload: j['payload'] == null ? null : Map<String, dynamic>.from(j['payload'] as Map),
  );
}

class SyncQueue {
  static const key = 'ie_sync_queue_v1';

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

  Future<void> enqueue(PendingChange change) async {
    final items = await all();
    final index = items.indexWhere((e) => e.entity == change.entity && e.id == change.id);
    if (index >= 0) {
      items[index] = change;
    } else {
      items.add(change);
    }
    await _save(items);
  }

  Future<void> remove(PendingChange change) async {
    final items = await all();
    items.removeWhere((e) => e.entity == change.entity && e.id == change.id && e.updatedAt == change.updatedAt);
    await _save(items);
  }

  Future<void> clear() => _save([]);

  Future<void> _save(List<PendingChange> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
