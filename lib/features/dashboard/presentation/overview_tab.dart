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
    final cpiAsync = ref.watch(cpiDataProvider);
    final hasCpiSource =
        cpiSourceForCurrency(settings.currency) != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, l, overallInflation),
          const SizedBox(height: 24),
          _buildChartHeader(context, l, ref, hasCpiSource, showCpi),
          const SizedBox(height: 8),
          _buildLineChart(context, l, ref, history, showCpi, cpiAsync),
          if (showCpi && hasCpiSource) ...[
            const SizedBox(height: 8),
            _buildChartLegend(context, l),
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
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 32, color: color),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader(BuildContext context, AppLocalizations l,
      WidgetRef ref, bool hasCpiSource, bool showCpi) {
    return Row(
      children: [
        Expanded(
          child: Text(l.overviewBasketIndex,
              style: Theme.of(context).textTheme.titleLarge),
        ),
        if (hasCpiSource)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.showNationalAverage,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: showCpi,
                onChanged: (_) =>
                    ref.read(showCpiOverlayProvider.notifier).toggle(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChartLegend(BuildContext context, AppLocalizations l) {
    return Row(
      children: [
        _legendDot(Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(l.yourInflation,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 16),
        _legendDot(Colors.orange),
        const SizedBox(width: 4),
        Text(l.nationalCpi,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
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
    WidgetRef ref,
    List<MonthlyIndex> history,
    bool showCpi,
    AsyncValue<List<CpiDataPoint>> cpiAsync,
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
    List<FlSpot> cpiSpots = [];
    if (showCpi) {
      final cpiPoints = cpiAsync.valueOrNull ?? [];
      if (cpiPoints.isNotEmpty && validHistory.isNotEmpty) {
        // Align CPI months to our basket history months
        final basketStart = validHistory.first.month;
        final basketEnd = validHistory.last.month;
        final relevantCpi = cpiPoints.where((p) =>
            !p.month.isBefore(basketStart) && !p.month.isAfter(basketEnd));

        for (final cp in relevantCpi) {
          // Find the closest basket month index for this CPI month
          int bestIdx = 0;
          int bestDiff = 999999;
          for (int i = 0; i < validHistory.length; i++) {
            final diff =
                (validHistory[i].month.millisecondsSinceEpoch -
                        cp.month.millisecondsSinceEpoch)
                    .abs();
            if (diff < bestDiff) {
              bestDiff = diff;
              bestIdx = i;
            }
          }
          cpiSpots.add(FlSpot(bestIdx.toDouble(), cp.index));
        }
      }
    }

    // Compute explicit Y bounds
    final allYValues = [
      ...spots.map((s) => s.y),
      if (cpiSpots.isNotEmpty) ...cpiSpots.map((s) => s.y),
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      if (showCpi && cpiSpots.isNotEmpty)
        LineChartBarData(
          spots: cpiSpots,
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
