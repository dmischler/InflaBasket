import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:inflabasket/core/models/auto_save_config.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'auto_backup_service.g.dart';

@riverpod
AutoBackupService autoBackupService(AutoBackupServiceRef ref) {
  return AutoBackupService(ref);
}

class AutoBackupService {
  final Ref _ref;

  AutoBackupService(this._ref);

  String get _dbFilename =>
      'InflaBasket_Backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.sqlite';

  Future<bool> performBackup() async {
    final settings = _ref.read(settingsControllerProvider);
    final storageType = settings.autoSaveStorageType;
    final autoSavePath = settings.autoSavePath;

    try {
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        debugPrint('Database file not found at $dbPath');
        return false;
      }

      if (storageType == AutoSaveStorageType.local && autoSavePath != null) {
        await _backupToLocal(dbFile, autoSavePath);
      } else if (storageType == AutoSaveStorageType.cloud) {
        await _backupToCloud(dbFile);
      } else {
        debugPrint('No valid backup path configured');
        return false;
      }

      await _ref
          .read(settingsControllerProvider.notifier)
          .setLastBackupAt(DateTime.now());
      return true;
    } catch (e) {
      debugPrint('Backup failed: $e');
      return false;
    }
  }

  Future<void> _backupToLocal(File dbFile, String targetPath) async {
    final backupPath = p.join(targetPath, _dbFilename);
    await dbFile.copy(backupPath);
  }

  Future<void> _backupToCloud(File dbFile) async {
    final tempDir = await getTemporaryDirectory();
    final tempBackupPath = p.join(tempDir.path, _dbFilename);
    await dbFile.copy(tempBackupPath);

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempBackupPath)],
          text: 'InflaBasket Backup',
        ),
      );
    } catch (e) {
      debugPrint('SharePlus failed: $e');
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save InflaBasket Backup',
        fileName: _dbFilename,
        type: FileType.custom,
        allowedExtensions: ['sqlite'],
      );
      if (result != null) {
        await File(tempBackupPath).copy(result);
      } else {
        throw Exception('Backup cancelled');
      }
    }
  }

  Future<String?> pickStorageLocation() async {
    try {
      String? selectedPath;

      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final result = await FilePicker.platform.getDirectoryPath();
        selectedPath = result;
      } else {
        final result = await FilePicker.platform.getDirectoryPath();
        selectedPath = result;
      }

      if (selectedPath != null) {
        await _ref
            .read(settingsControllerProvider.notifier)
            .setAutoSavePath(selectedPath);
      }

      return selectedPath;
    } catch (e) {
      debugPrint('Failed to pick storage location: $e');
      return null;
    }
  }

  Future<String> _getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'db.sqlite');
  }

  Future<String?> getDatabasePath() async {
    try {
      return await _getDatabasePath();
    } catch (e) {
      debugPrint('Failed to get database path: $e');
      return null;
    }
  }
}
