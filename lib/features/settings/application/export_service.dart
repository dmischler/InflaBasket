import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'export_service.g.dart';

@riverpod
class ExportService extends _$ExportService {
  @override
  FutureOr<void> build() => null;

  Future<void> exportData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);
      final languageCode = ref.read(settingsControllerProvider).locale;

      // Get all entries with details
      final entriesStream = repo.watchEntriesWithDetails();
      final entries = await entriesStream.first;

      // Prepare CSV data
      List<List<dynamic>> rows = [
        [
          'Date',
          'Store',
          'Category',
          'Product',
          'Price',
          'Quantity',
          'Unit',
          'Notes'
        ],
      ];

      final dateFormat = DateFormat('yyyy-MM-dd');

      for (final detail in entries) {
        final entry = detail.entry;
        final product = detail.product;
        final category = detail.category;

        rows.add([
          dateFormat.format(entry.purchaseDate),
          entry.storeName,
          CategoryLocalization.displayName(
            category.name,
            languageCode: languageCode,
          ),
          product.name,
          entry.price,
          entry.quantity,
          unitTypeFromString(entry.unit).label,
          entry.notes ?? '',
        ]);
      }

      final csvData = const CsvEncoder().convert(rows);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final file = File('${tempDir.path}/inflabasket_export_$dateStr.csv');
      await file.writeAsString(csvData);

      // Share
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
          ),
        );
      } catch (e) {
        debugPrint('SharePlus failed on Linux: $e');
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save InflaBasket Export',
          fileName: 'inflabasket_export_$dateStr.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (result != null) {
          await file.copy(result);
        } else {
          throw Exception('Export cancelled');
        }
      }
    });
  }
}
