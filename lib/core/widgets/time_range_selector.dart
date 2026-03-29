import 'package:flutter/material.dart';
import 'package:inflabasket/core/widgets/time_range_filter_sheet.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class TimeRangeSelector extends StatelessWidget {
  final ChartTimeFilter timeFilter;
  final ChartTimeRange selectedRange;
  final List<ChartTimeRange> availableOptions;
  final DateTime? firstDataPoint;
  final ValueChanged<ChartTimeRange> onRangeChanged;
  final void Function(DateTime start, DateTime end) onCustomRangeApplied;

  const TimeRangeSelector({
    super.key,
    required this.timeFilter,
    required this.selectedRange,
    required this.availableOptions,
    required this.firstDataPoint,
    required this.onRangeChanged,
    required this.onCustomRangeApplied,
  });

  String _timeRangeLabel(AppLocalizations l, ChartTimeRange range) {
    return switch (range) {
      ChartTimeRange.sixMonths => l.timeRange6m,
      ChartTimeRange.oneYear => l.timeRange1y,
      ChartTimeRange.twoYears => l.timeRange2y,
      ChartTimeRange.threeYears => l.timeRange3y,
      ChartTimeRange.fiveYears => l.timeRange5y,
      ChartTimeRange.tenYears => l.timeRange10y,
      ChartTimeRange.allTime => l.timeRangeAll,
      ChartTimeRange.custom => l.timeRangeCustom,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final displayRange = availableOptions.contains(selectedRange)
        ? selectedRange
        : availableOptions.first;
    return GestureDetector(
      onTap: () => TimeRangeFilterSheet.show(
        context: context,
        selectedRange: selectedRange,
        availableOptions: availableOptions,
        firstDataPoint: firstDataPoint,
        onRangeSelected: onRangeChanged,
        onCustomRangeApplied: onCustomRangeApplied,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_timeRangeLabel(l, displayRange)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
