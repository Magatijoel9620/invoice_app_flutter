import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _checkingForUpdates = false;
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final version = await AppUpdateService.instance.getCurrentVersion();
      if (mounted) setState(() => _currentVersion = version);
    } catch (_) {
      // The About screen remains usable if platform version data is unavailable.
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checkingForUpdates) return;
    setState(() => _checkingForUpdates = true);

    try {
      final update = await AppUpdateService.instance.checkForUpdate();
      if (!mounted) return;

      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No newer version was found. If you are offline, try again when connected.',
            ),
          ),
        );
        return;
      }

      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('InvoiceEasy ${update.latestVersion} is available'),
          content: SingleChildScrollView(
            child: Text(
              update.releaseNotes?.isNotEmpty == true
                  ? update.releaseNotes!
                  : 'A newer version of InvoiceEasy is ready to install.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Update'),
            ),
          ],
        ),
      );

      if (shouldUpdate != true || !mounted) return;

      final opened = await AppUpdateService.instance.openDownloadPage(
        update.downloadUrl,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the download page. Please try again later.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not check for updates. Please try again later.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingForUpdates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About InvoiceEasy')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Icon(Icons.receipt_long_rounded, size: 76, color: colors.primary),
          const SizedBox(height: 16),
          Text(
            'InvoiceEasy',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Simple invoicing for your business',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _currentVersion == null
                ? 'Version information unavailable'
                : 'Version $_currentVersion',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('About InvoiceEasy'),
                  subtitle: Text(
                    'Create invoices, manage customers and products, record payments, view reports and keep working when offline.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.cloud_sync_outlined),
                  title: Text('Offline-first'),
                  subtitle: Text(
                    'Your work is saved on this device and synchronized when a connection is available.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.business_outlined),
                  title: Text('Developer'),
                  subtitle: Text('Hempon Group'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.system_update_outlined),
              title: const Text('Check for updates'),
              subtitle: Text(
                _checkingForUpdates
                    ? 'Checking the latest InvoiceEasy version…'
                    : 'Check whether a newer InvoiceEasy release is available.',
              ),
              trailing: _checkingForUpdates
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: _checkingForUpdates ? null : _checkForUpdates,
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.support_agent_outlined),
              title: Text('Support'),
              subtitle: Text('hempongroup@gmail.com'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© 2026 Hempon Group. All rights reserved.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
