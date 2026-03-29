import 'package:flutter/material.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/widgets/custom_date_range_dialog.dart';

class TimeRangeFilterSheet extends StatelessWidget {
  final ChartTimeRange selectedRange;
  final List<ChartTimeRange> availableOptions;
  final DateTime? firstDataPoint;
  final ValueChanged<ChartTimeRange> onRangeSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeApplied;

  const TimeRangeFilterSheet({
    super.key,
    required this.selectedRange,
    required this.availableOptions,
    this.firstDataPoint,
    required this.onRangeSelected,
    required this.onCustomRangeApplied,
  });

  static Future<void> show({
    required BuildContext context,
    required ChartTimeRange selectedRange,
    required List<ChartTimeRange> availableOptions,
    DateTime? firstDataPoint,
    required ValueChanged<ChartTimeRange> onRangeSelected,
    required void Function(DateTime start, DateTime end) onCustomRangeApplied,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => TimeRangeFilterSheet(
        selectedRange: selectedRange,
        availableOptions: availableOptions,
        firstDataPoint: firstDataPoint,
        onRangeSelected: onRangeSelected,
        onCustomRangeApplied: onCustomRangeApplied,
      ),
    );
  }

  String _chipLabel(AppLocalizations l, ChartTimeRange range) {
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

  Future<void> _handleCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final minDate = firstDataPoint ?? DateTime(now.year - 5, 1, 1);
    final maxDate = DateTime(now.year, now.month, 1);

    final initialStart = selectedRange == ChartTimeRange.custom
        ? DateTime(now.year - 1, now.month, 1)
        : minDate;

    final result = await CustomDateRangeDialog.show(
      context: context,
      initialStart: initialStart,
      initialEnd: maxDate,
      minDate: minDate,
      maxDate: maxDate,
    );

    if (result != null) {
      final (start, end) = result;
      onCustomRangeApplied(start, end);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.timeRangeLabel,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableOptions.map((range) {
                return ChoiceChip(
                  label: Text(_chipLabel(l, range)),
                  selected: range == selectedRange,
                  onSelected: (_) {
                    if (range == ChartTimeRange.custom) {
                      _handleCustomRange(context);
                    } else {
                      onRangeSelected(range);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
