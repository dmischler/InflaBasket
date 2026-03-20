import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/mixins/chart_touch_state.dart';
import 'package:inflabasket/core/utils/chart_sizing.dart';
import 'package:inflabasket/core/theme/chart_animations.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/shimmer/chart_skeleton.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/widgets/time_range_selector.dart';
import 'package:inflabasket/core/utils/chart_date_range_helper.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/widgets/tabular_amount_text.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab>
    with ChartTouchState {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(entriesWithDetailsProvider);
    final categoriesInflation = ref.watch(categoryInflationListProvider);
    final settings = ref.watch(settingsControllerProvider);
    final timeFilter = ref.watch(chartTimeFilterControllerProvider);
    final allHistory = ref.watch(basketIndexHistoryProvider);
    final entries = entriesAsync.valueOrNull ?? const [];
    final firstDataPoint = entries.isNotEmpty
        ? entries
            .map<DateTime>((entry) => entry.entry.purchaseDate)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : (allHistory.isNotEmpty ? allHistory.first.month : null);
    final availableTimeRangeOptions = availableTimeRanges(entries);
    final selectedRange =
        resolveTimeRangeSelection(timeFilter, availableTimeRangeOptions);

    if (entriesAsync.isLoading && entriesAsync.valueOrNull == null) {
      return const AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: ChartSkeleton.categories(key: ValueKey('categories-loading')),
      );
    }

    if (entriesAsync.hasError && entriesAsync.valueOrNull == null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: StateMessageCard(
          key: const ValueKey('categories-error'),
          icon: Icons.error_outline,
          animationAsset: StateIllustrations.error,
          loop: false,
          title: l10n.errorGeneric,
          message: entriesAsync.error.toString(),
        ),
      );
    }

    if (categoriesInflation.isEmpty) {
      return StateMessageCard(
        icon: Icons.category_outlined,
        animationAsset: StateIllustrations.emptyGeneral,
        title: l10n.categoriesTitle,
        message: l10n.categoryNoCategoryData,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: SingleChildScrollView(
        key: const ValueKey('categories-content'),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TimeRangeSelector(
              timeFilter: timeFilter,
              selectedRange: selectedRange,
              availableOptions: availableTimeRangeOptions,
              firstDataPoint: firstDataPoint,
              onRangeChanged: (range) => ref
                  .read(chartTimeFilterControllerProvider.notifier)
                  .setRange(range),
              onCustomRangeRequested: (range) =>
                  ChartDateRangeHelper.showCustomDatePicker(
                context: context,
                ref: ref,
                currentFilter: timeFilter,
                firstDataPoint: firstDataPoint,
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.categoryInflationTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            _buildBarChart(context, l10n, categoriesInflation),
            const SizedBox(height: 24),
            Text(l10n.categoryDetailsTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildCategoryList(context, l10n, categoriesInflation, settings),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, AppLocalizations l10n,
      List<CategoryInflation> data) {
    // Filter out any non-finite values before any computation to prevent
    // TransformLayer invalid matrix errors in fl_chart.
    final validData = data.where((e) => e.inflationPercent.isFinite).toList();

    if (validData.isEmpty) {
      return SizedBox(
        height: responsiveChartHeight(context, type: ChartType.bar),
        child: Center(
          child: StateMessageCard(
            icon: Icons.bar_chart_outlined,
            title: l10n.categoryNoChartData,
            message: '',
            animationAsset: StateIllustrations.emptyGeneral,
          ),
        ),
      );
    }

    final maxInflation = validData.fold<double>(
        0, (max, e) => e.inflationPercent > max ? e.inflationPercent : max);
    final minInflation = validData.fold<double>(
        0, (min, e) => e.inflationPercent < min ? e.inflationPercent : min);

    final chartData = validData.take(7).toList();

    // Clamp axis bounds and ensure maxY > minY so fl_chart never gets an
    // invalid (zero-height or inverted) axis range.
    final clampedMax = maxInflation.clamp(-100.0, 1000.0);
    final clampedMin = minInflation.clamp(-100.0, 1000.0);
    final maxY = (clampedMax > 0 ? clampedMax * 1.2 : 10.0);
    final minY = (clampedMin < 0 ? clampedMin * 1.2 : 0.0);
    // Guarantee a non-zero range
    final safeMaxY = (maxY <= minY) ? minY + 10.0 : maxY;

    final isLuxeMode = Theme.of(context).brightness == Brightness.dark;
    final shouldAnimate = animationsEnabled(
      context,
      pointCount: chartData.length,
    );
    final baseWidth = isLuxeMode ? 16.0 : 20.0;

    return SizedBox(
      height: responsiveChartHeight(context, type: ChartType.bar),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMaxY,
          minY: minY,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    String name = CategoryLocalization.displayNameForContext(
                      context,
                      chartData[index].category.name,
                    );
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
          gridData: isLuxeMode
              ? const FlGridData(show: false)
              : FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = chartData[groupIndex];
                final isPositive = item.inflationPercent >= 0;
                final amountColor = isLuxeMode
                    ? (isPositive
                        ? AppColors.accentBtcMain
                        : AppColors.accentFiatMain)
                    : (isPositive
                        ? Colors.red.shade400
                        : Colors.green.shade400);
                final label = CategoryLocalization.displayNameForContext(
                  context,
                  item.category.name,
                );
                return BarTooltipItem(
                  '$label\n${item.inflationPercent.toStringAsFixed(1)}%',
                  TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent || response?.spot == null) return;
              final touchedIndex = response!.spot!.touchedBarGroupIndex;
              final handled =
                  handleBarTouch(touchedIndex, () => setState(() {}));
              if (!handled) return;
              HapticFeedback.lightImpact();
            },
          ),
          barGroups: chartData.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;
            final isTouched = index == touchedBarIndex;
            final isPositive = item.inflationPercent >= 0;
            // Clamp individual bar values as a secondary defence against
            // out-of-range values slipping through to fl_chart's painter.
            final baseToY =
                item.inflationPercent.clamp(-100.0, 1000.0).toDouble();

            final color = isLuxeMode
                ? (isPositive
                    ? AppColors.accentBtcMain
                    : AppColors.accentFiatMain)
                : (isPositive ? Colors.red.shade400 : Colors.green.shade400);

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: isTouched ? baseToY * 1.06 : baseToY,
                  color: isTouched ? null : color,
                  gradient: isTouched
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.75),
                            color,
                          ],
                        )
                      : null,
                  width: isTouched
                      ? (baseWidth * 1.12).roundToDouble()
                      : baseWidth,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: isLuxeMode
                      ? BackgroundBarChartRodData(
                          show: true,
                          toY: safeMaxY,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        )
                      : null,
                )
              ],
            );
          }).toList(),
        ),
        duration: shouldAnimate
            ? ChartAnimations.entranceDurationFor(chartData.length)
            : Duration.zero,
        curve: ChartAnimations.entranceCurve,
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, AppLocalizations l10n,
      List<CategoryInflation> data, AppSettings settings) {
    final format = NumberFormat.simpleCurrency(name: settings.currency);
    final isLuxeMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isPositive = item.inflationPercent >= 0;
        final categoryName = CategoryLocalization.displayNameForContext(
          context,
          item.category.name,
        );

        final listTile = ListTile(
          leading: CircleAvatar(
            backgroundColor: isLuxeMode
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor:
                isLuxeMode ? Theme.of(context).colorScheme.onSurface : null,
            child: Text(
              categoryName.isNotEmpty ? categoryName[0].toUpperCase() : '?',
            ),
          ),
          title: Text(categoryName),
          subtitle:
              Text(l10n.categoryTotalSpend(format.format(item.totalSpend))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isLuxeMode
                    ? (isPositive
                        ? AppColors.accentBtcMain
                        : AppColors.accentFiatMain)
                    : (isPositive ? Colors.red : Colors.green),
                size: 16,
              ),
              const SizedBox(width: 4),
              if (isLuxeMode)
                TabularAmountText(
                  '${item.inflationPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isPositive
                        ? AppColors.accentBtcMain
                        : AppColors.accentFiatMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              else
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

        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 8),
          child: listTile,
        );
      },
    );
  }
}
