import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/sync_status.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    if (status.state == SyncState.success && status.pending == 0) return const SizedBox.shrink();
    final text = switch (status.state) { SyncState.syncing => 'Syncing your data…', SyncState.error => status.message ?? 'Sync failed', SyncState.offline => 'Offline — changes are saved on this device', _ => status.pending == 0 ? '' : '${status.pending} local change(s) waiting to sync' };
    if (text.isEmpty) return const SizedBox.shrink();
    return MaterialBanner(content: Text(text), leading: Icon(status.state == SyncState.error ? Icons.error_outline : Icons.cloud_outlined), actions: [TextButton(onPressed: status.state == SyncState.syncing ? null : () async { try { await ref.read(syncServiceProvider).sync(); ref.invalidate(businessProvider); ref.invalidate(customersProvider); ref.invalidate(productsProvider); ref.invalidate(invoicesProvider); } catch (_) {} }, child: const Text('SYNC'))]);
  }
}
