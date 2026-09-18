import 'package:flutter/material.dart';
import '../core/guards/subscription_action_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../providers/app_providers.dart';
import 'invoice_details_screen.dart';
import 'widgets/empty_state.dart';

class ArchivedInvoicesScreen extends ConsumerWidget {
  const ArchivedInvoicesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(invoicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived invoices')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(invoicesProvider),
        ),
        data: (items) {
          final archived = items.where((i) => i.archived).toList();
          if (archived.isEmpty) {
            return const EmptyState(
              icon: Icons.archive_outlined,
              title: 'No archived invoices',
              message: 'Invoices you archive will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            itemCount: archived.length,
            itemBuilder: (context, index) {
              final invoice = archived[index];
              return Card(
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InvoiceDetailsScreen(invoiceId: invoice.id),
                    ),
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.archive_outlined),
                  ),
                  title: Text(
                    invoice.number,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${invoice.customerName}\n${shortDate.format(invoice.issueDate)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'restore') {
                        if (!SubscriptionActionGuard.requireWrite(context, ref)) return;
                        await ref
                            .read(invoicesProvider.notifier)
                            .upsert(invoice.copyWith(archived: false));
                      }
                      if (!context.mounted) return;
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete permanently?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (!context.mounted) return;
                        if (ok == true) {
                          if (!SubscriptionActionGuard.requireWrite(context, ref)) return;
                          await ref
                              .read(invoicesProvider.notifier)
                              .delete(invoice.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'restore', child: Text('Restore')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete permanently'),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 9),
          );
        },
      ),
    );
  }
}
