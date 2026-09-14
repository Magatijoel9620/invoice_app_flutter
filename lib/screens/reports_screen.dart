import 'dart:math' as math;

import '../models/business_profile.dart';
import '../services/report_export_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/invoice_status.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../providers/app_providers.dart';
import 'customer_profile_screen.dart';
import 'widgets/app_card.dart';
import 'widgets/empty_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? range;

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider);
    final customers = ref.watch(customersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & analytics'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export report',
            onSelected: (value) => _export(context, ref, value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Share PDF')),
              PopupMenuItem(value: 'csv', child: Text('Share CSV')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(invoicesProvider);
          ref.invalidate(customersProvider);
          await ref.read(invoicesProvider.future);
        },
        child: invoices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _error(context, ref, e),
          data: (all) => _report(
            context,
            _filtered(all),
            customers.valueOrNull ?? [],
            range,
          ),
        ),
      ),
    );
  }

  Widget _report(
    BuildContext context,
    List<Invoice> all,
    List<Customer> customers,
    DateTimeRange? selectedRange,
  ) {
    final active = all.where((i) => !i.archived).toList();
    final now = DateTime.now();
    final month = selectedRange == null
        ? active
              .where(
                (i) =>
                    i.issueDate.year == now.year &&
                    i.issueDate.month == now.month,
              )
              .toList()
        : active;
    final invoiced = month.fold<double>(0, (s, i) => s + i.total(i.vatRate));
    final collected = month.fold<double>(0, (s, i) => s + i.amountPaid);
    final outstanding = active.fold<double>(
      0,
      (s, i) => s + i.balance(i.vatRate),
    );
    final overdue = active
        .where(
          (i) => effectiveInvoiceStatus(i, i.vatRate) == InvoiceStatus.overdue,
        )
        .toList();
    final paid = active
        .where(
          (i) => effectiveInvoiceStatus(i, i.vatRate) == InvoiceStatus.paid,
        )
        .length;
    final drafts = active
        .where(
          (i) => effectiveInvoiceStatus(i, i.vatRate) == InvoiceStatus.draft,
        )
        .length;
    final collection = invoiced <= 0
        ? 0.0
        : (collected / invoiced).clamp(0, 1).toDouble();

    final customerStats = <String, _CustomerStat>{};
    for (final invoice in active) {
      final stat = customerStats.putIfAbsent(
        invoice.customerName,
        () => _CustomerStat(invoice.customerName),
      );
      stat.invoiced += invoice.total(invoice.vatRate);
      stat.paid += invoice.amountPaid;
      stat.invoices++;
    }
    final ranked = customerStats.values.toList()
      ..sort((a, b) => b.invoiced.compareTo(a.invoiced));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
      children: [
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.date_range_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  range == null
                      ? 'All invoice dates'
                      : '${shortDate.format(range!.start)} – ${shortDate.format(range!.end)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => _pickRange(context),
                child: Text(range == null ? 'Filter' : 'Change'),
              ),
              if (range != null)
                IconButton(
                  tooltip: 'Clear date filter',
                  onPressed: () => setState(() => range = null),
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          selectedRange == null ? 'This month' : 'Selected period',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          selectedRange == null
              ? _monthName(now)
              : '${shortDate.format(selectedRange.start)} – ${shortDate.format(selectedRange.end)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _metric(
              context,
              'Invoiced',
              compactMoney(invoiced),
              Icons.receipt_long_outlined,
            ),
            _metric(
              context,
              'Collected',
              compactMoney(collected),
              Icons.payments_outlined,
            ),
            _metric(
              context,
              'Outstanding',
              compactMoney(outstanding),
              Icons.account_balance_wallet_outlined,
            ),
            _metric(
              context,
              'Overdue',
              '${overdue.length}',
              Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _collectionCard(context, collection, collected, invoiced),
        const SizedBox(height: 14),
        _trend(context, active),
        const SizedBox(height: 14),
        _health(context, active.length, paid, overdue.length, drafts),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Customer performance',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${ranked.length} customers',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (ranked.isEmpty)
          const EmptyState(
            icon: Icons.insights_outlined,
            title: 'No analytics yet',
            message:
                'Create invoices to start seeing customer and collection insights.',
          )
        else
          ...ranked.take(10).map((stat) {
            Customer? customer;
            for (final c in customers) {
              if (c.name == stat.name) {
                customer = c;
                break;
              }
            }
            final balance = math.max(0, stat.invoiced - stat.paid);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: AppCard(
                onTap: customer == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerProfileScreen(customer: customer!),
                        ),
                      ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          child: Text(
                            stat.name.isEmpty
                                ? '?'
                                : stat.name[0].toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${stat.invoices} invoice${stat.invoices == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              money.format(stat.invoiced),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              balance <= .01
                                  ? 'Paid in full'
                                  : '${money.format(balance)} due',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        if (customer != null)
                          const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: stat.invoiced <= 0
                          ? 0
                          : (stat.paid / stat.invoiced).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _collectionCard(
    BuildContext context,
    double rate,
    double collected,
    double invoiced,
  ) {
    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                Text(
                  '${(rate * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection rate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  invoiced <= 0
                      ? 'No invoices issued this month yet.'
                      : '${money.format(collected)} collected of ${money.format(invoiced)} invoiced.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trend(BuildContext context, List<Invoice> invoices) {
    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];
    for (var offset = 5; offset >= 0; offset--) {
      final date = DateTime(now.year, now.month - offset, 1);
      values.add(
        invoices
            .where(
              (i) =>
                  i.issueDate.year == date.year &&
                  i.issueDate.month == date.month,
            )
            .fold<double>(0, (s, i) => s + i.total(i.vatRate)),
      );
      labels.add(_monthShort(date.month));
    }
    final maxValue = values.fold<double>(0, math.max);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue trend',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            'Invoiced value over the last 6 months',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 135,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final fraction = maxValue <= 0 ? .04 : values[index] / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          values[index] == 0
                              ? '—'
                              : compactMoney(values[index]),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: 72 * fraction + 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .72),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[index],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _health(
    BuildContext context,
    int total,
    int paid,
    int overdue,
    int drafts,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice health',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _row('Active invoices', '$total'),
          _row('Paid', '$paid'),
          _row('Overdue', '$overdue'),
          _row('Drafts', '$drafts'),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );

  Widget _error(BuildContext context, WidgetRef ref, Object error) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 90),
      const Icon(Icons.cloud_off_rounded, size: 44),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Could not load reports',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 4),
      Center(child: Text('$error', textAlign: TextAlign.center)),
      const SizedBox(height: 8),
      Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(invoicesProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ),
    ],
  );

  String _monthName(DateTime d) => '${_monthShort(d.month)} ${d.year}';
  String _monthShort(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );

  List<Invoice> _filtered(List<Invoice> invoices) {
    final r = range;
    if (r == null) return invoices;
    final start = DateTime(r.start.year, r.start.month, r.start.day);
    final end = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59);
    return invoices
        .where((i) => !i.issueDate.isBefore(start) && !i.issueDate.isAfter(end))
        .toList();
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: range,
    );
    if (picked != null && mounted) setState(() => range = picked);
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    final invoices = _filtered(
      ref.read(invoicesProvider).valueOrNull ?? [],
    ).where((i) => !i.archived).toList();
    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no invoices to export.')),
      );
      return;
    }
    final business =
        ref.read(businessProvider).valueOrNull ??
        BusinessProfile(
          id: 'default',
          name: 'My Business',
          businessType: 'Other',
        );
    try {
      if (format == 'csv') {
        await ReportExportService.shareCsv(invoices, business);
      } else {
        await ReportExportService.sharePdf(invoices, business);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

class _CustomerStat {
  final String name;
  double invoiced = 0;
  double paid = 0;
  int invoices = 0;
  _CustomerStat(this.name);
}
