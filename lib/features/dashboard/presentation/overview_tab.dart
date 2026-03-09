import 'dart:math' show min, max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final overallInflation = ref.watch(basketInflationProvider);
    final history = ref.watch(basketIndexHistoryProvider);
    final topInflators = ref.watch(itemInflationListProvider);
    final settings = ref.watch(settingsControllerProvider);
    final showCpi = ref.watch(showCpiOverlayProvider);
    final overlayType = ref.watch(effectiveComparisonOverlayTypeProvider);
    final overlayAsync = ref.watch(comparisonOverlayDataProvider);
    final availableTypes = availableComparisonOverlayTypes(settings.currency);
    final hasOverlaySource = availableTypes.isNotEmpty;
    final overlayPoints =
        overlayAsync.valueOrNull ?? const <ComparisonDataPoint>[];
    final hasOverlayData = overlayPoints.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, l, overallInflation),
          const SizedBox(height: 24),
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
          _buildLineChart(context, l, history, showCpi, overlayPoints),
          if (showCpi && hasOverlaySource) ...[
            const SizedBox(height: 8),
            _buildOverlayStatus(context, l, overlayAsync, hasOverlayData),
          ],
          if (showCpi && hasOverlayData && overlayType != null) ...[
            const SizedBox(height: 8),
            _buildChartLegend(context, l, overlayType),
          ],
          const SizedBox(height: 24),
          Text(l.overviewTopInflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildTopInflators(context, l, topInflators, settings),
          const SizedBox(height: 24),
          Text(l.overviewTopDeflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildTopDeflators(context, l, topInflators, settings),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, AppLocalizations l, double inflation) {
    final color = inflation > 0
        ? Colors.red
        : (inflation < 0 ? Colors.green : Colors.grey);
    final icon = inflation > 0
        ? Icons.trending_up
        : (inflation < 0 ? Icons.trending_down : Icons.trending_flat);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.overviewTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '${inflation > 0 ? '+' : ''}${inflation.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

  Widget _buildChartHeader(
      BuildContext context,
      AppLocalizations l,
      WidgetRef ref,
      List<ComparisonOverlayType> availableTypes,
      ComparisonOverlayType? overlayType,
      bool showCpi,
      bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: Text(l.overviewBasketIndex,
              style: Theme.of(context).textTheme.titleLarge),
        ),
        if (availableTypes.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (overlayType != null)
                IconButton(
                  tooltip: 'Comparison data source details',
                  onPressed: () => _showOverlaySourceInfo(
                    context,
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
                                .read(selectedComparisonOverlayTypeProvider
                                    .notifier)
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
                overlayType == ComparisonOverlayType.cpi
                    ? 'CPI Source'
                    : 'Money Supply Source',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                _overlaySourceDescription(overlayType, currency),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  String _overlaySourceDescription(
    ComparisonOverlayType overlayType,
    String currency,
  ) {
    return switch (overlayType) {
      ComparisonOverlayType.cpi => switch (currency) {
          'CHF' =>
            'Consumer-price data comes from Eurostat monthly HICP observations for Switzerland. The series is rebased to the same 100-index baseline as your basket history.',
          'EUR' =>
            'Consumer-price data comes from Eurostat monthly HICP observations for the EU27 aggregate. The series is rebased to the same 100-index baseline as your basket history.',
          _ =>
            'Consumer-price overlays are shown only when a supported CPI source is available for the selected currency.',
        },
      ComparisonOverlayType.moneySupply => switch (currency) {
          'CHF' =>
            'Money-supply data uses Swiss National Bank M2 observations, filtered to the same visible history window and rebased to match your basket index.',
          'EUR' =>
            'Money-supply data uses European Central Bank M2 observations, filtered to the same visible history window and rebased to match your basket index.',
          'USD' =>
            'Money-supply data uses FRED M2 observations for the United States, filtered to the same visible history window and rebased to match your basket index.',
          'GBP' =>
            'Money-supply data uses Bank of England M2 observations, filtered to the same visible history window and rebased to match your basket index.',
          _ =>
            'Money-supply overlays are shown only when a supported source is available for the selected currency.',
        },
    };
  }

  Widget _buildChartLegend(BuildContext context, AppLocalizations l,
      ComparisonOverlayType overlayType) {
    return Row(
      children: [
        _legendDot(Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(l.yourInflation, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 16),
        _legendDot(Colors.orange),
        const SizedBox(width: 4),
        Text(_overlayLabel(l, overlayType),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _overlayLabel(AppLocalizations l, ComparisonOverlayType overlayType) {
    return switch (overlayType) {
      ComparisonOverlayType.cpi => l.nationalCpi,
      ComparisonOverlayType.moneySupply => l.moneySupplyM2,
    };
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    AppLocalizations l,
    List<MonthlyIndex> history,
    bool showCpi,
    List<ComparisonDataPoint> overlayPoints,
  ) {
    final validHistory = history.where((h) => h.index.isFinite).toList();
    if (validHistory.isEmpty || validHistory.length == 1) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(l.overviewNoData)),
      );
    }

    final spots = validHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.index);
    }).toList();

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
          // Find the closest basket month index for this CPI month
          int bestIdx = 0;
          int bestDiff = 999999;
          for (int i = 0; i < validHistory.length; i++) {
            final diff = (validHistory[i].month.millisecondsSinceEpoch -
                    cp.month.millisecondsSinceEpoch)
                .abs();
            if (diff < bestDiff) {
              bestDiff = diff;
              bestIdx = i;
            }
          }
          comparisonSpots.add(FlSpot(bestIdx.toDouble(), cp.index));
        }
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

    final barData = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: Theme.of(context).colorScheme.primary,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      if (showCpi && comparisonSpots.isNotEmpty)
        LineChartBarData(
          spots: comparisonSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
    ];

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < validHistory.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                          DateFormat.MMM().format(validHistory[index].month)),
                    );
                  }
                  return const Text('');
                },
                interval: 1,
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
        ),
      ),
    );
  }

  Widget _buildTopInflators(BuildContext context, AppLocalizations l,
      List<ItemInflation> items, AppSettings settings) {
    if (items.isEmpty) {
      return Text(l.overviewNoData);
    }

    final inflators =
        items.where((i) => i.inflationPercent > 0).take(5).toList();

    if (inflators.isEmpty) {
      return const Text('No price increases detected yet!');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inflators.length,
      itemBuilder: (context, index) {
        final item = inflators[index];
        final unitLabel = _unitPriceLabel(item, settings.currency);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.product.name),
          subtitle: Text(unitLabel),
          trailing: Text(
            '+${item.inflationPercent.toStringAsFixed(1)}%',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  Widget _buildTopDeflators(BuildContext context, AppLocalizations l,
      List<ItemInflation> items, AppSettings settings) {
    if (items.isEmpty) {
      return Text(l.overviewNoData);
    }

    final deflators = items.where((i) => i.inflationPercent < 0).toList()
      ..sort((a, b) => a.inflationPercent.compareTo(b.inflationPercent));

    final top = deflators.take(5).toList();
    if (top.isEmpty) {
      return const Text('No price decreases detected yet.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: top.length,
      itemBuilder: (context, index) {
        final item = top[index];
        final unitLabel = _unitPriceLabel(item, settings.currency);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.product.name),
          subtitle: Text(unitLabel),
          trailing: Text(
            '${item.inflationPercent.toStringAsFixed(1)}%',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  /// Builds a subtitle string showing base → current per-unit price.
  String _unitPriceLabel(ItemInflation item, String currency) {
    final unit = item.baseUnit;
    String fmt(double pricePerBase) =>
        unit.formattedUnitPriceFromNormalized(pricePerBase, currency);
    return '${fmt(item.baseUnitPrice)} → ${fmt(item.currentUnitPrice)}';
  }
}
