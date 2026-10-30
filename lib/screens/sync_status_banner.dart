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
            ],
          );
        },
      ),
    );
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

    // Detailed failures and retained queue items are shown in Account > Sync
    // status. The global banner is reserved for transient/offline activity.

    // Pending items remain visible in Account > Sync status. Avoid a banner
    // permanently occupying the app after the automatic retry cycle ends.
    return null;
  }
}

class _BannerData {
  const _BannerData({required this.icon, required this.message});

  final IconData icon;
  final Widget message;
}
