import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallInflation = ref.watch(basketInflationProvider);
    final history = ref.watch(basketIndexHistoryProvider);
    final topInflators = ref.watch(itemInflationListProvider);
    final settings = ref.watch(settingsControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, overallInflation),
          const SizedBox(height: 24),
          Text('Basket Index History',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildLineChart(context, history),
          const SizedBox(height: 24),
          Text('Top Inflators', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildTopInflators(context, topInflators, settings),
          const SizedBox(height: 24),
          Text('Top Deflators', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildTopDeflators(context, topInflators, settings),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double inflation) {
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
                Text('Personal Inflation',
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

  Widget _buildLineChart(BuildContext context, List<MonthlyIndex> history) {
    final validHistory = history.where((h) => h.index.isFinite).toList();
    if (validHistory.isEmpty || validHistory.length == 1) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Not enough data to chart.')),
      );
    }

    final spots = validHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.index);
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < history.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child:
                          Text(DateFormat.MMM().format(history[index].month)),
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
          lineBarsData: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopInflators(
      BuildContext context, List<ItemInflation> items, AppSettings settings) {
    if (items.isEmpty) {
      return const Text(
          'Add multiple entries of the same product to track inflation.');
    }

    // Only show items with > 0% inflation, up to top 5
    final inflators =
        items.where((i) => i.inflationPercent > 0).take(5).toList();

    if (inflators.isEmpty) {
      return const Text('No price increases detected yet! 🎉');
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

  Widget _buildTopDeflators(
      BuildContext context, List<ItemInflation> items, AppSettings settings) {
    if (items.isEmpty) {
      return const Text(
          'Add multiple entries of the same product to track inflation.');
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
