import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inflabasket/core/database/database.dart';

part 'database_backup_service.g.dart';

@riverpod
class DatabaseBackupService extends _$DatabaseBackupService {
  @override
  FutureOr<void> build() => null;

  String get _dbFilename =>
      'InflaBasket_Backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.sqlite';

  Future<String> exportDatabase() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'db.sqlite');

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    final tempDir = await getTemporaryDirectory();
    final backupPath = p.join(tempDir.path, _dbFilename);

    await dbFile.copy(backupPath);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backupPath)],
        text: 'InflaBasket Backup',
      ),
    );

    return _dbFilename;
  }

  Future<String?> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sqlite', 'db'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.first;
    if (pickedFile.path == null) return null;

    final file = File(pickedFile.path!);
    final bytes = await file.openRead(0, 16).first;
    final header = String.fromCharCodes(bytes);
    if (!header.startsWith('SQLite format 3')) {
      throw Exception('Invalid database file');
    }

    final tempDir = await getTemporaryDirectory();
    final pendingPath = p.join(tempDir.path, 'pending_restore.sqlite');
    await file.copy(pendingPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_restore_path', pendingPath);

    return pendingPath;
  }

  Future<String> exportAsJson() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'db.sqlite');
    final db = AppDatabase(NativeDatabase(File(dbPath)));

    final entries = await (db.select(db.purchaseEntries).join([
      innerJoin(
          db.products, db.products.id.equalsExp(db.purchaseEntries.productId)),
      innerJoin(
          db.categories, db.categories.id.equalsExp(db.products.categoryId)),
    ])).get();

    final categories = await db.select(db.categories).get();
    final products = await db.select(db.products).get();

    final List<Map<String, dynamic>> entriesList = [];
    for (final row in entries) {
      final entry = row.readTable(db.purchaseEntries);
      final product = row.readTable(db.products);
      final category = row.readTable(db.categories);
      entriesList.add({
        'id': entry.id,
        'productName': product.name,
        'categoryName': category.name,
        'storeName': entry.storeName,
        'purchaseDate': entry.purchaseDate.toIso8601String(),
        'price': entry.price,
        'quantity': entry.quantity,
        'unit': entry.unit,
        'notes': entry.notes,
        'priceSats': entry.priceSats,
      });
    }

    final Map<String, dynamic> backup = {
      'version': '1.5.0',
      'exportDate': DateTime.now().toIso8601String(),
      'categories': categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'iconString': c.iconString,
                'isCustom': c.isCustom,
              })
          .toList(),
      'products': products
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'categoryId': p.categoryId,
                'barcode': p.barcode,
                'brand': p.brand,
              })
          .toList(),
      'entries': entriesList,
    };

    final jsonStr = jsonEncode(backup);

    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final filePath = p.join(tempDir.path, 'InflaBasket_Export_$dateStr.json');
    final file = File(filePath);
    await file.writeAsString(jsonStr);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: 'InflaBasket Export',
      ),
    );

    return filePath;
  }
}
