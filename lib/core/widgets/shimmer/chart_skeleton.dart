import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/widgets/shimmer/list_tile_skeleton.dart';
import 'package:inflabasket/core/widgets/shimmer/shimmer_container.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

enum ChartSkeletonVariant { line, bar }

class ChartSkeleton extends StatefulWidget {
  const ChartSkeleton.overview({super.key})
      : showSummaryCard = true,
        showInflationLists = true,
        showCategoryList = false,
        variant = ChartSkeletonVariant.line;

  const ChartSkeleton.categories({super.key})
      : showSummaryCard = false,
        showInflationLists = false,
        showCategoryList = true,
        variant = ChartSkeletonVariant.bar;

  final bool showSummaryCard;
  final bool showInflationLists;
  final bool showCategoryList;
  final ChartSkeletonVariant variant;

  @override
  State<ChartSkeleton> createState() => _ChartSkeletonState();
}

class _ChartSkeletonState extends State<ChartSkeleton> {
  Timer? _timeoutTimer;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showFallback = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showFallback
          ? StateMessageCard(
              key: const ValueKey('chart-timeout'),
              icon: Icons.hourglass_empty,
              animationAsset: StateIllustrations.loadingMinimal,
              title: l10n.loadingStillTitle,
              message: l10n.loadingStillMessage,
              isLoading: true,
            )
          : _ChartSkeletonContent(
              key: const ValueKey('chart-skeleton'),
              showSummaryCard: widget.showSummaryCard,
              showInflationLists: widget.showInflationLists,
              showCategoryList: widget.showCategoryList,
              variant: widget.variant,
            ),
    );
  }
}

class _ChartSkeletonContent extends StatelessWidget {
  const _ChartSkeletonContent({
    super.key,
    required this.showSummaryCard,
    required this.showInflationLists,
    required this.showCategoryList,
    required this.variant,
  });

  final bool showSummaryCard;
  final bool showInflationLists;
  final bool showCategoryList;
  final ChartSkeletonVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.loadingChart,
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSummaryCard) ...[
                const _SkeletonPanel(
                  child: SizedBox(height: 104, child: _SummaryCardSkeleton()),
                ),
                const SizedBox(height: 24),
              ],
              const _SectionLabelSkeleton(),
              const SizedBox(height: 8),
              const _TimeRangeSkeleton(),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: ShimmerContainer(width: 168, height: 14),
              ),
              const SizedBox(height: 12),
              _SkeletonPanel(
                child: SizedBox(
                  height: variant == ChartSkeletonVariant.line ? 280 : 300,
                  child: _ChartCanvasSkeleton(variant: variant),
                ),
              ),
              if (showInflationLists) ...const [
                SizedBox(height: 24),
                _TitleSkeleton(),
                SizedBox(height: 16),
                _OverviewListSkeleton(),
                SizedBox(height: 24),
                _TitleSkeleton(),
                SizedBox(height: 16),
                _OverviewListSkeleton(),
              ],
              if (showCategoryList) ...const [
                SizedBox(height: 24),
                _TitleSkeleton(),
                SizedBox(height: 16),
                _CategoryListSkeleton(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isLuxeMode
            ? AppColors.bgElevated.withValues(alpha: 0.9)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLuxeMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerContainer(width: 120, height: 14),
              SizedBox(height: 12),
              ShimmerContainer(width: 156, height: 36),
            ],
          ),
        ),
        SizedBox(width: 16),
        ShimmerContainer(width: 64, height: 64, shape: BoxShape.circle),
      ],
    );
  }
}

class _SectionLabelSkeleton extends StatelessWidget {
  const _SectionLabelSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerContainer(width: 88, height: 12);
  }
}

class _TimeRangeSkeleton extends StatelessWidget {
  const _TimeRangeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        6,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
            child: const ShimmerContainer(height: 36),
          ),
        ),
      ),
    );
  }
}

class _TitleSkeleton extends StatelessWidget {
  const _TitleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerContainer(width: 170, height: 24);
  }
}

class _OverviewListSkeleton extends StatelessWidget {
  const _OverviewListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTileSkeleton(showLeading: false),
        ListTileSkeleton(showLeading: false),
        ListTileSkeleton(showLeading: false),
      ],
    );
  }
}

class _CategoryListSkeleton extends StatelessWidget {
  const _CategoryListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTileSkeleton(),
        ListTileSkeleton(),
        ListTileSkeleton(),
        ListTileSkeleton(),
      ],
    );
  }
}

class _ChartCanvasSkeleton extends StatelessWidget {
  const _ChartCanvasSkeleton({required this.variant});

  final ChartSkeletonVariant variant;

  @override
  Widget build(BuildContext context) {
    return ShimmerContainer(
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: variant == ChartSkeletonVariant.line
            ? const _LineChartSkeletonPainter()
            : const _BarChartSkeletonPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LineChartSkeletonPainter extends CustomPainter {
  const _LineChartSkeletonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final areaPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final baselineY = size.height - 42;
    final guidePath = Path()
      ..moveTo(0, baselineY)
      ..lineTo(size.width, baselineY);
    canvas.drawPath(guidePath, framePaint);

    final linePath = Path()
      ..moveTo(8, baselineY - 12)
      ..cubicTo(size.width * 0.12, baselineY - 58, size.width * 0.22,
          baselineY - 96, size.width * 0.35, baselineY - 76)
      ..cubicTo(size.width * 0.48, baselineY - 58, size.width * 0.58,
          baselineY - 138, size.width * 0.7, baselineY - 118)
      ..cubicTo(size.width * 0.82, baselineY - 98, size.width * 0.9,
          baselineY - 30, size.width - 8, baselineY - 64);

    final areaPath = Path.from(linePath)
      ..lineTo(size.width - 8, baselineY)
      ..lineTo(8, baselineY)
      ..close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, framePaint);

    for (final x in [0.12, 0.35, 0.58, 0.8]) {
      canvas.drawCircle(
        Offset(size.width * x, baselineY - 60),
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarChartSkeletonPainter extends CustomPainter {
  const _BarChartSkeletonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final baselineY = size.height - 40;
    canvas.drawRect(Rect.fromLTWH(0, baselineY, size.width, 2), paint);

    const barCount = 6;
    final spacing = size.width / (barCount * 2);
    final barWidth = spacing * 1.15;
    final heights = [0.42, 0.68, 0.5, 0.78, 0.35, 0.6];

    for (var index = 0; index < barCount; index++) {
      final left = spacing * (index * 2 + 0.5);
      final barHeight = (size.height - 84) * heights[index];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baselineY - barHeight, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
