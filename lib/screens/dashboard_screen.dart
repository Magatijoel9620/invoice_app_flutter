import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/invoice_status.dart';
import '../models/invoice.dart';
import '../providers/app_providers.dart';
import 'invoice_details_screen.dart';
import 'widgets/app_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onCreateInvoice;
  const DashboardScreen({super.key, required this.onCreateInvoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(businessProvider);
    final invoices = ref.watch(invoicesProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(invoicesProvider);
        await ref.read(invoicesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          business.when(
            data: (b) => _greeting(context, b.name),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => _errorCard(
              context,
              'Business unavailable',
              '$e',
              () => ref.invalidate(businessProvider),
            ),
          ),
          const SizedBox(height: 16),
          _hero(context),
          const SizedBox(height: 18),
          invoices.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _errorCard(
              context,
              'Could not load invoices',
              'Your dashboard could not be refreshed.',
              () => ref.invalidate(invoicesProvider),
            ),
            data: (items) => _content(context, ref, items),
          ),
        ],
      ),
    );
  }

  Widget _greeting(BuildContext context, String name) {
    final hour = DateTime.now().hour;

    String greeting;
    String emoji;

    if (hour >= 5 && hour < 12) {
      greeting = 'Good morning';
      emoji = '👋';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
      emoji = '☀️';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good evening';
      emoji = '🌆';
    } else {
      greeting = 'Good night';
      emoji = '🌙';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting $emoji',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 3),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withValues(alpha: .72)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to invoice?',
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create, send and track your business invoices.',
            style: TextStyle(color: cs.onPrimary.withValues(alpha: .82)),
          ),
          const SizedBox(height: 15),
          FilledButton.tonalIcon(
            onPressed: onCreateInvoice,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create invoice'),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, List<Invoice> items) {
    final active = items.where((i) => !i.archived).toList();
    final now = DateTime.now();
    final month = active
        .where(
          (i) => i.issueDate.year == now.year && i.issueDate.month == now.month,
        )
        .toList();
    final invoiced = month.fold<double>(
      0,
      (sum, i) => sum + i.total(i.vatRate),
    );
    final collected = month.fold<double>(0, (sum, i) => sum + i.amountPaid);
    final outstanding = active.fold<double>(
      0,
      (sum, i) => sum + i.balance(i.vatRate),
    );
    final overdue = active
        .where(
          (i) => effectiveInvoiceStatus(i, i.vatRate) == InvoiceStatus.overdue,
        )
        .length;

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            StatCard(
              label: 'Invoiced',
              value: compactMoney(invoiced),
              icon: Icons.receipt_long_rounded,
            ),
            StatCard(
              label: 'Collected',
              value: compactMoney(collected),
              icon: Icons.payments_rounded,
            ),
            StatCard(
              label: 'Outstanding',
              value: compactMoney(outstanding),
              icon: Icons.account_balance_wallet_rounded,
            ),
            StatCard(
              label: 'Overdue',
              value: '$overdue',
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _trendCard(context, active),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent invoices',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            if (active.isNotEmpty)
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(invoicesProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        const SizedBox(height: 7),
        if (active.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Your first invoice is waiting',
            message: 'Create an invoice to start tracking sales and payments.',
            actionLabel: 'Create invoice',
            onAction: onCreateInvoice,
          )
        else
          ...active
              .take(5)
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: AppCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetailsScreen(invoiceId: i.id),
                      ),
                    ),
                    child: _invoiceRow(context, i),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _invoiceRow(BuildContext context, Invoice i) {
    final status = effectiveInvoiceStatus(i, i.vatRate);
    return Row(
      children: [
        CircleAvatar(radius: 20, child: Icon(_statusIcon(status), size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i.number,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                i.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                shortDate.format(i.issueDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              money.format(i.total(i.vatRate)),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              invoiceStatusLabel(status).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _trendCard(BuildContext context, List<Invoice> invoices) {
    final values = <double>[];
    final labels = <String>[];
    final now = DateTime.now();
    for (var offset = 5; offset >= 0; offset--) {
      final monthDate = DateTime(now.year, now.month - offset, 1);
      final total = invoices
          .where(
            (i) =>
                i.issueDate.year == monthDate.year &&
                i.issueDate.month == monthDate.month,
          )
          .fold<double>(0, (s, i) => s + i.total(i.vatRate));
      values.add(total);
      labels.add(_monthLabel(monthDate));
    }
    final maxValue = values.fold<double>(0, math.max);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoicing trend',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text('Last 6 months', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final fraction = maxValue <= 0
                    ? 0.04
                    : values[index] / maxValue;
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: 70 * fraction + 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .75),
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

  Widget _errorCard(
    BuildContext context,
    String title,
    String message,
    VoidCallback retry,
  ) => AppCard(
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 34),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(message, textAlign: TextAlign.center),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  String _monthLabel(DateTime date) => const [
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
  ][date.month - 1];

  IconData _statusIcon(InvoiceStatus s) => switch (s) {
    InvoiceStatus.paid => Icons.check_circle_outline,
    InvoiceStatus.overdue => Icons.warning_amber_rounded,
    InvoiceStatus.cancelled => Icons.block_outlined,
    InvoiceStatus.draft => Icons.edit_note,
    InvoiceStatus.partiallyPaid => Icons.timelapse,
    InvoiceStatus.viewed => Icons.visibility_outlined,
    InvoiceStatus.sent => Icons.send_outlined,
  };
}
