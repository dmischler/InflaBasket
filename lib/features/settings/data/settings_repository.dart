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

  Stream<List<Setting>> watchAllSettings() {
    return _db.select(_db.settings).watch();
  }

  Future<List<Setting>> getAllSettings() async {
    return _db.select(_db.settings).get();
  }

  Future<String?> getSetting(String key) async {
    final query = _db.select(_db.settings)..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  Stream<String?> watchSetting(String key) {
    final query = _db.select(_db.settings)..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  Future<void> setSetting(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<void> deleteSetting(String key) async {
    await (_db.delete(_db.settings)..where((t) => t.key.equals(key))).go();
  }

  Future<void> setApiKey(String provider, String apiKey) async {
    final key = provider == 'gemini' ? 'gemini_api_key' : 'openai_api_key';
    await setSetting(key, apiKey);
  }

  Future<void> seedDefaults() async {
    await _db.seedDefaultSettings();
  }

  Future<void> factoryReset({bool keepApiKeys = true}) async {
    if (keepApiKeys) {
      final apiKeys = await (_db.select(_db.settings)
            ..where((t) => t.key.isIn(['gemini_api_key', 'openai_api_key'])))
          .get();
      await _db.delete(_db.settings).go();
      if (apiKeys.isNotEmpty) {
        await _db.batch((b) {
          b.insertAll(_db.settings, apiKeys);
        });
      }
    } else {
      await _db.delete(_db.settings).go();
    }
    await _db.seedDefaultSettings();
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
