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
    final availableTimeRangeOptions = availableTimeRanges(
        entries.map<DateTime>((entry) => entry.entry.purchaseDate));
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
            _buildTimeRangeSelector(
              context,
              l10n,
              ref,
              timeFilter,
              selectedRange,
              availableTimeRangeOptions,
              firstDataPoint,
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
        child: Center(child: Text(l10n.categoryNoChartData)),
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

    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;
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
                          color: AppColors.bgElevated.withValues(alpha: 0.3),
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
    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

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
                ? AppColors.bgElevated
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: isLuxeMode ? AppColors.textPrimary : null,
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
}

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
          13 - widget.minDate.month, (i) => widget.minDate.month + i);
    }
    return List.generate(12, (i) => i + 1);
  }

  List<int> get _availableEndMonths {
    if (endYear == startYear) {
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
                        if (!_availableStartMonths.contains(startMonth)) {
                          startMonth = _availableStartMonths.first;
                        }
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
