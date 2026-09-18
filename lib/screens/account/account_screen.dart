import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_easy/screens/auth/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_providers.dart';
import '../../services/cloud_config.dart';
import '../../services/sync_status.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool loaded = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (loaded || !CloudConfig.isConfigured) return;
    try {
      final profile = await ref.read(accountProfileServiceProvider).get();
      _name.text = profile.fullName;
      _phone.text = profile.phone;
    } catch (_) {}
    loaded = true;
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await ref
          .read(accountProfileServiceProvider)
          .save(fullName: _name.text, phone: _phone.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Account profile saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _sync() async {
    try {
      await ref.read(syncServiceProvider).sync();
      if (mounted) {
        ref.invalidate(businessProvider);
        ref.invalidate(customersProvider);
        ref.invalidate(productsProvider);
        ref.invalidate(invoicesProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sync complete.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your local invoices stay on this device. '
          'Cloud sync will stop until you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await ref.read(authServiceProvider).signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not sign out: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your InvoiceEasy cloud account and cloud data. Local data on this device is not automatically erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client.functions.invoke('delete-account');
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account deletion needs the Supabase delete-account function. $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final sync = ref.watch(syncStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person_rounded),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: saving ? null : _save,
                    child: Text(saving ? 'Saving…' : 'Save profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(_syncIcon(sync.state)),
                  title: Text(_syncTitle(sync)),
                  subtitle: Text(
                    sync.pending == 0
                        ? 'No pending local changes'
                        : '${sync.pending} change(s) waiting to sync',
                  ),
                  trailing: IconButton(
                    tooltip: 'Sync now',
                    onPressed: sync.state == SyncState.syncing ? null : _sync,
                    icon: const Icon(Icons.sync),
                  ),
                ),
                if (sync.lastSyncedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 72,
                      right: 16,
                      bottom: 14,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Last sync: ${sync.lastSyncedAt}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: const Text('Reset password'),
                  onTap: () async {
                    final email = user?.email;
                    if (email != null) {
                      await ref.read(authServiceProvider).resetPassword(email);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset instructions sent.'),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete account'),
              subtitle: const Text('Permanently delete cloud account and data'),
              onTap: _deleteAccount,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'InvoiceEasy 3.0 • Offline-first cloud sync',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _syncIcon(SyncState state) => switch (state) {
    SyncState.syncing => Icons.sync,
    SyncState.success => Icons.cloud_done_outlined,
    SyncState.error => Icons.cloud_off_outlined,
    SyncState.idle => Icons.cloud_outlined,
    SyncState.offline => Icons.cloud_off_outlined,
  };
  String _syncTitle(SyncStatus status) => switch (status.state) {
    SyncState.syncing => 'Syncing…',
    SyncState.success => 'Cloud synced',
    SyncState.error => 'Sync error',
    SyncState.idle => 'Ready to sync',
    SyncState.offline => 'Cloud offline',
  };
}
