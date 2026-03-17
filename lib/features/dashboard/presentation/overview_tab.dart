import 'dart:math' show min, max;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/mixins/chart_touch_state.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/theme/chart_animations.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/shimmer/chart_skeleton.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/utils/chart_sizing.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/core/widgets/tabular_amount_text.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

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
        ? ref.watch(itemInflationListSatsProvider)
        : const AsyncData<List<ItemInflationSats>>(<ItemInflationSats>[]);
    final yearlySummarySatsAsync = isBitcoinMode
        ? ref.watch(yearlyBasketInflationSummarySatsProvider)
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

    final fiatYearlySummary = ref.watch(yearlyBasketInflationSummaryProvider);
    final fiatHistory = ref.watch(filteredDynamicIndexProvider);
    final fiatTopInflators = ref.watch(itemInflationListProvider);
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
    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;
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
          _buildSummaryCard(context, l, yearlySummary),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeRangeSelector(
                context,
                l,
                ref,
                timeFilter,
                selectedRange,
                availableTimeRangeOptions,
                firstDataPoint,
              ),
              _buildChartHeader(
                context,
                l,
                ref,
                availableTypes,
                overlayType,
                showCpi,
                overlayAsync.isLoading,
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
          _buildTopInflators(
            context,
            l,
            topInflators,
            settings,
            displayBitcoinData,
          ),
          const SizedBox(height: 24),
          Text(l.overviewTopDeflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildTopDeflators(
            context,
            l,
            topInflators,
            settings,
            displayBitcoinData,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AppLocalizations l,
      YearlyInflationSummary summary) {
    final title = l.overviewTitle;
    if (summary.qualifyingProducts <= 0) {
      return StateMessageCard(
        icon: Icons.show_chart,
        animationAsset: StateIllustrations.emptyGeneral,
        animationHeight: 140,
        title: title,
        message: l.overviewNoData,
      );
    }

    final inflation = summary.yearlyInflationPercent;
    final color = inflation > 0
        ? Colors.red
        : (inflation < 0 ? Colors.green : Colors.grey);
    final icon = inflation > 0
        ? Icons.trending_up
        : (inflation < 0 ? Icons.trending_down : Icons.trending_flat);

    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

    return isLuxeMode
        ? VaultCard(
            isActive: true,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: TabularAmountText(
                          '${inflation > 0 ? '+' : ''}${inflation.toStringAsFixed(1)}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, size: 32, color: color),
                )
              ],
            ),
          )
        : Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: TabularAmountText(
                            '${inflation > 0 ? '+' : ''}${inflation.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, size: 32, color: color),
                  )
                ],
              ),
            ),
          );
  }

  Widget _buildTimeRangeSelector(
    BuildContext context,
    AppLocalizations l,
    WidgetRef ref,
    ChartTimeFilter timeFilter,
    ChartTimeRange selectedRange,
    List<ChartTimeRange> availableOptions,
    DateTime? firstDataPoint,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<ChartTimeRange>(
        value: availableOptions.contains(selectedRange)
            ? selectedRange
            : availableOptions.first,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down),
        items: availableOptions.map((range) {
          return DropdownMenuItem(
            value: range,
            child: Text(
              range == ChartTimeRange.custom
                  ? l.timeRangeCustom
                  : _timeRangeLabel(l, range),
            ),
          );
        }).toList(),
        onChanged: (range) {
          if (range == null) return;
          if (range == ChartTimeRange.custom) {
            _showCustomDatePicker(context, ref, timeFilter, firstDataPoint);
          } else {
            ref
                .read(chartTimeFilterControllerProvider.notifier)
                .setRange(range);
          }
        },
      ),
    );
  }

  String _timeRangeLabel(AppLocalizations l, ChartTimeRange range) {
    return switch (range) {
      ChartTimeRange.sixMonths => l.timeRange6m,
      ChartTimeRange.oneYear => l.timeRange1y,
      ChartTimeRange.twoYears => l.timeRange2y,
      ChartTimeRange.threeYears => l.timeRange3y,
      ChartTimeRange.fiveYears => l.timeRange5y,
      ChartTimeRange.tenYears => l.timeRange10y,
      ChartTimeRange.custom => l.timeRangeCustom,
    };
  }

  Future<void> _showCustomDatePicker(
    BuildContext context,
    WidgetRef ref,
    ChartTimeFilter currentFilter,
    DateTime? firstDataPoint,
  ) async {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final minDate = firstDataPoint ?? DateTime(now.year - 5, 1, 1);
    final maxDate = DateTime(now.year, now.month, 1);

    // Initialize with current values or defaults
    DateTime startDate =
        currentFilter.customStart ?? DateTime(now.year - 1, now.month, 1);
    DateTime endDate = currentFilter.customEnd ?? maxDate;

    final result = await showDialog<(DateTime, DateTime)>(
      context: context,
      builder: (context) => _CustomDateRangeDialog(
        initialStart: startDate,
        initialEnd: endDate,
        minDate: minDate,
        maxDate: maxDate,
        l: l,
      ),
    );

    if (result != null) {
      ref.read(chartTimeFilterControllerProvider.notifier).setCustomRange(
            result.$1,
            result.$2,
          );
    }
  }

  Widget _buildChartHeader(
      BuildContext context,
      AppLocalizations l,
      WidgetRef ref,
      List<ComparisonOverlayType> availableTypes,
      ComparisonOverlayType? overlayType,
      bool showCpi,
      bool isLoading) {
    if (availableTypes.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overlayType != null)
          IconButton(
            tooltip: l.comparisonSourceDetails,
            onPressed: () => _showOverlaySourceInfo(
              context,
              l,
              overlayType,
              ref.read(settingsControllerProvider).currency,
            ),
            icon: const Icon(Icons.info_outline, size: 20),
          ),
        if (overlayType != null)
          DropdownButtonHideUnderline(
            child: DropdownButton<ComparisonOverlayType>(
              value: overlayType,
              borderRadius: BorderRadius.circular(12),
              items: availableTypes
                  .map(
                    (type) => DropdownMenuItem<ComparisonOverlayType>(
                      value: type,
                      child: Text(_overlayLabel(l, type)),
                    ),
                  )
                  .toList(),
              onChanged: availableTypes.length < 2
                  ? null
                  : (value) {
                      if (value == null) return;
                      ref
                          .read(selectedComparisonOverlayTypeProvider.notifier)
                          .set(value);
                    },
            ),
          ),
        const SizedBox(width: 4),
        Switch.adaptive(
          value: showCpi,
          onChanged: isLoading
              ? null
              : (_) => ref.read(showCpiOverlayProvider.notifier).toggle(),
        ),
      ],
    );
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
        _legendDot(isLuxeMode ? AppColors.textSecondary : Colors.orange),
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
    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowOpacity = isDark ? 0.6 : 0.35;
    final chartHeight = responsiveChartHeight(context, type: ChartType.line);

    final barData = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: primaryColor,
        barWidth: isLuxeMode ? 3 : 4,
        isStrokeCapRound: true,
        shadow: isLuxeMode
            ? Shadow(color: primaryColor.withValues(alpha: 0.8), blurRadius: 8)
            : const Shadow(color: Colors.transparent),
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: isLuxeMode
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.3),
                    AppColors.bgVoid.withValues(alpha: 0.0),
                  ],
                )
              : null,
          color: isLuxeMode ? null : primaryColor.withValues(alpha: 0.2),
        ),
      ),
      if (showCpi && comparisonSpots.isNotEmpty)
        LineChartBarData(
          spots: comparisonSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: isLuxeMode ? AppColors.textSecondary : Colors.orange,
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

  Widget _buildTopInflators(BuildContext context, AppLocalizations l,
      dynamic items, AppSettings settings, bool isBitcoinMode) {
    if (items.isEmpty) {
      return StateMessageCard(
        icon: Icons.trending_up,
        animationAsset: StateIllustrations.emptyGeneral,
        animationHeight: 140,
        title: l.overviewTopInflators,
        message: l.overviewNoData,
      );
    }

    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

    final List<dynamic> inflators = isBitcoinMode
        ? (items as List<ItemInflationSats>)
            .where((i) => i.inflationPercent > 0)
            .take(5)
            .toList()
        : (items as List<ItemInflation>)
            .where((i) => i.inflationPercent > 0)
            .take(5)
            .toList();

    if (inflators.isEmpty) {
      return Text(l.overviewNoPriceIncreases);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inflators.length,
      itemBuilder: (context, index) {
        final item = inflators[index];
        final unitLabel =
            _unitPriceLabel(item, settings.currency, isBitcoinMode);

        final listTile = InkWell(
          onTap: () => context.push('/home/product/${item.product.id}'),
          child: ListTile(
            contentPadding: isLuxeMode
                ? const EdgeInsets.symmetric(horizontal: 16)
                : EdgeInsets.zero,
            title: Text(item.product.name,
                style: isLuxeMode
                    ? const TextStyle(fontWeight: FontWeight.w600)
                    : null),
            subtitle: Text(unitLabel),
            trailing: isLuxeMode
                ? TabularAmountText(
                    '+${item.inflationPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: AppColors.accentBtcMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  )
                : Text(
                    '+${item.inflationPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
          ),
        );

        if (isLuxeMode) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VaultCard(
              padding: EdgeInsets.zero,
              child: listTile,
            ),
          );
        }

        return listTile;
      },
    );
  }

  Widget _buildTopDeflators(BuildContext context, AppLocalizations l,
      dynamic items, AppSettings settings, bool isBitcoinMode) {
    if (items.isEmpty) {
      return StateMessageCard(
        icon: Icons.trending_down,
        animationAsset: StateIllustrations.emptyGeneral,
        animationHeight: 140,
        title: l.overviewTopDeflators,
        message: l.overviewNoData,
      );
    }

    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

    List<dynamic> deflators;
    if (isBitcoinMode) {
      final list = (items as List<ItemInflationSats>)
          .where((i) => i.inflationPercent < 0)
          .toList();
      list.sort((a, b) => a.inflationPercent.compareTo(b.inflationPercent));
      deflators = list;
    } else {
      final list = (items as List<ItemInflation>)
          .where((i) => i.inflationPercent < 0)
          .toList();
      list.sort((a, b) => a.inflationPercent.compareTo(b.inflationPercent));
      deflators = list;
    }

    final top = deflators.take(5).toList();
    if (top.isEmpty) {
      return Text(l.overviewNoPriceDecreases);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: top.length,
      itemBuilder: (context, index) {
        final item = top[index];
        final unitLabel =
            _unitPriceLabel(item, settings.currency, isBitcoinMode);

        final listTile = InkWell(
          onTap: () => context.push('/home/product/${item.product.id}'),
          child: ListTile(
            contentPadding: isLuxeMode
                ? const EdgeInsets.symmetric(horizontal: 16)
                : EdgeInsets.zero,
            title: Text(item.product.name,
                style: isLuxeMode
                    ? const TextStyle(fontWeight: FontWeight.w600)
                    : null),
            subtitle: Text(unitLabel),
            trailing: isLuxeMode
                ? TabularAmountText(
                    '${item.inflationPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: AppColors.accentFiatMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  )
                : Text(
                    '${item.inflationPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
          ),
        );

        if (isLuxeMode) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VaultCard(
              padding: EdgeInsets.zero,
              child: listTile,
            ),
          );
        }

        return listTile;
      },
    );
  }

  String _unitPriceLabel(dynamic item, String currency, bool isBitcoinMode) {
    if (isBitcoinMode) {
      final satsItem = item as ItemInflationSats;
      final baseFormatted = SatsConverter.formatSats(satsItem.baseSatsPrice);
      final currentFormatted =
          SatsConverter.formatSats(satsItem.currentSatsPrice);
      return '$baseFormatted → $currentFormatted';
    } else {
      final fiatItem = item as ItemInflation;
      final unit = fiatItem.baseUnit;
      String fmt(double pricePerBase) =>
          unit.formattedUnitPriceFromNormalized(pricePerBase, currency);
      return '${fmt(fiatItem.baseUnitPrice)} → ${fmt(fiatItem.currentUnitPrice)}';
    }
  }
}

/// Dialog for selecting a custom date range with year and month pickers.
class _CustomDateRangeDialog extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime minDate;
  final DateTime maxDate;
  final AppLocalizations l;

  const _CustomDateRangeDialog({
    required this.initialStart,
    required this.initialEnd,
    required this.minDate,
    required this.maxDate,
    required this.l,
  });

  @override
  State<_CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<_CustomDateRangeDialog> {
  late int startYear;
  late int startMonth;
  late int endYear;
  late int endMonth;

  @override
  void initState() {
    super.initState();
    startYear = widget.initialStart.year;
    startMonth = widget.initialStart.month;
    endYear = widget.initialEnd.year;
    endMonth = widget.initialEnd.month;
  }

  List<int> get _availableStartYears {
    return List.generate(
      widget.maxDate.year - widget.minDate.year + 1,
      (i) => widget.minDate.year + i,
    );
  }

  List<int> get _availableEndYears {
    return List.generate(
      widget.maxDate.year - startYear + 1,
      (i) => startYear + i,
    );
  }

  List<int> get _availableStartMonths {
    if (startYear == widget.minDate.year) {
      return List.generate(
        13 - widget.minDate.month,
        (i) => widget.minDate.month + i,
      );
    }
    return List.generate(12, (i) => i + 1);
  }

  List<int> get _availableEndMonths {
    if (endYear == startYear) {
      // End month must be >= start month
      return List.generate(13 - startMonth, (i) => startMonth + i);
    }
    if (endYear == widget.maxDate.year) {
      return List.generate(widget.maxDate.month, (i) => i + 1);
    }
    return List.generate(12, (i) => i + 1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l.timeRangeCustom),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.l.filterDateFrom}:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: startYear,
                  decoration: InputDecoration(labelText: widget.l.filterYear),
                  items: _availableStartYears
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        startYear = value;
                        // Adjust start month if needed
                        if (!_availableStartMonths.contains(startMonth)) {
                          startMonth = _availableStartMonths.first;
                        }
                        // Adjust end date if it's before start date
                        if (endYear < startYear ||
                            (endYear == startYear && endMonth < startMonth)) {
                          endYear = startYear;
                          endMonth = startMonth;
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: startMonth,
                  decoration: InputDecoration(labelText: widget.l.filterMonth),
                  items: _availableStartMonths
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                              DateFormat.MMM().format(DateTime(2024, m, 1)))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        startMonth = value;
                        // Adjust end date if it's before start date
                        if (endYear == startYear && endMonth < startMonth) {
                          endMonth = startMonth;
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${widget.l.filterDateTo}:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: endYear,
                  decoration: InputDecoration(labelText: widget.l.filterYear),
                  items: _availableEndYears
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        endYear = value;
                        // Adjust end month if needed
                        if (!_availableEndMonths.contains(endMonth)) {
                          endMonth = _availableEndMonths.first;
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: endMonth,
                  decoration: InputDecoration(labelText: widget.l.filterMonth),
                  items: _availableEndMonths
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                              DateFormat.MMM().format(DateTime(2024, m, 1)))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        endMonth = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final start = DateTime(startYear, startMonth, 1);
            final monthEnd =
                DateTime(endYear, endMonth + 1, 0, 23, 59, 59, 999);
            final now = DateTime.now();
            final end = monthEnd.isAfter(now) ? now : monthEnd;
            Navigator.of(context).pop((start, end));
          },
          child: Text(widget.l.apply),
        ),
      ],
    );
  }
}
