import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/widgets/custom_date_range_dialog.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';

class ChartDateRangeHelper {
  static Future<void> showCustomDatePicker({
    required BuildContext context,
    required WidgetRef ref,
    required ChartTimeFilter currentFilter,
    DateTime? firstDataPoint,
  }) async {
    final now = DateTime.now();
    final minDate = firstDataPoint ?? DateTime(now.year - 5, 1, 1);
    final maxDate = DateTime(now.year, now.month, 1);
    final startDate =
        currentFilter.customStart ?? DateTime(now.year - 1, now.month, 1);
    final endDate = currentFilter.customEnd ?? maxDate;

    final result = await CustomDateRangeDialog.show(
      context: context,
      initialStart: startDate,
      initialEnd: endDate,
      minDate: minDate,
      maxDate: maxDate,
    );

    if (result != null) {
      ref.read(chartTimeFilterControllerProvider.notifier).setCustomRange(
            result.$1,
            result.$2,
          );
    }
  }
}
