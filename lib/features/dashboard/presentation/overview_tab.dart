import 'dart:math' show min, max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/core/widgets/tabular_amount_text.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final isBitcoinMode = settings.isBitcoinMode;

    final overallInflation = isBitcoinMode
        ? ref.watch(basketInflationSatsProvider)
        : ref.watch(basketInflationProvider);

    final history = isBitcoinMode
        ? ref.watch(filteredDynamicIndexSatsProvider).when(
              data: (data) => data,
              loading: () => <MonthlyIndex>[],
              error: (_, __) => <MonthlyIndex>[],
            )
        : ref.watch(filteredDynamicIndexProvider);
    final allHistory = isBitcoinMode
        ? ref.watch(dynamicLaspeyresIndexSatsProvider).when(
              data: (data) => data,
              loading: () => <MonthlyIndex>[],
              error: (_, __) => <MonthlyIndex>[],
            )
        : ref.watch(dynamicLaspeyresIndexProvider);
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
    final firstDataPoint =
        allHistory.isNotEmpty ? allHistory.first.month : null;
    final availableTimeRangeOptions = availableTimeRanges(firstDataPoint);

    final topInflators = isBitcoinMode
        ? ref.watch(itemInflationListSatsProvider).when(
              data: (data) => data,
              loading: () => <ItemInflationSats>[],
              error: (_, __) => <ItemInflationSats>[],
            )
        : ref.watch(itemInflationListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, l, overallInflation, isBitcoinMode),
          const SizedBox(height: 24),
          _buildTimeRangeSelector(
            context,
            l,
            ref,
            timeFilter,
            availableTimeRangeOptions,
            firstDataPoint,
          ),
          const SizedBox(height: 16),
          _buildChartHeader(
            context,
            l,
            ref,
            availableTypes,
            overlayType,
            showCpi,
            overlayAsync.isLoading,
          ),
          const SizedBox(height: 8),
          _buildLineChart(
              context, l, history, showCpi, overlayPoints, timeFilter.range),
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
          _buildTopInflators(context, l, topInflators, settings, isBitcoinMode),
          const SizedBox(height: 24),
          Text(l.overviewTopDeflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildTopDeflators(context, l, topInflators, settings, isBitcoinMode),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AppLocalizations l,
      double inflation, bool isBitcoinMode) {
    final color = inflation > 0
        ? Colors.red
        : (inflation < 0 ? Colors.green : Colors.grey);
    final icon = inflation > 0
        ? Icons.trending_up
        : (inflation < 0 ? Icons.trending_down : Icons.trending_flat);

    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

    final title = isBitcoinMode ? 'Sats Inflation' : l.overviewTitle;

    return isLuxeMode
        ? VaultCard(
            isActive: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TabularAmountText(
                      '${inflation > 0 ? '+' : ''}${inflation.toStringAsFixed(1)}%',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${inflation > 0 ? '+' : ''}${inflation.toStringAsFixed(1)}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
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
    List<ChartTimeRange> availableOptions,
    DateTime? firstDataPoint,
  ) {
    final segments = <ButtonSegment<ChartTimeRange>>[];
    for (final option in availableOptions) {
      if (option == ChartTimeRange.custom) continue; // Handle custom separately
      segments.add(ButtonSegment(
        value: option,
        label: Text(_timeRangeLabel(l, option)),
      ));
    }
    // Always add custom option
    segments.add(ButtonSegment(
      value: ChartTimeRange.custom,
      label: const Text('…'),
      enabled: true,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.timeRangeLabel, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SegmentedButton<ChartTimeRange>(
          segments: segments,
          selected: {timeFilter.range},
          onSelectionChanged: (selected) {
            final range = selected.first;
            if (range == ChartTimeRange.custom) {
              _showCustomDatePicker(context, ref, timeFilter, firstDataPoint);
            } else {
              ref
                  .read(chartTimeFilterControllerProvider.notifier)
                  .setRange(range);
            }
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }

  String _timeRangeLabel(AppLocalizations l, ChartTimeRange range) {
    return switch (range) {
      ChartTimeRange.ytd => l.timeRangeYtd,
      ChartTimeRange.oneYear => l.timeRange1y,
      ChartTimeRange.twoYears => l.timeRange2y,
      ChartTimeRange.fiveYears => l.timeRange5y,
      ChartTimeRange.allTime => l.timeRangeAll,
      ChartTimeRange.custom => '…',
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
        Text(l.showComparisonOverlay,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 8),
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

  String _getDateFormat(ChartTimeRange range, List<MonthlyIndex> validHistory) {
    if (range == ChartTimeRange.custom && validHistory.isNotEmpty) {
      final start = validHistory.first.month;
      final end = validHistory.last.month;
      final months = (end.year - start.year) * 12 + end.month - start.month;
      range = months <= 6
          ? ChartTimeRange.ytd
          : months <= 24
              ? ChartTimeRange.twoYears
              : ChartTimeRange.fiveYears;
    }

    switch (range) {
      case ChartTimeRange.ytd:
        return 'MMM d';
      case ChartTimeRange.oneYear:
        return 'MMM d';
      case ChartTimeRange.twoYears:
        return "MMM ''yy";
      case ChartTimeRange.fiveYears:
      case ChartTimeRange.allTime:
        return 'yyyy';
      case ChartTimeRange.custom:
        return 'MMM d';
    }
  }

  double _getTickInterval(ChartTimeRange range, int dataLength) {
    switch (range) {
      case ChartTimeRange.ytd:
      case ChartTimeRange.oneYear:
      case ChartTimeRange.custom:
        return const Duration(days: 30).inMilliseconds.toDouble();
      case ChartTimeRange.twoYears:
        return const Duration(days: 90).inMilliseconds.toDouble();
      case ChartTimeRange.fiveYears:
      case ChartTimeRange.allTime:
        return const Duration(days: 365).inMilliseconds.toDouble();
    }
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
        height: 200,
        child: Center(child: Text(l.overviewNoData)),
      );
    }

    final baseSpots = validHistory
        .map((e) => FlSpot(
              e.month.millisecondsSinceEpoch.toDouble(),
              e.index - 100,
            ))
        .toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < baseSpots.length; i++) {
      spots.add(baseSpots[i]);
      if (i < baseSpots.length - 1) {
        spots.add(FlSpot(baseSpots[i + 1].x, baseSpots[i].y));
      }
    }

    // Build CPI spots aligned to the same x-axis if overlay is active
    List<FlSpot> comparisonSpots = [];
    if (showCpi) {
      if (overlayPoints.isNotEmpty && validHistory.isNotEmpty) {
        // Align CPI months to our basket history months
        final basketStart = validHistory.first.month;
        final basketEnd = validHistory.last.month;
        final relevantCpi = overlayPoints.where((p) =>
            !p.month.isBefore(basketStart) && !p.month.isAfter(basketEnd));

        for (final cp in relevantCpi) {
          comparisonSpots.add(
            FlSpot(cp.month.millisecondsSinceEpoch.toDouble(), cp.index - 100),
          );
        }
        comparisonSpots.sort((a, b) => a.x.compareTo(b.x));
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

    final barData = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: false,
        color: primaryColor,
        barWidth: isLuxeMode ? 3 : 4,
        isStrokeCapRound: true,
        shadow: isLuxeMode
            ? Shadow(color: primaryColor.withValues(alpha: 0.8), blurRadius: 8)
            : const Shadow(color: Colors.transparent),
        dotData: const FlDotData(show: true),
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
          isCurved: false,
          color: isLuxeMode ? AppColors.textSecondary : Colors.orange,
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
    ];

    return SizedBox(
      height: 280,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final format = _getDateFormat(timeRange, validHistory);
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat(format).format(date)),
                  );
                },
                interval: _getTickInterval(timeRange, validHistory.length),
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
            touchTooltipData: LineTouchTooltipData(
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
                  final dateStr = DateFormat('MMM yyyy').format(nearest.month);
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
      ),
    );
  }

  Widget _buildTopInflators(BuildContext context, AppLocalizations l,
      dynamic items, AppSettings settings, bool isBitcoinMode) {
    if (items.isEmpty) {
      return Text(l.overviewNoData);
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

        final listTile = ListTile(
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
      return Text(l.overviewNoData);
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

        final listTile = ListTile(
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
                  value: startYear,
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
                  value: startMonth,
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
                  value: endYear,
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
                  value: endMonth,
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
            final end = DateTime(endYear, endMonth, 1);
            Navigator.of(context).pop((start, end));
          },
          child: Text(widget.l.apply),
        ),
      ],
    );
  }
}
