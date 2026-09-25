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

  // ===========================================================================
  // GREETING
  // ===========================================================================

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

  // ===========================================================================
  // HERO
  // ===========================================================================

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

  // ===========================================================================
  // MAIN CONTENT
  // ===========================================================================

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
        // ---------------------------------------------------------------------
        // KPI CARDS
        // ---------------------------------------------------------------------
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

        // ---------------------------------------------------------------------
        // COLLECTION TREND
        // ---------------------------------------------------------------------
        _collectionTrendCard(context, active),

        const SizedBox(height: 18),

        // ---------------------------------------------------------------------
        // FINANCIAL / STATUS VISUALS
        // ---------------------------------------------------------------------
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;

            final financialCard = _financialSummaryCard(context, active);

            final statusCard = _invoiceStatusCard(context, active);

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: financialCard),
                  const SizedBox(width: 14),
                  Expanded(child: statusCard),
                ],
              );
            }

            return Column(
              children: [financialCard, const SizedBox(height: 14), statusCard],
            );
          },
        ),

        const SizedBox(height: 22),

        // ---------------------------------------------------------------------
        // RECENT INVOICES
        // ---------------------------------------------------------------------
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

  // ===========================================================================
  // COLLECTION TREND CARD
  // ===========================================================================

  Widget _collectionTrendCard(BuildContext context, List<Invoice> invoices) {
    final points = <_InvoiceTrendPoint>[];
    final now = DateTime.now();

    for (var offset = 5; offset >= 0; offset--) {
      final monthDate = DateTime(now.year, now.month - offset, 1);

      var invoiced = 0.0;
      var collected = 0.0;

      for (final invoice in invoices) {
        if (invoice.issueDate.year != monthDate.year ||
            invoice.issueDate.month != monthDate.month) {
          continue;
        }

        invoiced += invoice.total(invoice.vatRate);

        collected += invoice.amountPaid;
      }

      points.add(
        _InvoiceTrendPoint(
          month: _monthLabel(monthDate),
          invoiced: invoiced,
          collected: collected,
        ),
      );
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection trend',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Invoiced vs collected · last 6 months',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (points.isNotEmpty) _CollectionBadge(point: points.last),
              ],
            ),
            const SizedBox(height: 16),
            _InvoiceTrendChart(points: points),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _TrendLegend(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FINANCIAL SUMMARY
  // ===========================================================================

  Widget _financialSummaryCard(BuildContext context, List<Invoice> invoices) {
    var invoiced = 0.0;
    var collected = 0.0;
    var outstanding = 0.0;

    for (final invoice in invoices) {
      invoiced += invoice.total(invoice.vatRate);
      collected += invoice.amountPaid;
      outstanding += invoice.balance(invoice.vatRate);
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receivables overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _FinancialBarChart(
              invoiced: invoiced,
              collected: collected,
              outstanding: outstanding,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INVOICE STATUS DONUT
  // ===========================================================================

  Widget _invoiceStatusCard(BuildContext context, List<Invoice> invoices) {
    final counts = <InvoiceStatus, int>{};

    for (final invoice in invoices) {
      final status = effectiveInvoiceStatus(invoice, invoice.vatRate);

      counts[status] = (counts[status] ?? 0) + 1;
    }

    final entries = InvoiceStatus.values
        .where((status) => (counts[status] ?? 0) > 0)
        .map(
          (status) => _StatusSlice(status: status, count: counts[status] ?? 0),
        )
        .toList();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              'Current active invoice mix',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const SizedBox(
                height: 180,
                child: Center(child: Text('No invoice status data yet')),
              )
            else
              _StatusDonut(entries: entries),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INVOICE ROW
  // ===========================================================================

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

  // ===========================================================================
  // ERROR CARD
  // ===========================================================================

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

// =============================================================================
// TREND MODEL
// =============================================================================

class _InvoiceTrendPoint {
  const _InvoiceTrendPoint({
    required this.month,
    required this.invoiced,
    required this.collected,
  });

  final String month;
  final double invoiced;
  final double collected;
}

// =============================================================================
// COLLECTION BADGE
// =============================================================================

class _CollectionBadge extends StatelessWidget {
  const _CollectionBadge({required this.point});

  final _InvoiceTrendPoint point;

  @override
  Widget build(BuildContext context) {
    final rate = point.invoiced <= 0
        ? 0.0
        : (point.collected / point.invoiced).clamp(0.0, 1.0);

    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${(rate * 100).toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// =============================================================================
// TREND LEGEND
// =============================================================================

class _TrendLegend extends StatelessWidget {
  const _TrendLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _LegendDot(color: scheme.primary, label: 'Invoiced'),
        const SizedBox(width: 20),
        _LegendDot(color: scheme.secondary, label: 'Collected'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

// =============================================================================
// INTERACTIVE COLLECTION CHART
// =============================================================================

class _InvoiceTrendChart extends StatefulWidget {
  const _InvoiceTrendChart({required this.points});

  final List<_InvoiceTrendPoint> points;

  @override
  State<_InvoiceTrendChart> createState() => _InvoiceTrendChartState();
}

class _InvoiceTrendChartState extends State<_InvoiceTrendChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxWidth < 500 ? 190.0 : 220.0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (event) {
            final index = _indexAtPosition(
              event.localPosition,
              constraints.maxWidth,
            );

            if (index != null && index != selectedIndex) {
              setState(() => selectedIndex = index);
            }
          },
          onExit: (_) {
            setState(() => selectedIndex = null);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final index = _indexAtPosition(
                details.localPosition,
                constraints.maxWidth,
              );

              if (index != null) {
                setState(() {
                  selectedIndex = selectedIndex == index ? null : index;
                });
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: chartHeight,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _InvoiceTrendPainter(
                      points: widget.points,
                      selectedIndex: selectedIndex,
                      invoicedColor: Theme.of(context).colorScheme.primary,
                      collectedColor: Theme.of(context).colorScheme.secondary,
                      gridColor: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: .35),
                      surfaceColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                if (selectedIndex != null)
                  _InvoiceTrendTooltip(
                    point: widget.points[selectedIndex!],
                    index: selectedIndex!,
                    count: widget.points.length,
                    width: constraints.maxWidth,
                    height: chartHeight,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  int? _indexAtPosition(Offset position, double width) {
    if (widget.points.isEmpty) {
      return null;
    }

    const left = 14.0;
    const right = 14.0;

    final usableWidth = width - left - right;

    var closestIndex = 0;
    var closestDistance = double.infinity;

    for (var i = 0; i < widget.points.length; i++) {
      final x = widget.points.length == 1
          ? width / 2
          : left + usableWidth * (i / (widget.points.length - 1));

      final distance = (position.dx - x).abs();

      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestDistance <= 55 ? closestIndex : null;
  }
}

// =============================================================================
// COLLECTION TOOLTIP
// =============================================================================

class _InvoiceTrendTooltip extends StatelessWidget {
  const _InvoiceTrendTooltip({
    required this.point,
    required this.index,
    required this.count,
    required this.width,
    required this.height,
  });

  final _InvoiceTrendPoint point;
  final int index;
  final int count;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const tooltipWidth = 185.0;
    const tooltipHeight = 93.0;

    const left = 14.0;
    const right = 14.0;
    const top = 10.0;
    const bottom = 28.0;

    final chartWidth = width - left - right;

    final maxValue = math.max(point.invoiced, point.collected);

    final ratio = maxValue <= 0 ? 0.0 : point.collected / maxValue;

    final chartHeight = height - top - bottom;

    final x = count <= 1
        ? width / 2
        : left + chartWidth * (index / (count - 1));

    final y = top + chartHeight * (1 - ratio);

    var tooltipLeft = x - tooltipWidth / 2;

    tooltipLeft = tooltipLeft.clamp(
      4.0,
      math.max(4.0, width - tooltipWidth - 4),
    );

    var tooltipTop = y - tooltipHeight - 10;

    if (tooltipTop < 4) {
      tooltipTop = y + 10;
    }

    tooltipTop = tooltipTop.clamp(
      4.0,
      math.max(4.0, height - tooltipHeight - 4),
    );

    final collectionRate = point.invoiced <= 0
        ? 0.0
        : (point.collected / point.invoiced).clamp(0.0, 1.0);

    return Positioned(
      left: tooltipLeft,
      top: tooltipTop,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.month,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Invoiced  ${compactMoney(point.invoiced)}',
                style: theme.textTheme.labelSmall,
              ),
              Text(
                'Collected ${compactMoney(point.collected)}',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 2),
              Text(
                '${(collectionRate * 100).toStringAsFixed(1)}% collection',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COLLECTION PAINTER
// =============================================================================

class _InvoiceTrendPainter extends CustomPainter {
  const _InvoiceTrendPainter({
    required this.points,
    required this.selectedIndex,
    required this.invoicedColor,
    required this.collectedColor,
    required this.gridColor,
    required this.surfaceColor,
  });

  final List<_InvoiceTrendPoint> points;
  final int? selectedIndex;
  final Color invoicedColor;
  final Color collectedColor;
  final Color gridColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const left = 14.0;
    const right = 14.0;
    const top = 10.0;
    const bottom = 28.0;

    final width = size.width - left - right;

    final height = size.height - top - bottom;

    final maxValue = points.fold<double>(
      0,
      (max, point) => math.max(max, math.max(point.invoiced, point.collected)),
    );

    final maximum = maxValue <= 0 ? 1.0 : maxValue;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = top + height * (i / 3);

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final invoicedPoints = <Offset>[];

    final collectedPoints = <Offset>[];

    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : left + width * (i / (points.length - 1));

      final invoicedY = top + height * (1 - points[i].invoiced / maximum);

      final collectedY = top + height * (1 - points[i].collected / maximum);

      invoicedPoints.add(Offset(x, invoicedY));

      collectedPoints.add(Offset(x, collectedY));
    }

    _drawSeries(
      canvas,
      invoicedPoints,
      invoicedColor,
      fill: true,
      chartBottom: size.height - bottom,
    );

    _drawSeries(
      canvas,
      collectedPoints,
      collectedColor,
      fill: false,
      chartBottom: size.height - bottom,
    );

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      final index = selectedIndex!;

      final guidePaint = Paint()
        ..color = invoicedColor.withValues(alpha: .17)
        ..strokeWidth = 1;

      final x = invoicedPoints[index].dx;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, size.height - bottom),
        guidePaint,
      );
    }

    for (var i = 0; i < points.length; i++) {
      _drawPoint(
        canvas,
        invoicedPoints[i],
        invoicedColor,
        selected: selectedIndex == i,
      );

      _drawPoint(
        canvas,
        collectedPoints[i],
        collectedColor,
        selected: selectedIndex == i,
      );

      _drawMonthLabel(canvas, invoicedPoints[i], points[i].month, size);
    }
  }

  void _drawSeries(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    required bool fill,
    required double chartBottom,
  }) {
    if (points.length < 2) {
      if (points.length == 1) {
        canvas.drawCircle(points.first, 4, Paint()..color = color);
      }
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final control1 = Offset(
        current.dx + (next.dx - current.dx) * .45,
        current.dy,
      );

      final control2 = Offset(next.dx - (next.dx - current.dx) * .45, next.dy);

      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        next.dx,
        next.dy,
      );
    }

    if (fill) {
      final area = Path.from(path)
        ..lineTo(points.last.dx, chartBottom)
        ..lineTo(points.first.dx, chartBottom)
        ..close();

      canvas.drawPath(
        area,
        Paint()
          ..color = color.withValues(alpha: .07)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = fill ? 2.5 : 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawPoint(
    Canvas canvas,
    Offset point,
    Color color, {
    required bool selected,
  }) {
    canvas.drawCircle(point, selected ? 6.5 : 4.5, Paint()..color = color);

    canvas.drawCircle(point, selected ? 2.8 : 2, Paint()..color = surfaceColor);
  }

  void _drawMonthLabel(Canvas canvas, Offset point, String label, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: invoicedColor.withValues(alpha: .70),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    var x = point.dx - painter.width / 2;

    x = x.clamp(0.0, math.max(0.0, size.width - painter.width));

    painter.paint(canvas, Offset(x, size.height - 17));
  }

  @override
  bool shouldRepaint(covariant _InvoiceTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.invoicedColor != invoicedColor ||
        oldDelegate.collectedColor != collectedColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

// =============================================================================
// FINANCIAL BAR CHART
// =============================================================================

class _FinancialBarChart extends StatefulWidget {
  const _FinancialBarChart({
    required this.invoiced,
    required this.collected,
    required this.outstanding,
  });

  final double invoiced;
  final double collected;
  final double outstanding;

  @override
  State<_FinancialBarChart> createState() => _FinancialBarChartState();
}

class _FinancialBarChartState extends State<_FinancialBarChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final values = [
      ('Invoiced', widget.invoiced, scheme.primary),
      ('Collected', widget.collected, scheme.secondary),
      ('Outstanding', widget.outstanding, scheme.tertiary),
    ];

    final maximum = values.fold<double>(
      0,
      (max, value) => math.max(max, value.$2),
    );

    return Column(
      children: List.generate(values.length, (index) {
        final item = values[index];

        final fraction = maximum <= 0
            ? 0.0
            : (item.$2 / maximum).clamp(0.0, 1.0);

        final selected = selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() => selectedIndex = index);
            },
            onExit: (_) {
              setState(() => selectedIndex = null);
            },
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = selected ? null : index;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.$1,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected ? item.$3 : null,
                              ),
                        ),
                      ),
                      Text(
                        compactMoney(item.$2),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: selected ? 12 : 9,
                          width: double.infinity,
                          color: scheme.surfaceContainerHighest,
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: selected ? 12 : 9,
                            decoration: BoxDecoration(
                              color: item.$3,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// STATUS DONUT
// =============================================================================

class _StatusSlice {
  const _StatusSlice({required this.status, required this.count});

  final InvoiceStatus status;
  final int count;
}

class _StatusDonut extends StatefulWidget {
  const _StatusDonut({required this.entries});

  final List<_StatusSlice> entries;

  @override
  State<_StatusDonut> createState() => _StatusDonutState();
}

class _StatusDonutState extends State<_StatusDonut> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 520;

        final donut = MouseRegion(
          cursor: SystemMouseCursors.click,
          onExit: (_) {
            setState(() => selectedIndex = null);
          },
          onHover: (event) {
            final index = _hitTest(event.localPosition);

            if (index != selectedIndex) {
              setState(() => selectedIndex = index);
            }
          },
          child: GestureDetector(
            onTapUp: (details) {
              final index = _hitTest(details.localPosition);

              if (index != null) {
                setState(() {
                  selectedIndex = selectedIndex == index ? null : index;
                });
              }
            },
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _StatusDonutPainter(
                  entries: widget.entries,
                  selectedIndex: selectedIndex,
                  colors: _statusColors(scheme, widget.entries.length),
                  surfaceColor: scheme.surface,
                  trackColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
        );

        final legend = _StatusLegend(
          entries: widget.entries,
          selectedIndex: selectedIndex,
          colors: _statusColors(scheme, widget.entries.length),
          onSelect: (index) {
            setState(() {
              selectedIndex = selectedIndex == index ? null : index;
            });
          },
        );

        if (horizontal) {
          return Row(
            children: [
              donut,
              const SizedBox(width: 20),
              Expanded(child: legend),
            ],
          );
        }

        return Column(children: [donut, const SizedBox(height: 16), legend]);
      },
    );
  }

  int? _hitTest(Offset position) {
    const size = 200.0;

    final center = Offset(size / 2, size / 2);

    final distance = (position - center).distance;

    if (distance < 40 || distance > 88) {
      return null;
    }

    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    var angle = math.atan2(dy, dx) + math.pi / 2;

    if (angle < 0) {
      angle += math.pi * 2;
    }

    final total = widget.entries.fold<int>(0, (sum, item) => sum + item.count);

    if (total <= 0) return null;

    var start = 0.0;

    for (var i = 0; i < widget.entries.length; i++) {
      final sweep = widget.entries[i].count / total * math.pi * 2;

      if (angle >= start && angle <= start + sweep) {
        return i;
      }

      start += sweep;
    }

    return null;
  }
}

// =============================================================================
// STATUS LEGEND
// =============================================================================

class _StatusLegend extends StatelessWidget {
  const _StatusLegend({
    required this.entries,
    required this.selectedIndex,
    required this.colors,
    required this.onSelect,
  });

  final List<_StatusSlice> entries;
  final int? selectedIndex;
  final List<Color> colors;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, item) => sum + item.count);

    return Column(
      children: List.generate(entries.length, (index) {
        final item = entries[index];

        final percentage = total <= 0 ? 0.0 : item.count / total * 100;

        final selected = selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => onSelect(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: selected ? 11 : 9,
                    height: selected ? 11 : 9,
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      invoiceStatusLabel(item.status),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// STATUS DONUT PAINTER
// =============================================================================

class _StatusDonutPainter extends CustomPainter {
  const _StatusDonutPainter({
    required this.entries,
    required this.selectedIndex,
    required this.colors,
    required this.surfaceColor,
    required this.trackColor,
  });

  final List<_StatusSlice> entries;
  final int? selectedIndex;
  final List<Color> colors;
  final Color surfaceColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final total = entries.fold<int>(0, (sum, item) => sum + item.count);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;

    canvas.drawCircle(center, 58, track);

    if (total <= 0) {
      _drawCenter(canvas, center, '0', 'invoices');
      return;
    }

    var start = -math.pi / 2;

    for (var i = 0; i < entries.length; i++) {
      final sweep = entries[i].count / total * math.pi * 2;

      if (sweep <= 0) continue;

      final selected = selectedIndex == i;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 34 : 28
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 58),
        start + .018,
        math.max(0, sweep - .036),
        false,
        paint,
      );

      start += sweep;
    }

    final centerCount = selectedIndex == null
        ? total
        : entries[selectedIndex!].count;

    final centerLabel = selectedIndex == null
        ? 'invoices'
        : invoiceStatusLabel(entries[selectedIndex!].status);

    _drawCenter(canvas, center, '$centerCount', centerLabel);
  }

  void _drawCenter(Canvas canvas, Offset center, String value, String label) {
    final valueColor = surfaceColor.computeLuminance() > .5
        ? Colors.black
        : Colors.white;

    final secondaryColor = surfaceColor.computeLuminance() > .5
        ? Colors.black54
        : Colors.white70;

    final valuePainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: valueColor,
          fontSize: 25,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: secondaryColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    valuePainter.paint(
      canvas,
      Offset(center.dx - valuePainter.width / 2, center.dy - 18),
    );

    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy + 10),
    );
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.colors != colors ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.trackColor != trackColor;
  }
}

// =============================================================================
// STATUS COLORS
// =============================================================================

List<Color> _statusColors(ColorScheme scheme, int count) {
  final palette = [
    scheme.primary,
    scheme.secondary,
    scheme.tertiary,
    scheme.primaryContainer,
    scheme.secondaryContainer,
    scheme.tertiaryContainer,
    scheme.outline,
  ];

  return List.generate(count, (index) => palette[index % palette.length]);
}
