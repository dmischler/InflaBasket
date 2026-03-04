import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesInflation = ref.watch(categoryInflationListProvider);
    final settings = ref.watch(settingsControllerProvider);

    if (categoriesInflation.isEmpty) {
      return const Center(child: Text('Not enough data to show categories.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inflation by Category',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _buildBarChart(context, categoriesInflation),
          const SizedBox(height: 24),
          Text('Category Details',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildCategoryList(context, categoriesInflation, settings),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<CategoryInflation> data) {
    final maxInflation = data.fold<double>(
        0, (max, e) => e.inflationPercent > max ? e.inflationPercent : max);
    final minInflation = data.fold<double>(
        0, (min, e) => e.inflationPercent < min ? e.inflationPercent : min);

    final chartData = data.take(7).toList();

    final clampedMax = maxInflation.clamp(-100, 1000);
    final clampedMin = minInflation.clamp(-100, 1000);

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: clampedMax > 0 ? clampedMax * 1.2 : 10,
          minY: clampedMin < 0 ? clampedMin * 1.2 : 0,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    // Truncate long names
                    String name = chartData[index].category.name;
                    if (name.length > 8) name = '${name.substring(0, 7)}...';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(name, style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%',
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: chartData.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;
            final isPositive = item.inflationPercent >= 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.inflationPercent,
                  color:
                      isPositive ? Colors.red.shade400 : Colors.green.shade400,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<CategoryInflation> data,
      AppSettings settings) {
    final format = NumberFormat.simpleCurrency(name: settings.currency);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isPositive = item.inflationPercent >= 0;

        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(item.category.name.isNotEmpty
                  ? item.category.name[0].toUpperCase()
                  : '?'),
            ),
            title: Text(item.category.name),
            subtitle:
                Text('Weight: ${format.format(item.totalSpend)} total spend'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.inflationPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
