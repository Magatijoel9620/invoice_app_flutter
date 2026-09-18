import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/connectivity_service.dart';
import '../services/sync_status.dart';

/// Global connectivity + synchronization feedback used by the authenticated
/// application shell.
class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();

    _wasOffline = ref.read(connectivityProvider).isOffline;

    ref.listenManual<ConnectivityService>(connectivityProvider, (
      previous,
      next,
    ) {
      if (next.isOffline) {
        _wasOffline = true;
      }

      if (next.isOnline && _wasOffline && mounted) {
        _wasOffline = false;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Back online — syncing your changes…'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final sync = ref.watch(syncStatusProvider);
    final content = _content(connectivity, sync);

    if (content == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(content.icon, color: colorScheme.onSecondaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DefaultTextStyle(
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                        child: content.message,
                      ),
                    ),
                  ],
                ),
                if (content.showRetry) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _retry,
                      child: const Text('RETRY'),
                    ),
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Icon(content.icon, color: colorScheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                  child: content.message,
                ),
              ),
              if (content.showRetry) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: _retry, child: const Text('RETRY')),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _retry() async {
    try {
      await ref.read(syncServiceProvider).retryNow();

      ref.invalidate(businessProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(invoicesProvider);
    } catch (_) {
      // The sync provider remains in its failed state and the
      // retry button remains available.
    }
  }

  _BannerData? _content(ConnectivityService connectivity, SyncStatus sync) {
    if (connectivity.isChecking) {
      return const _BannerData(
        icon: Icons.wifi_find_outlined,
        message: Text('Checking your internet connection…'),
      );
    }

    if (connectivity.isOffline) {
      return _BannerData(
        icon: Icons.cloud_off_outlined,
        message: Text(
          sync.pending > 0
              ? 'Offline — ${sync.pending} change'
                    '${sync.pending == 1 ? '' : 's'} saved on this device.'
              : 'Offline — your data remains available on this device.',
        ),
      );
    }

    if (sync.state == SyncState.syncing) {
      return _BannerData(
        icon: Icons.sync_rounded,
        message: Text(
          sync.pending > 0
              ? 'Syncing — ${sync.pending} pending change'
                    '${sync.pending == 1 ? '' : 's'}…'
              : 'Syncing your data…',
        ),
      );
    }

    if (sync.state == SyncState.error) {
      return _BannerData(
        icon: Icons.error_outline_rounded,
        message: Text(
          sync.message ?? 'Sync failed. Your local changes are safe.',
        ),
        showRetry: true,
      );
    }

    if (sync.pending > 0) {
      return _BannerData(
        icon: Icons.cloud_upload_outlined,
        message: Text(
          '${sync.pending} change'
          '${sync.pending == 1 ? '' : 's'} waiting to sync.'
          '${sync.failed > 0 ? ' ${sync.failed} failed operation'
                    '${sync.failed == 1 ? '' : 's'} retained for retry.' : ''}',
        ),
        showRetry: true,
      );
    }

    return null;
  }
}

class _BannerData {
  const _BannerData({
    required this.icon,
    required this.message,
    this.showRetry = false,
  });

  final IconData icon;
  final Widget message;
  final bool showRetry;
}
