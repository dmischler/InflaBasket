import 'dart:math' show min, max;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/theme/chart_animations.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/utils/chart_sizing.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';

class ChartTickConfig {
  const ChartTickConfig({
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

class _TouchDebouncer {
  _TouchDebouncer();

  DateTime? _lastTouchTime;

  bool shouldHandleTouch() {
    final now = DateTime.now();
    if (_lastTouchTime != null &&
        now.difference(_lastTouchTime!) < ChartAnimations.touchDebounce) {
      return false;
    }

    _lastTouchTime = now;
    return true;
  }

  bool handleTouchDebounce() => shouldHandleTouch();
}

ChartTickConfig buildTickConfig(
  ChartTimeRange range,
  List<MonthlyIndex> validHistory,
  double chartWidth,
) {
  if (validHistory.length < 2) {
    return const ChartTickConfig(
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
    monthsBetween(
            DateTime(start.year, start.month), DateTime(end.year, end.month)) +
        1,
  );
  final estimatedLabelWidth = switch (range) {
    ChartTimeRange.sixMonths || ChartTimeRange.oneYear => 44.0,
    ChartTimeRange.twoYears || ChartTimeRange.threeYears => 64.0,
    ChartTimeRange.fiveYears ||
    ChartTimeRange.tenYears ||
    ChartTimeRange.allTime =>
      42.0,
    ChartTimeRange.custom => totalMonths <= 18 ? 44.0 : 64.0,
  };
  final targetLabels =
      max(2, min(5, (chartWidth / estimatedLabelWidth).floor()));
  final rawStepMonths = max(1, (totalMonths / targetLabels).ceil());
  final stepMonths = niceMonthStep(rawStepMonths);
  final format = tickDateFormat(totalMonths, stepMonths);

  final totalRangeMs = end.difference(start).inMilliseconds.toDouble();
  final minInterval = (totalRangeMs / targetLabels * 0.8).clamp(
    stepMonths * 20 * Duration.millisecondsPerDay.toDouble(),
    double.infinity,
  );

  return ChartTickConfig(
    format: format,
    interval: stepMonths * 30.4375 * Duration.millisecondsPerDay,
    minInterval: minInterval,
    reservedSize: format == 'yyyy' ? 30 : 38,
  );
}

int niceMonthStep(int rawStepMonths) {
  const steps = <int>[1, 2, 3, 4, 6, 12, 18, 24, 36, 60];
  for (final step in steps) {
    if (rawStepMonths <= step) return step;
  }
  return steps.last;
}

String tickDateFormat(int totalMonths, int stepMonths) {
  if (totalMonths <= 18 && stepMonths <= 3) {
    return 'MMM';
  }
  if (stepMonths >= 12 || totalMonths > 72) {
    return 'yyyy';
  }
  return "MMM ''yy";
}

List<MonthlyIndex> aggregateByPeriod(
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
      case ChartTimeRange.allTime:
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

class InflationLineChart extends StatefulWidget {
  const InflationLineChart({
    super.key,
    required this.history,
    required this.showCpi,
    required this.overlayPoints,
    required this.timeRange,
  });

  final List<MonthlyIndex> history;
  final bool showCpi;
  final List<ComparisonDataPoint> overlayPoints;
  final ChartTimeRange timeRange;

  @override
  State<InflationLineChart> createState() => _InflationLineChartState();
}

class _InflationLineChartState extends State<InflationLineChart> {
  final _TouchDebouncer _touchDebouncer = _TouchDebouncer();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final validHistory = widget.history.where((h) => h.index.isFinite).toList();
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

    final aggregatedHistory = aggregateByPeriod(validHistory, widget.timeRange);
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
    if (widget.showCpi && widget.overlayPoints.isNotEmpty) {
      DateTime periodStart(DateTime date) {
        switch (widget.timeRange) {
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
          case ChartTimeRange.allTime:
            return DateTime(date.year, 1, 1);
        }
      }

      final basketStart = aggregatedHistory.first.month;
      final basketEnd = aggregatedHistory.last.month;
      final relevantCpi = widget.overlayPoints.where(
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

      if (comparisonSpots.isNotEmpty) {
        final offset = comparisonSpots.first.y;
        comparisonSpots =
            comparisonSpots.map((s) => FlSpot(s.x, s.y - offset)).toList();
      }
    }

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
      if (widget.showCpi && comparisonSpots.isNotEmpty)
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
      key: ValueKey('linechart-container-${widget.timeRange.name}'),
      height: chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tickConfig = buildTickConfig(
              widget.timeRange, aggregatedHistory, constraints.maxWidth);
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
                  if (!_touchDebouncer.handleTouchDebounce()) return;
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
