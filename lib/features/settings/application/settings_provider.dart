import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/auto_save_config.dart';
import 'package:inflabasket/core/services/notification_service.dart';
import 'package:inflabasket/core/services/price_update_reminder_service.dart';
import 'package:inflabasket/core/database/database.dart';

part 'settings_provider.g.dart';

@riverpod
Future<String> appVersion(AppVersionRef ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
}

class AppSettings {
  final String currency;
  final bool isMetric;
  final String locale;
  final bool isBitcoinMode;
  final bool isDarkMode;
  final bool priceUpdateReminderEnabled;
  final int priceUpdateReminderMonths;
  final bool autoSaveEnabled;
  final AutoSaveStorageType autoSaveStorageType;
  final String? autoSavePath;
  final DateTime? lastBackupAt;

  const AppSettings({
    this.currency = 'CHF',
    this.isMetric = true,
    this.locale = 'en',
    this.isBitcoinMode = false,
    this.isDarkMode = true,
    this.priceUpdateReminderEnabled = false,
    this.priceUpdateReminderMonths = 6,
    this.autoSaveEnabled = false,
    this.autoSaveStorageType = AutoSaveStorageType.local,
    this.autoSavePath,
    this.lastBackupAt,
  });

  AppSettings copyWith({
    String? currency,
    bool? isMetric,
    String? locale,
    bool? isBitcoinMode,
    bool? isDarkMode,
    bool? priceUpdateReminderEnabled,
    int? priceUpdateReminderMonths,
    bool? autoSaveEnabled,
    AutoSaveStorageType? autoSaveStorageType,
    String? autoSavePath,
    DateTime? lastBackupAt,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      isMetric: isMetric ?? this.isMetric,
      locale: locale ?? this.locale,
      isBitcoinMode: isBitcoinMode ?? this.isBitcoinMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      priceUpdateReminderEnabled:
          priceUpdateReminderEnabled ?? this.priceUpdateReminderEnabled,
      priceUpdateReminderMonths:
          priceUpdateReminderMonths ?? this.priceUpdateReminderMonths,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      autoSaveStorageType: autoSaveStorageType ?? this.autoSaveStorageType,
      autoSavePath: autoSavePath ?? this.autoSavePath,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }
}

String resolveAppLanguageCode([String? languageCode]) {
  return CategoryLocalization.normalizeLanguageCode(
    languageCode ?? PlatformDispatcher.instance.locale.languageCode,
  );
}

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  static const supportedLocales = <String>['en', 'de'];
  static const _currencyKey = 'settings_currency';
  static const _metricKey = 'settings_is_metric';
  static const _localeKey = 'settings_locale';
  static const _bitcoinModeKey = 'settings_bitcoin_mode';
  static const hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const aiConsentAcceptedKey = 'ai_consent_accepted';
  static const _priceUpdateReminderKey =
      'settings_price_update_reminder_enabled';
  static const _priceUpdateReminderMonthsKey =
      'settings_price_update_reminder_months';
  static const _darkModeKey = 'settings_dark_mode';
  static const _autoSaveEnabledKey = 'settings_auto_save_enabled';
  static const _autoSaveStorageTypeKey = 'settings_auto_save_storage_type';
  static const _autoSavePathKey = 'settings_auto_save_path';
  static const _lastBackupAtKey = 'settings_last_backup_at';

  // Legacy key - kept for migration
  static const _themeKey = 'settings_theme_type';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    // Migration: Convert old theme index to isBitcoinMode
    // Old indices: 0=standardLight, 1=standardDark, 2=luxeDarkFiat, 3=luxeDarkBitcoin, 4=neoCyberpunkTerminal
    // If user had luxeDarkBitcoin (index 3), set isBitcoinMode=true
    final savedThemeIndex = prefs.getInt(_themeKey);
    bool isBitcoinMode = false;
    if (savedThemeIndex != null) {
      // Index 3 was luxeDarkBitcoin
      isBitcoinMode = savedThemeIndex == 3;
      // Clean up legacy key
      prefs.remove(_themeKey);
    } else {
      isBitcoinMode = prefs.getBool(_bitcoinModeKey) ?? false;
    }

    return AppSettings(
      currency: prefs.getString(_currencyKey) ?? 'CHF',
      isMetric: prefs.getBool(_metricKey) ?? true,
      locale: resolveAppLanguageCode(prefs.getString(_localeKey)),
      isBitcoinMode: isBitcoinMode,
      isDarkMode: prefs.getBool(_darkModeKey) ?? true,
      priceUpdateReminderEnabled:
          prefs.getBool(_priceUpdateReminderKey) ?? false,
      priceUpdateReminderMonths:
          prefs.getInt(_priceUpdateReminderMonthsKey) ?? 6,
      autoSaveEnabled: prefs.getBool(_autoSaveEnabledKey) ?? false,
      autoSaveStorageType: AutoSaveStorageType
          .values[prefs.getInt(_autoSaveStorageTypeKey) ?? 0],
      autoSavePath: prefs.getString(_autoSavePathKey),
      lastBackupAt: prefs.getString(_lastBackupAtKey) != null
          ? DateTime.tryParse(prefs.getString(_lastBackupAtKey)!)
          : null,
    );
  }

  Future<void> setCurrency(String currency) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_currencyKey, currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> setMetric(bool isMetric) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_metricKey, isMetric);
    state = state.copyWith(isMetric: isMetric);
  }

  Future<void> setLocale(String locale) async {
    final normalizedLocale = resolveAppLanguageCode(locale);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, normalizedLocale);
    state = state.copyWith(locale: normalizedLocale);
  }

  Future<void> setBitcoinMode(bool isBitcoinMode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_bitcoinModeKey, isBitcoinMode);
    state = state.copyWith(isBitcoinMode: isBitcoinMode);
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_darkModeKey, isDarkMode);
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  bool get hasAcceptedAiConsent {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(aiConsentAcceptedKey) ?? false;
  }

  Future<void> acceptAiConsent() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(aiConsentAcceptedKey, true);
  }

  Future<bool> setPriceUpdateReminder(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);

    if (enabled) {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) {
        final notificationService = ref.read(notificationServiceProvider);
        final granted = await notificationService.requestPermission();
        if (!granted) {
          return false;
        }
      }
    }

    await prefs.setBool(_priceUpdateReminderKey, enabled);
    state = state.copyWith(priceUpdateReminderEnabled: enabled);

    final reminderService = ref.read(priceUpdateReminderServiceProvider);
    await reminderService.syncReminderSchedule();

    return true;
  }

  Future<void> setPriceUpdateReminderMonths(int months) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_priceUpdateReminderMonthsKey, months);
    state = state.copyWith(priceUpdateReminderMonths: months);

    if (state.priceUpdateReminderEnabled) {
      final reminderService = ref.read(priceUpdateReminderServiceProvider);
      await reminderService.syncReminderSchedule();
    }
  }

  Future<void> setAutoSaveEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_autoSaveEnabledKey, enabled);
    state = state.copyWith(autoSaveEnabled: enabled);
  }

  Future<void> setAutoSaveStorageType(AutoSaveStorageType type) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_autoSaveStorageTypeKey, type.index);
    state = state.copyWith(autoSaveStorageType: type);
  }

  Future<void> setAutoSavePath(String? path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (path != null) {
      await prefs.setString(_autoSavePathKey, path);
    } else {
      await prefs.remove(_autoSavePathKey);
    }
    state = state.copyWith(autoSavePath: path);
  }

  Future<void> setLastBackupAt(DateTime? time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (time != null) {
      await prefs.setString(_lastBackupAtKey, time.toIso8601String());
    } else {
      await prefs.remove(_lastBackupAtKey);
    }
    state = state.copyWith(lastBackupAt: time);
  }

  Future<void> factoryReset(AppDatabase database) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await database.resetDatabase();
    await prefs.clear();
    await prefs.setBool(hasCompletedOnboardingKey, false);
    ref.invalidate(settingsControllerProvider);
  }
}
