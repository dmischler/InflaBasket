import 'package:flutter/material.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class TimeRangeSelector extends StatelessWidget {
  final ChartTimeFilter timeFilter;
  final ChartTimeRange selectedRange;
  final List<ChartTimeRange> availableOptions;
  final DateTime? firstDataPoint;
  final ValueChanged<ChartTimeRange> onRangeChanged;
  final void Function(ChartTimeRange) onCustomRangeRequested;

  const TimeRangeSelector({
    super.key,
    required this.timeFilter,
    required this.selectedRange,
    required this.availableOptions,
    required this.firstDataPoint,
    required this.onRangeChanged,
    required this.onCustomRangeRequested,
  });

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
            onCustomRangeRequested(range);
          } else {
            onRangeChanged(range);
          }
        },
      ),
    );
  }
}
