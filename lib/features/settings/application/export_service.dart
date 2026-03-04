import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'export_service.g.dart';

@riverpod
class ExportService extends _$ExportService {
  @override
  FutureOr<void> build() {}

  Future<void> exportData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);

      // Get all entries with details
      final entriesStream = repo.watchEntriesWithDetails();
      final entries = await entriesStream.first;

      // Prepare CSV data
      List<List<dynamic>> rows = [
        [
          'Date',
          'Store',
          'Location',
          'Category',
          'Product',
          'Price',
          'Quantity',
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
          entry.location ?? '',
          category.name,
          product.name,
          entry.price,
          entry.quantity,
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
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My InflaBasket Purchase History',
      );
    });
  }
}
