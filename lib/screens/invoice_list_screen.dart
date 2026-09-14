import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/invoice_status.dart';
import '../models/invoice.dart';
import '../providers/app_providers.dart';
import 'invoice_details_screen.dart';
import 'widgets/app_card.dart';
import 'widgets/empty_state.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  final VoidCallback onCreate;

  const InvoiceListScreen({super.key, required this.onCreate});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListState();
}

class _InvoiceListState extends ConsumerState<InvoiceListScreen> {
  final search = TextEditingController();
  String query = '';
  InvoiceStatus? filter;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(invoicesProvider);

    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(invoicesProvider),
      ),
      data: (items) {
        final active = items.where((invoice) => !invoice.archived).toList();
        final normalized = query.trim().toLowerCase();
        final list = active.where((invoice) {
          final status = effectiveInvoiceStatus(invoice, invoice.vatRate);
          return (filter == null || status == filter) &&
              (normalized.isEmpty ||
                  invoice.number.toLowerCase().contains(normalized) ||
                  invoice.customerName.toLowerCase().contains(normalized));
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(invoicesProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invoices',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${active.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Search, filter and manage every invoice.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: search,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search invoice or customer',
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            search.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', null),
                    ...InvoiceStatus.values.map(
                      (status) => _chip(invoiceStatusLabel(status), status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (list.isEmpty)
                EmptyState(
                  icon: normalized.isNotEmpty || filter != null
                      ? Icons.search_off_rounded
                      : Icons.receipt_long_outlined,
                  title: normalized.isNotEmpty || filter != null
                      ? 'No matching invoices'
                      : 'No invoices yet',
                  message: normalized.isNotEmpty || filter != null
                      ? 'Try another search or clear the filter.'
                      : 'Create your first invoice and it will appear here.',
                  actionLabel:
                      normalized.isEmpty && filter == null ? 'Create invoice' : null,
                  onAction:
                      normalized.isEmpty && filter == null ? widget.onCreate : null,
                )
              else
                ...list.map(
                  (invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InvoiceDetailsScreen(invoiceId: invoice.id),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _statusColor(
                              effectiveInvoiceStatus(
                                invoice,
                                invoice.vatRate,
                              ),
                            ).withValues(alpha: .12),
                            child: Icon(
                              _statusIcon(
                                effectiveInvoiceStatus(
                                  invoice,
                                  invoice.vatRate,
                                ),
                              ),
                              color: _statusColor(
                                effectiveInvoiceStatus(
                                  invoice,
                                  invoice.vatRate,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(invoice.customerName),
                                const SizedBox(height: 3),
                                Text(
                                  '${shortDate.format(invoice.issueDate)} • Due ${shortDate.format(invoice.dueDate)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                money.format(invoice.total(invoice.vatRate)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                invoiceStatusLabel(
                                  effectiveInvoiceStatus(
                                    invoice,
                                    invoice.vatRate,
                                  ),
                                ).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _statusColor(
                                    effectiveInvoiceStatus(
                                      invoice,
                                      invoice.vatRate,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, InvoiceStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: filter == status,
        onSelected: (_) => setState(() => filter = status),
      ),
    );
  }

  Color _statusColor(InvoiceStatus status) {
    final colors = Theme.of(context).colorScheme;
    return switch (status) {
      InvoiceStatus.paid => colors.primary,
      InvoiceStatus.overdue => colors.error,
      InvoiceStatus.cancelled => colors.outline,
      InvoiceStatus.draft => colors.secondary,
      InvoiceStatus.partiallyPaid => colors.tertiary,
      InvoiceStatus.viewed => colors.primary,
      InvoiceStatus.sent => colors.secondary,
    };
  }

  IconData _statusIcon(InvoiceStatus status) => switch (status) {
        InvoiceStatus.paid => Icons.check_circle_outline,
        InvoiceStatus.overdue => Icons.warning_amber_rounded,
        InvoiceStatus.cancelled => Icons.block_outlined,
        InvoiceStatus.draft => Icons.edit_note,
        InvoiceStatus.partiallyPaid => Icons.timelapse,
        InvoiceStatus.viewed => Icons.visibility_outlined,
        InvoiceStatus.sent => Icons.send_outlined,
      };
}
