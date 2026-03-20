import 'dart:math' show min, max;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inflabasket/core/mixins/chart_touch_state.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/core/theme/chart_animations.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/shimmer/chart_skeleton.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/utils/chart_sizing.dart';
import 'package:inflabasket/core/widgets/custom_date_range_dialog.dart';
import 'package:inflabasket/core/widgets/inflation_summary_card.dart';
import 'package:inflabasket/core/widgets/time_range_selector.dart';
import 'package:inflabasket/core/widgets/chart_header.dart';
import 'package:inflabasket/core/widgets/inflation_list_view.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class _ChartTickConfig {
  const _ChartTickConfig({
    required this.format,
    required this.interval,
    required this.minInterval,
    required this.reservedSize,
  });

  final String format;
  final double interval;
  final double minInterval;
  final double reservedSize;
}

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab>
    with ChartTouchState {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(entriesWithDetailsProvider);
    final settings = ref.watch(settingsControllerProvider);
    final isBitcoinMode = settings.isBitcoinMode;
    final entries = entriesAsync.valueOrNull ?? const <EntryWithDetails>[];
    final historySatsAsync = isBitcoinMode
        ? ref.watch(filteredDynamicIndexSatsProvider)
        : const AsyncData<List<MonthlyIndex>>(<MonthlyIndex>[]);
    final allHistorySatsAsync = isBitcoinMode
        ? ref.watch(dynamicLaspeyresIndexSatsProvider)
        : const AsyncData<List<MonthlyIndex>>(<MonthlyIndex>[]);
    final topInflatorsSatsAsync = isBitcoinMode
        ? ref.watch(overallItemInflationListSatsProvider)
        : const AsyncData<List<ItemInflationSats>>(<ItemInflationSats>[]);
    final yearlySummarySatsAsync = isBitcoinMode
        ? ref.watch(overallYearlyInflationSummarySatsProvider)
        : const AsyncData<YearlyInflationSummary>(
            YearlyInflationSummary.empty());
    final bitcoinHistory = historySatsAsync.valueOrNull;
    final bitcoinAllHistory = allHistorySatsAsync.valueOrNull;
    final bitcoinTopInflators = topInflatorsSatsAsync.valueOrNull;
    final bitcoinYearlySummary = yearlySummarySatsAsync.valueOrNull;

    final hasEntriesData = entriesAsync.valueOrNull != null;
    final isInitialLoading = !hasEntriesData && entriesAsync.isLoading;
    final bitcoinLoading = isBitcoinMode &&
        ((historySatsAsync.isLoading && bitcoinHistory == null) ||
            (allHistorySatsAsync.isLoading && bitcoinAllHistory == null) ||
            (topInflatorsSatsAsync.isLoading && bitcoinTopInflators == null) ||
            (yearlySummarySatsAsync.isLoading && bitcoinYearlySummary == null));

    final coreError = entriesAsync.hasError && !hasEntriesData
        ? entriesAsync.error
        : !isBitcoinMode || bitcoinLoading
            ? null
            : historySatsAsync.hasError && bitcoinHistory == null
                ? historySatsAsync.error
                : allHistorySatsAsync.hasError && bitcoinAllHistory == null
                    ? allHistorySatsAsync.error
                    : topInflatorsSatsAsync.hasError &&
                            bitcoinTopInflators == null
                        ? topInflatorsSatsAsync.error
                        : yearlySummarySatsAsync.hasError &&
                                bitcoinYearlySummary == null
                            ? yearlySummarySatsAsync.error
                            : null;

    final loadingChild = isInitialLoading
        ? const ChartSkeleton.overview(key: ValueKey('overview-loading'))
        : coreError != null
            ? StateMessageCard(
                key: const ValueKey('overview-error'),
                icon: Icons.error_outline,
                animationAsset: StateIllustrations.error,
                loop: false,
                title: l.errorGeneric,
                message: coreError.toString(),
              )
            : null;

    if (loadingChild != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: loadingChild,
      );
    }

    final fiatYearlySummary = ref.watch(overallYearlyInflationSummaryProvider);
    final fiatHistory = ref.watch(filteredDynamicIndexProvider);
    final fiatTopInflators = ref.watch(overallItemInflationListProvider);
    final displayBitcoinData =
        isBitcoinMode && !bitcoinLoading && coreError == null;

    final yearlySummary = displayBitcoinData
        ? bitcoinYearlySummary ?? const YearlyInflationSummary.empty()
        : fiatYearlySummary;

    final history = displayBitcoinData
        ? bitcoinHistory ?? const <MonthlyIndex>[]
        : fiatHistory;
    final showCpi = ref.watch(showCpiOverlayProvider);
    final overlayType = ref.watch(effectiveComparisonOverlayTypeProvider);
    final overlayAsync = ref.watch(comparisonOverlayDataProvider);
    final availableTypes = availableComparisonOverlayTypes(settings.currency);
    final hasOverlaySource = availableTypes.isNotEmpty;
    final overlayPoints =
        overlayAsync.valueOrNull ?? const <ComparisonDataPoint>[];
    final hasOverlayData = overlayPoints.isNotEmpty;
    final isLuxeMode = Theme.of(context).brightness == Brightness.dark;
    final timeFilter = ref.watch(chartTimeFilterControllerProvider);
    final firstDataPoint = entries.isNotEmpty
        ? entries
            .map<DateTime>((entry) => entry.entry.purchaseDate)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final availableTimeRangeOptions = availableTimeRanges(entries);
    final selectedRange = resolveTimeRangeSelection(
      timeFilter,
      availableTimeRangeOptions,
    );

    final topInflators = displayBitcoinData
        ? bitcoinTopInflators ?? const <ItemInflationSats>[]
        : fiatTopInflators;

    return SingleChildScrollView(
      key: const ValueKey('overview-content'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InflationSummaryCard(
            summary: yearlySummary,
            title: l.overviewTitle,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TimeRangeSelector(
                timeFilter: timeFilter,
                selectedRange: selectedRange,
                availableOptions: availableTimeRangeOptions,
                firstDataPoint: firstDataPoint,
                onRangeChanged: (range) => ref
                    .read(chartTimeFilterControllerProvider.notifier)
                    .setRange(range),
                onCustomRangeRequested: (_) => _showCustomDatePicker(
                  context,
                  ref,
                  timeFilter,
                  firstDataPoint,
                ),
              ),
              ChartHeader(
                availableTypes: availableTypes,
                overlayType: overlayType,
                showCpi: showCpi,
                isLoading: overlayAsync.isLoading,
                onOverlayTypeChanged: (type) => ref
                    .read(selectedComparisonOverlayTypeProvider.notifier)
                    .set(type),
                onToggleCpi: () =>
                    ref.read(showCpiOverlayProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLineChart(
              context, l, history, showCpi, overlayPoints, selectedRange),
          if (showCpi && hasOverlaySource) ...[
            const SizedBox(height: 8),
            _buildOverlayStatus(context, l, overlayAsync, hasOverlayData),
          ],
          if (showCpi && hasOverlayData && overlayType != null) ...[
            const SizedBox(height: 8),
            _buildChartLegend(context, l, overlayType, isLuxeMode),
          ],
          const SizedBox(height: 24),
          Text(l.overviewTopInflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          InflationListView(
            items: displayBitcoinData
                ? (topInflators as List<ItemInflationSats>).toInflationList()
                : (topInflators as List<ItemInflation>).toInflationList(),
            isBitcoinMode: displayBitcoinData,
            settings: settings,
            isInflatorsList: true,
          ),
          const SizedBox(height: 24),
          Text(l.overviewTopDeflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          InflationListView(
            items: displayBitcoinData
                ? (topInflators as List<ItemInflationSats>).toInflationList()
                : (topInflators as List<ItemInflation>).toInflationList(),
            isBitcoinMode: displayBitcoinData,
            settings: settings,
            isInflatorsList: false,
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDatePicker(
    BuildContext context,
    WidgetRef ref,
    ChartTimeFilter currentFilter,
    DateTime? firstDataPoint,
  ) async {
    final now = DateTime.now();
    final minDate = firstDataPoint ?? DateTime(now.year - 5, 1, 1);
    final maxDate = DateTime(now.year, now.month, 1);

    DateTime startDate =
        currentFilter.customStart ?? DateTime(now.year - 1, now.month, 1);
    DateTime endDate = currentFilter.customEnd ?? maxDate;

    final result = await CustomDateRangeDialog.show(
      context: context,
      initialStart: startDate,
      initialEnd: endDate,
      minDate: minDate,
      maxDate: maxDate,
    );

    if (result != null) {
      ref.read(chartTimeFilterControllerProvider.notifier).setCustomRange(
            result.$1,
            result.$2,
          );
    }
  }

  Widget _buildOverlayStatus(BuildContext context, AppLocalizations l,
      AsyncValue<List<ComparisonDataPoint>> overlayAsync, bool hasOverlayData) {
    if (overlayAsync.isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l.loading,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
    if (!hasOverlayData) {
      return Text(
        l.comparisonLoadError,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      );
    }
    return const SizedBox.shrink();
  }

  void _showOverlaySourceInfo(
    BuildContext context,
    AppLocalizations l,
    ComparisonOverlayType overlayType,
    String currency,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overlayType == ComparisonOverlayType.snbCoreInflation
                    ? l.cpiSourceTitle
                    : l.moneySupplySourceTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                _overlaySourceDescription(l, overlayType, currency),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  String _overlaySourceDescription(
    AppLocalizations l,
    ComparisonOverlayType overlayType,
    String currency,
  ) {
    return switch (overlayType) {
      ComparisonOverlayType.moneySupply => switch (currency) {
          'CHF' => l.moneySupplySourceChfDescription,
          'EUR' => l.moneySupplySourceEurDescription,
          'USD' => l.moneySupplySourceUsdDescription,
          'GBP' => l.moneySupplySourceGbpDescription,
          _ => l.moneySupplySourceUnavailableDescription,
        },
      ComparisonOverlayType.snbCoreInflation => l.cpiSourceChfDescription,
    };
  }

  Widget _buildChartLegend(BuildContext context, AppLocalizations l,
      ComparisonOverlayType overlayType, bool isLuxeMode) {
    return Row(
      children: [
        _legendDot(Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(l.yourInflation, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 16),
        _legendDot(isLuxeMode
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Colors.orange),
        const SizedBox(width: 4),
        Text(_overlayLabel(l, overlayType),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _overlayLabel(AppLocalizations l, ComparisonOverlayType overlayType) {
    return switch (overlayType) {
      ComparisonOverlayType.moneySupply => l.moneySupplyM2,
      ComparisonOverlayType.snbCoreInflation => l.coreInflationSnb,
    };
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  _ChartTickConfig _buildTickConfig(
    ChartTimeRange range,
    List<MonthlyIndex> validHistory,
    double chartWidth,
  ) {
    if (validHistory.length < 2) {
      return const _ChartTickConfig(
        format: 'MMM',
        interval: 2629800000,
        minInterval: 2629800000,
        reservedSize: 32,
      );
    }

    final start = validHistory.first.month;
    final end = validHistory.last.month;
    final totalMonths = max(
      1,
      monthsBetween(DateTime(start.year, start.month),
              DateTime(end.year, end.month)) +
          1,
    );
    final estimatedLabelWidth = switch (range) {
      ChartTimeRange.sixMonths || ChartTimeRange.oneYear => 44.0,
      ChartTimeRange.twoYears || ChartTimeRange.threeYears => 64.0,
      ChartTimeRange.fiveYears || ChartTimeRange.tenYears => 42.0,
      ChartTimeRange.custom => totalMonths <= 18 ? 44.0 : 64.0,
    };
    // Use fewer target labels (max 5) to prevent overlap
    final targetLabels =
        max(2, min(5, (chartWidth / estimatedLabelWidth).floor()));
    final rawStepMonths = max(1, (totalMonths / targetLabels).ceil());
    final stepMonths = _niceMonthStep(rawStepMonths);
    final format = _tickDateFormat(totalMonths, stepMonths);

    // Calculate min interval to prevent too-frequent ticks (based on label width)
    final totalRangeMs = end.difference(start).inMilliseconds.toDouble();
    final minInterval = (totalRangeMs / targetLabels * 0.8).clamp(
      stepMonths * 20 * Duration.millisecondsPerDay.toDouble(),
      double.infinity,
    );

    return _ChartTickConfig(
      format: format,
      interval: stepMonths * 30.4375 * Duration.millisecondsPerDay,
      minInterval: minInterval,
      reservedSize: format == 'yyyy' ? 30 : 38,
    );
  }

  int _niceMonthStep(int rawStepMonths) {
    const steps = <int>[1, 2, 3, 4, 6, 12, 18, 24, 36, 60];
    for (final step in steps) {
      if (rawStepMonths <= step) return step;
    }
    return steps.last;
  }

  String _tickDateFormat(int totalMonths, int stepMonths) {
    if (totalMonths <= 18 && stepMonths <= 3) {
      return 'MMM';
    }
    if (stepMonths >= 12 || totalMonths > 72) {
      return 'yyyy';
    }
    return "MMM ''yy";
  }

  List<MonthlyIndex> _aggregateByPeriod(
    List<MonthlyIndex> history,
    ChartTimeRange range,
  ) {
    if (history.isEmpty) return history;

    DateTime periodStart(DateTime date) {
      switch (range) {
        case ChartTimeRange.sixMonths:
        case ChartTimeRange.oneYear:
        case ChartTimeRange.custom:
          return DateTime(date.year, date.month, 1);
        case ChartTimeRange.twoYears:
        case ChartTimeRange.threeYears:
          final quarter = (date.month - 1) ~/ 3;
          return DateTime(date.year, quarter * 3 + 1, 1);
        case ChartTimeRange.fiveYears:
        case ChartTimeRange.tenYears:
          return DateTime(date.year, 1, 1);
      }
    }

    final groups = <DateTime, List<MonthlyIndex>>{};
    for (final point in history) {
      final key = periodStart(point.month);
      groups.putIfAbsent(key, () => []).add(point);
    }

    return groups.entries.map((entry) {
      final avgIndex = entry.value.map((p) => p.index).reduce((a, b) => a + b) /
          entry.value.length;
      final latest =
          entry.value.reduce((a, b) => a.month.isAfter(b.month) ? a : b);
      return MonthlyIndex(
        month: entry.key,
        index: avgIndex,
        chartPoint: latest.chartPoint,
      );
    }).toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  Widget _buildLineChart(
    BuildContext context,
    AppLocalizations l,
    List<MonthlyIndex> history,
    bool showCpi,
    List<ComparisonDataPoint> overlayPoints,
    ChartTimeRange timeRange,
  ) {
    final validHistory = history.where((h) => h.index.isFinite).toList();
    if (validHistory.isEmpty) {
      return SizedBox(
        height: responsiveChartHeight(context, type: ChartType.line),
        child: StateMessageCard(
          icon: Icons.show_chart,
          title: l.overviewTitle,
          message: l.overviewNoData,
        ),
      );
    }

    final aggregatedHistory = _aggregateByPeriod(validHistory, timeRange);
    final shouldAnimate = animationsEnabled(
      context,
      pointCount: aggregatedHistory.length,
    );

    final spots = aggregatedHistory
        .map((e) => FlSpot(
              e.month.millisecondsSinceEpoch.toDouble(),
              e.index - 100,
            ))
        .toList();

    List<FlSpot> comparisonSpots = [];
    if (showCpi && overlayPoints.isNotEmpty) {
      DateTime periodStart(DateTime date) {
        switch (timeRange) {
          case ChartTimeRange.sixMonths:
          case ChartTimeRange.oneYear:
          case ChartTimeRange.custom:
            return DateTime(date.year, date.month, 1);
          case ChartTimeRange.twoYears:
          case ChartTimeRange.threeYears:
            final quarter = (date.month - 1) ~/ 3;
            return DateTime(date.year, quarter * 3 + 1, 1);
          case ChartTimeRange.fiveYears:
          case ChartTimeRange.tenYears:
            return DateTime(date.year, 1, 1);
        }
      }

      final basketStart = aggregatedHistory.first.month;
      final basketEnd = aggregatedHistory.last.month;
      final relevantCpi = overlayPoints.where(
          (p) => !p.month.isBefore(basketStart) && !p.month.isAfter(basketEnd));

      final cpiGroups = <DateTime, List<ComparisonDataPoint>>{};
      for (final cp in relevantCpi) {
        final key = periodStart(cp.month);
        cpiGroups.putIfAbsent(key, () => []).add(cp);
      }

      comparisonSpots = cpiGroups.entries.map((entry) {
        final avgIndex =
            entry.value.map((p) => p.index).reduce((a, b) => a + b) /
                entry.value.length;
        return FlSpot(
          entry.key.millisecondsSinceEpoch.toDouble(),
          avgIndex - 100,
        );
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));

      // Offset comparison curve so first tooltip starts at exactly 0%
      if (comparisonSpots.isNotEmpty) {
        final offset = comparisonSpots.first.y;
        comparisonSpots =
            comparisonSpots.map((s) => FlSpot(s.x, s.y - offset)).toList();
      }
    }

    // Compute explicit Y bounds
    final allYValues = [
      ...spots.map((s) => s.y),
      if (comparisonSpots.isNotEmpty) ...comparisonSpots.map((s) => s.y),
    ];
    final dataMinY = allYValues.reduce(min);
    final dataMaxY = allYValues.reduce(max);
    final chartMinY = dataMinY == dataMaxY ? dataMinY - 10.0 : dataMinY;
    final chartMaxY = dataMinY == dataMaxY ? dataMaxY + 10.0 : dataMaxY;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowOpacity = isDark ? 0.6 : 0.35;
    final chartHeight = responsiveChartHeight(context, type: ChartType.line);

    final barData = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: primaryColor,
        barWidth: isDark ? 3 : 4,
        isStrokeCapRound: true,
        shadow: isDark
            ? Shadow(color: primaryColor.withValues(alpha: 0.8), blurRadius: 8)
            : const Shadow(color: Colors.transparent),
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.3),
                    Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.0),
                  ],
                )
              : null,
          color: isDark ? null : primaryColor.withValues(alpha: 0.2),
        ),
      ),
      if (showCpi && comparisonSpots.isNotEmpty)
        LineChartBarData(
          spots: comparisonSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: isDark
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Colors.orange,
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
    ];

    return SizedBox(
      key: ValueKey('linechart-container-${timeRange.name}'),
      height: chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tickConfig = _buildTickConfig(
              timeRange, aggregatedHistory, constraints.maxWidth);
          return LineChart(
            LineChartData(
              minY: chartMinY,
              maxY: chartMaxY,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: tickConfig.reservedSize,
                    interval: tickConfig.interval,
                    maxIncluded: false,
                    minIncluded: false,
                    getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return SideTitleWidget(
                        meta: meta,
                        fitInside: SideTitleFitInsideData.fromTitleMeta(
                          meta,
                          distanceFromEdge: 8,
                          enabled: true,
                        ),
                        child: Text(
                          DateFormat(tickConfig.format).format(date),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                  ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: barData,
              lineTouchData: LineTouchData(
                enabled: true,
                touchSpotThreshold: 35,
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent ||
                      response?.lineBarSpots == null) {
                    return;
                  }
                  if (!handleTouchDebounce()) return;
                  HapticFeedback.lightImpact();
                },
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((index) {
                    final indicatorColor = barData.color ?? primaryColor;
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: indicatorColor.withValues(alpha: 0.6),
                        strokeWidth: 2,
                        dashArray: [4, 3],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, spotIndex) {
                          return GlowDotPainter(
                            color: indicatorColor,
                            radius: 8,
                            glowColor:
                                indicatorColor.withValues(alpha: glowOpacity),
                            glowRadius: 12,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  tooltipMargin: 20,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final nearest = validHistory.reduce((a, b) {
                        final da =
                            (a.month.millisecondsSinceEpoch.toDouble() - spot.x)
                                .abs();
                        final db =
                            (b.month.millisecondsSinceEpoch.toDouble() - spot.x)
                                .abs();
                        return da <= db ? a : b;
                      });
                      final dateStr =
                          DateFormat('MMM yyyy').format(nearest.month);
                      final delta = spot.y;
                      final label =
                          '$dateStr\n${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%';
                      return LineTooltipItem(
                        label,
                        TextStyle(
                          color: spot.bar.color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
            duration: shouldAnimate
                ? ChartAnimations.entranceDurationFor(aggregatedHistory.length)
                : Duration.zero,
            curve: ChartAnimations.entranceCurve,
          );
        },
      ),
    );
  }
}
