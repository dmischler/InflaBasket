import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class CustomDateRangeDialog extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime minDate;
  final DateTime maxDate;

  const CustomDateRangeDialog({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.minDate,
    required this.maxDate,
  });

  static Future<(DateTime, DateTime)?> show({
    required BuildContext context,
    required DateTime initialStart,
    required DateTime initialEnd,
    required DateTime minDate,
    required DateTime maxDate,
  }) {
    return showDialog<(DateTime, DateTime)>(
      context: context,
      builder: (context) => CustomDateRangeDialog(
        initialStart: initialStart,
        initialEnd: initialEnd,
        minDate: minDate,
        maxDate: maxDate,
      ),
    );
  }

  @override
  State<CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<CustomDateRangeDialog> {
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
        13 - widget.minDate.month,
        (i) => widget.minDate.month + i,
      );
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
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.timeRangeCustom),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l.filterDateFrom}:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: startYear,
                  decoration: InputDecoration(labelText: l.filterYear),
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
                  value: startMonth,
                  decoration: InputDecoration(labelText: l.filterMonth),
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
          Text('${l.filterDateTo}:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: endYear,
                  decoration: InputDecoration(labelText: l.filterYear),
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
                  value: endMonth,
                  decoration: InputDecoration(labelText: l.filterMonth),
                  items: _availableEndMonths
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                              DateFormat.MMM().format(DateTime(2024, m, 1)))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => endMonth = value);
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
          child: Text(l.cancel),
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
          child: Text(l.apply),
        ),
      ],
    );
  }
}
