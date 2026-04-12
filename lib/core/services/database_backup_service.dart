import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'database_backup_service.g.dart';

@riverpod
class DatabaseBackupService extends _$DatabaseBackupService {
  static const _autoBackupPrefix = 'InflaBasket_AutoBackup_';
  static const _maxAutoBackupsToKeep = 14;
  bool _isAutoBackupRunning = false;

  @override
  FutureOr<void> build() => null;

  String get _dbFilename =>
      'InflaBasket_Backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.sqlite';

  String get _autoBackupFilename =>
      '$_autoBackupPrefix${DateFormat('yyyy-MM-dd_HH-mm-ss-SSS').format(DateTime.now())}.sqlite';

  Future<File> _dbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'db.sqlite');
    return File(dbPath);
  }

  Future<Directory> _internalAutoBackupDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(docsDir.path, 'backups', 'auto'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  bool _isLikelyStaleAppContainerPath(
    String configuredPath,
    String currentDocsPath,
  ) {
    const marker = '/Containers/Data/Application/';
    if (!configuredPath.contains(marker)) return false;

    String normalizeForComparison(String value) {
      final normalized = p.normalize(value);
      if (normalized.startsWith('/private/var/')) {
        return normalized.replaceFirst('/private', '');
      }
      return normalized;
    }

    final normalizedConfigured = normalizeForComparison(configuredPath);
    final normalizedCurrent = normalizeForComparison(currentDocsPath);
    return !normalizedConfigured.startsWith(normalizedCurrent);
  }

  Future<void> _copyAutoBackupToExternal(File sourceBackupFile) async {
    final settings = ref.read(settingsControllerProvider);
    final externalPath = settings.autoBackupExternalPath.trim();
    if (externalPath.isEmpty) return;

    final docsDir = await getApplicationDocumentsDirectory();
    if (_isLikelyStaleAppContainerPath(externalPath, docsDir.path)) {
      await ref
          .read(settingsControllerProvider.notifier)
          .clearAutoBackupExternalPath();
      return;
    }

    final externalDir = Directory(externalPath);
    if (!await externalDir.exists()) {
      return;
    }

    final targetPath =
        p.join(externalDir.path, p.basename(sourceBackupFile.path));
    await sourceBackupFile.copy(targetPath);
  }

  Future<void> _pruneOldInternalAutoBackups(Directory backupDir) async {
    final all = await backupDir
        .list()
        .where((entry) =>
            entry is File &&
            p.basename(entry.path).startsWith(_autoBackupPrefix))
        .cast<File>()
        .toList();

    if (all.length <= _maxAutoBackupsToKeep) {
      return;
    }

    all.sort((a, b) => b.path.compareTo(a.path));
    final toDelete = all.skip(_maxAutoBackupsToKeep);
    for (final file in toDelete) {
      try {
        await file.delete();
      } catch (_) {
        // Best-effort cleanup only.
      }
    }
  }

  Future<String?> pickExternalBackupDirectory() async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select backup folder',
    );
    if (selectedPath == null || selectedPath.isEmpty) {
      return null;
    }

    await ref
        .read(settingsControllerProvider.notifier)
        .setAutoBackupExternalPath(selectedPath);
    return selectedPath;
  }

  Future<bool> runAutoBackup({bool force = false}) async {
    if (_isAutoBackupRunning) return false;

    final settings = ref.read(settingsControllerProvider);
    if (!force && !settings.autoBackupEnabled) return false;

    _isAutoBackupRunning = true;
    try {
      final dbFile = await _dbFile();
      if (!await dbFile.exists()) {
        return false;
      }

      final backupDir = await _internalAutoBackupDir();
      final backupPath = p.join(backupDir.path, _autoBackupFilename);
      final localBackup = await dbFile.copy(backupPath);

      try {
        await _copyAutoBackupToExternal(localBackup);
      } on FileSystemException catch (error) {
        debugPrint('External auto backup failed: $error');
      }

      await _pruneOldInternalAutoBackups(backupDir);
      await ref
          .read(settingsControllerProvider.notifier)
          .setAutoBackupLastAt(DateTime.now());
      return true;
    } catch (error, stackTrace) {
      debugPrint('Auto backup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _isAutoBackupRunning = false;
    }
  }

  Future<String> exportDatabase() async {
    final dbFile = await _dbFile();
    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    final tempDir = await getTemporaryDirectory();
    final backupPath = p.join(tempDir.path, _dbFilename);

    await dbFile.copy(backupPath);

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupPath)],
          text: 'InflaBasket Backup',
        ),
      );
    } catch (e) {
      debugPrint('SharePlus failed on Linux: $e');
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save InflaBasket Backup',
        fileName: _dbFilename,
        type: FileType.custom,
        allowedExtensions: ['sqlite'],
      );
      if (result != null) {
        await File(backupPath).copy(result);
      } else {
        throw Exception('Export cancelled');
      }
    }

    return _dbFilename;
  }

  Future<String?> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
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
    final dbFile = await _dbFile();
    final db = AppDatabase(NativeDatabase(dbFile));
    try {
      final entries = await (db.select(db.purchaseEntries).join([
        innerJoin(db.products,
            db.products.id.equalsExp(db.purchaseEntries.productId)),
        innerJoin(
            db.categories, db.categories.id.equalsExp(db.products.categoryId)),
      ])).get();

      final categories = await db.select(db.categories).get();
      final products = await db.select(db.products).get();
      final priceHistories = await db.select(db.priceHistories).get();

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
        'version': '1.6.0',
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
                  'storeName': p.storeName,
                })
            .toList(),
        'entries': entriesList,
        'priceHistories': priceHistories
            .map((h) => {
                  'id': h.id,
                  'productId': h.productId,
                  'price': h.price,
                  'monthYear': h.monthYear,
                  'createdAt': h.createdAt.toIso8601String(),
                })
            .toList(),
      };

      final jsonStr = jsonEncode(backup);

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final filePath = p.join(tempDir.path, 'InflaBasket_Export_$dateStr.json');
      final file = File(filePath);
      await file.writeAsString(jsonStr);

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            text: 'InflaBasket Export',
          ),
        );
      } catch (e) {
        debugPrint('SharePlus failed on Linux: $e');
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save InflaBasket Export',
          fileName: 'InflaBasket_Export_$dateStr.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (result != null) {
          await file.copy(result);
        } else {
          throw Exception('Export cancelled');
        }
      }

      return filePath;
    } finally {
      await db.close();
    }
  }
}
