import 'package:flutter/material.dart';

/// Shared shimmer surface used by screen-shaped loading states.
/// It only paints placeholders and never participates in loading or caching.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, required this.child});

  final Widget child;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionDisabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionDisabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = _motionDisabled
        ? ExcludeSemantics(child: widget.child)
        : ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = -1.4 + (_controller.value * 2.8);
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(offset, 0),
                    end: Alignment(offset + .9, 0),
                    colors: [
                      scheme.surfaceContainerLow,
                      scheme.surfaceContainerHighest,
                      scheme.surfaceContainerLow,
                    ],
                  ).createShader(bounds),
                  child: child,
                );
              },
              child: widget.child,
            ),
          );
    return Semantics(
      label: 'Loading content',
      liveRegion: true,
      child: placeholder,
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Dashboard-specific skeleton: KPI Bento layout, chart area and invoice rows.
class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SkeletonBlock(width: 142, height: 16, radius: 6),
          const SizedBox(height: 8),
          const _SkeletonBlock(width: 210, height: 27, radius: 7),
          const SizedBox(height: 18),
          const _SkeletonBlock(height: 122, radius: 18),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 96, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBlock(height: 96, radius: 16)),
            ],
          ),
          const SizedBox(height: 10),
          const _SkeletonBlock(height: 66, radius: 15),
          const SizedBox(height: 16),
          const _SkeletonBlock(height: 205, radius: 18),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 136, radius: 18)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBlock(height: 136, radius: 18)),
            ],
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < 2; index++) ...[
            const _SkeletonBlock(height: 70, radius: 15),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

/// Responsive record-list placeholder shared by invoices, customers,
/// products and archived records.
class RecordListLoadingState extends StatelessWidget {
  const RecordListLoadingState({
    super.key,
    this.rows = 3,
    this.showHeader = true,
    this.showSearch = false,
    this.showFilters = false,
  });

  final int rows;
  final bool showHeader;
  final bool showSearch;
  final bool showFilters;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            const _SkeletonBlock(width: 150, height: 25, radius: 7),
            const SizedBox(height: 8),
            const _SkeletonBlock(width: 230, height: 13, radius: 6),
            const SizedBox(height: 16),
          ],
          if (showSearch) ...[
            const _SkeletonBlock(height: 54, radius: 15),
            const SizedBox(height: 12),
          ],
          if (showFilters) ...[
            const Row(
              children: [
                _SkeletonBlock(width: 58, height: 31, radius: 18),
                SizedBox(width: 8),
                _SkeletonBlock(width: 78, height: 31, radius: 18),
                SizedBox(width: 8),
                _SkeletonBlock(width: 78, height: 31, radius: 18),
              ],
            ),
            const SizedBox(height: 13),
          ],
          for (var index = 0; index < rows; index++) ...[
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  _SkeletonBlock(width: 42, height: 42, radius: 14),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBlock(width: 136, height: 13, radius: 5),
                        SizedBox(height: 8),
                        _SkeletonBlock(width: 92, height: 10, radius: 5),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  _SkeletonBlock(width: 54, height: 12, radius: 5),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

/// Report page placeholder with the same KPI, summary and chart hierarchy.
class ReportsLoadingState extends StatelessWidget {
  const ReportsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SkeletonBlock(height: 66, radius: 16),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 90, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBlock(height: 90, radius: 16)),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _SkeletonBlock(height: 90, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBlock(height: 90, radius: 16)),
            ],
          ),
          const SizedBox(height: 14),
          const _SkeletonBlock(height: 150, radius: 18),
          const SizedBox(height: 14),
          const _SkeletonBlock(height: 205, radius: 18),
          const SizedBox(height: 14),
          for (var index = 0; index < 2; index++) ...[
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

/// Plan-card placeholder adapts between a stacked phone layout and a row.
class PlanLoadingState extends StatelessWidget {
  const PlanLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = List.generate(
            constraints.maxWidth >= 760 ? 3 : 2,
            (index) => Container(
              height: 218,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(width: 118, height: 15, radius: 6),
                  SizedBox(height: 12),
                  _SkeletonBlock(width: 154, height: 30, radius: 7),
                  SizedBox(height: 14),
                  _SkeletonBlock(height: 10, radius: 5),
                  SizedBox(height: 8),
                  _SkeletonBlock(width: 180, height: 10, radius: 5),
                  Spacer(),
                  _SkeletonBlock(height: 42, radius: 12),
                ],
              ),
            ),
          );
          if (constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index < cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          }
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Kept as a compatibility wrapper for any existing loading call sites.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) => RecordListLoadingState(
    rows: rows,
    showHeader: false,
  );
}
