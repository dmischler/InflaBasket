import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'settings_repository.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepository(db);
}

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  Future<List<Setting>> getAllSettings() async {
    return _db.select(_db.settings).get();
  }

  Future<void> setSetting(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<void> migrateFromSharedPreferences(SharedPreferences prefs) async {
    final existing = await getAllSettings();
    final existingKeys = existing.map((s) => s.key).toSet();

    final migrations = <String, String>{};

    void addIfNotExists(String key, String value) {
      if (!existingKeys.contains(key)) {
        migrations[key] = value;
      }
    }

    addIfNotExists('currency', prefs.getString('settings_currency') ?? 'CHF');
    addIfNotExists(
        'is_metric', (prefs.getBool('settings_is_metric') ?? true).toString());
    addIfNotExists('locale', prefs.getString('settings_locale') ?? 'en');
    addIfNotExists('is_bitcoin_mode',
        (prefs.getBool('settings_bitcoin_mode') ?? false).toString());

    final themeIndex = prefs.getInt('settings_theme_type');
    if (themeIndex != null) {
      addIfNotExists('is_bitcoin_mode', (themeIndex == 3).toString());
    } else {
      addIfNotExists('is_dark_mode',
          (prefs.getBool('settings_dark_mode') ?? true).toString());
    }

    addIfNotExists(
        'price_update_reminder_enabled',
        (prefs.getBool('settings_price_update_reminder_enabled') ?? false)
            .toString());
    addIfNotExists(
        'price_update_reminder_months',
        (prefs.getInt('settings_price_update_reminder_months') ?? 6)
            .toString());
    addIfNotExists('ai_consent_accepted',
        (prefs.getBool('ai_consent_accepted') ?? false).toString());
    addIfNotExists('has_completed_onboarding',
        (prefs.getBool('has_completed_onboarding') ?? false).toString());
    addIfNotExists('ai_provider', 'gemini');
    addIfNotExists('gemini_api_key', '');
    addIfNotExists('openai_api_key', '');
    addIfNotExists('auto_backup_enabled',
        (prefs.getBool('settings_auto_save_enabled') ?? true).toString());
    addIfNotExists('auto_backup_external_path',
        prefs.getString('settings_auto_save_path') ?? '');
    addIfNotExists('auto_backup_last_at',
        prefs.getString('settings_last_backup_at') ?? '');

    if (migrations.isNotEmpty) {
      await _db.batch((b) {
        b.insertAll(
          _db.settings,
          migrations.entries
              .map((e) => SettingsCompanion.insert(key: e.key, value: e.value)),
        );
      });
    }
  }
}
