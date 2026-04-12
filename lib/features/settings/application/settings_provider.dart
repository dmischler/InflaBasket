import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/services/notification_service.dart';
import 'package:inflabasket/core/services/price_update_reminder_service.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/data/settings_repository.dart';

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

enum AiProvider { gemini, openai }

class AppSettings {
  final String currency;
  final bool isMetric;
  final String locale;
  final bool isBitcoinMode;
  final bool isDarkMode;
  final bool priceUpdateReminderEnabled;
  final int priceUpdateReminderMonths;
  final bool aiConsentAccepted;
  final bool hasCompletedOnboarding;
  final AiProvider aiProvider;
  final String geminiApiKey;
  final String openaiApiKey;
  final bool autoBackupEnabled;
  final String autoBackupExternalPath;
  final DateTime? autoBackupLastAt;

  const AppSettings({
    this.currency = 'CHF',
    this.isMetric = true,
    this.locale = 'en',
    this.isBitcoinMode = false,
    this.isDarkMode = true,
    this.priceUpdateReminderEnabled = false,
    this.priceUpdateReminderMonths = 6,
    this.aiConsentAccepted = false,
    this.hasCompletedOnboarding = false,
    this.aiProvider = AiProvider.gemini,
    this.geminiApiKey = '',
    this.openaiApiKey = '',
    this.autoBackupEnabled = true,
    this.autoBackupExternalPath = '',
    this.autoBackupLastAt,
  });

  String get currentApiKey =>
      aiProvider == AiProvider.gemini ? geminiApiKey : openaiApiKey;

  bool get hasApiKey => currentApiKey.isNotEmpty;

  AppSettings copyWith({
    String? currency,
    bool? isMetric,
    String? locale,
    bool? isBitcoinMode,
    bool? isDarkMode,
    bool? priceUpdateReminderEnabled,
    int? priceUpdateReminderMonths,
    bool? aiConsentAccepted,
    bool? hasCompletedOnboarding,
    AiProvider? aiProvider,
    String? geminiApiKey,
    String? openaiApiKey,
    bool? autoBackupEnabled,
    String? autoBackupExternalPath,
    DateTime? autoBackupLastAt,
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
      aiConsentAccepted: aiConsentAccepted ?? this.aiConsentAccepted,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      aiProvider: aiProvider ?? this.aiProvider,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupExternalPath:
          autoBackupExternalPath ?? this.autoBackupExternalPath,
      autoBackupLastAt: autoBackupLastAt ?? this.autoBackupLastAt,
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

  @override
  AppSettings build() {
    return const AppSettings();
  }

  Future<void> initializeFromDatabase() async {
    final repo = ref.read(settingsRepositoryProvider);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await repo.migrateFromSharedPreferences(prefs);
    } on UnimplementedError {
      // Ignored in tests that don't override sharedPreferencesProvider.
    }

    final settingsList = await repo.getAllSettings();
    final settingsMap = {for (final s in settingsList) s.key: s.value};

    settingsMap.remove('settings_theme_type');
    final isDarkMode =
        _parseBool(settingsMap['is_dark_mode'], defaultValue: true);
    final rawLastAutoBackup = settingsMap['auto_backup_last_at'] ?? '';
    final autoBackupLastAt =
        rawLastAutoBackup.isEmpty ? null : DateTime.tryParse(rawLastAutoBackup);

    state = AppSettings(
      currency: settingsMap['currency'] ?? 'CHF',
      isMetric: _parseBool(settingsMap['is_metric'], defaultValue: true),
      locale: resolveAppLanguageCode(settingsMap['locale']),
      isBitcoinMode: _parseBool(settingsMap['is_bitcoin_mode']),
      isDarkMode: isDarkMode,
      priceUpdateReminderEnabled:
          _parseBool(settingsMap['price_update_reminder_enabled']),
      priceUpdateReminderMonths:
          int.tryParse(settingsMap['price_update_reminder_months'] ?? '6') ?? 6,
      aiConsentAccepted: _parseBool(settingsMap['ai_consent_accepted']),
      hasCompletedOnboarding:
          _parseBool(settingsMap['has_completed_onboarding']),
      aiProvider: settingsMap['ai_provider'] == 'openai'
          ? AiProvider.openai
          : AiProvider.gemini,
      geminiApiKey: settingsMap['gemini_api_key'] ?? '',
      openaiApiKey: settingsMap['openai_api_key'] ?? '',
      autoBackupEnabled:
          _parseBool(settingsMap['auto_backup_enabled'], defaultValue: true),
      autoBackupExternalPath: settingsMap['auto_backup_external_path'] ?? '',
      autoBackupLastAt: autoBackupLastAt,
    );
  }

  bool _parseBool(String? value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }

  Future<void> _set(String key, String value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setSetting(key, value);
  }

  Future<void> setCurrency(String currency) async {
    await _set('currency', currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> setMetric(bool isMetric) async {
    await _set('is_metric', isMetric.toString());
    state = state.copyWith(isMetric: isMetric);
  }

  Future<void> setLocale(String locale) async {
    final normalizedLocale = resolveAppLanguageCode(locale);
    await _set('locale', normalizedLocale);
    state = state.copyWith(locale: normalizedLocale);
  }

  Future<void> setBitcoinMode(bool isBitcoinMode) async {
    await _set('is_bitcoin_mode', isBitcoinMode.toString());
    state = state.copyWith(isBitcoinMode: isBitcoinMode);
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    await _set('is_dark_mode', isDarkMode.toString());
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  bool get hasAcceptedAiConsent => state.aiConsentAccepted;

  Future<void> acceptAiConsent() async {
    await _set('ai_consent_accepted', true.toString());
    state = state.copyWith(aiConsentAccepted: true);
  }

  Future<void> setAiProvider(AiProvider provider) async {
    await _set('ai_provider', provider.name);
    state = state.copyWith(aiProvider: provider);
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    await _set('gemini_api_key', apiKey);
    state = state.copyWith(geminiApiKey: apiKey);
  }

  Future<void> setOpenaiApiKey(String apiKey) async {
    await _set('openai_api_key', apiKey);
    state = state.copyWith(openaiApiKey: apiKey);
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _set('auto_backup_enabled', enabled.toString());
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  Future<void> setAutoBackupExternalPath(String path) async {
    await _set('auto_backup_external_path', path);
    state = state.copyWith(autoBackupExternalPath: path);
  }

  Future<void> clearAutoBackupExternalPath() async {
    await _set('auto_backup_external_path', '');
    state = state.copyWith(autoBackupExternalPath: '');
  }

  Future<void> setAutoBackupLastAt(DateTime? dateTime) async {
    final serialized = dateTime?.toIso8601String() ?? '';
    await _set('auto_backup_last_at', serialized);
    state = state.copyWith(autoBackupLastAt: dateTime);
  }

  Future<bool> setPriceUpdateReminder(bool enabled) async {
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

    await _set('price_update_reminder_enabled', enabled.toString());
    state = state.copyWith(priceUpdateReminderEnabled: enabled);

    final reminderService = ref.read(priceUpdateReminderServiceProvider);
    await reminderService.syncReminderSchedule();

    return true;
  }

  Future<void> setPriceUpdateReminderMonths(int months) async {
    await _set('price_update_reminder_months', months.toString());
    state = state.copyWith(priceUpdateReminderMonths: months);

    if (state.priceUpdateReminderEnabled) {
      final reminderService = ref.read(priceUpdateReminderServiceProvider);
      await reminderService.syncReminderSchedule();
    }
  }

  Future<void> factoryReset({bool keepApiKeys = true}) async {
    final database = ref.read(entryRepositoryProvider).database;
    await database.resetDatabase(keepApiKeys: keepApiKeys);
    await initializeFromDatabase();
  }
}
