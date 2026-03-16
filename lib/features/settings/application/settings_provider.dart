import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/services/notification_service.dart';
import 'package:inflabasket/core/services/price_update_reminder_service.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

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
  final bool priceUpdateReminderEnabled;
  final int priceUpdateReminderMonths;

  const AppSettings({
    this.currency = 'CHF',
    this.isMetric = true,
    this.locale = 'en',
    this.isBitcoinMode = false,
    this.priceUpdateReminderEnabled = false,
    this.priceUpdateReminderMonths = 6,
  });

  AppSettings copyWith({
    String? currency,
    bool? isMetric,
    String? locale,
    bool? isBitcoinMode,
    bool? priceUpdateReminderEnabled,
    int? priceUpdateReminderMonths,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      isMetric: isMetric ?? this.isMetric,
      locale: locale ?? this.locale,
      isBitcoinMode: isBitcoinMode ?? this.isBitcoinMode,
      priceUpdateReminderEnabled:
          priceUpdateReminderEnabled ?? this.priceUpdateReminderEnabled,
      priceUpdateReminderMonths:
          priceUpdateReminderMonths ?? this.priceUpdateReminderMonths,
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
  static const _priceUpdateReminderKey =
      'settings_price_update_reminder_enabled';
  static const _priceUpdateReminderMonthsKey =
      'settings_price_update_reminder_months';

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
      priceUpdateReminderEnabled:
          prefs.getBool(_priceUpdateReminderKey) ?? false,
      priceUpdateReminderMonths:
          prefs.getInt(_priceUpdateReminderMonthsKey) ?? 6,
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

  Future<void> factoryReset(AppDatabase database) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await database.resetDatabase();
    await prefs.clear();
    await prefs.setBool(hasCompletedOnboardingKey, false);
    ref.invalidate(settingsControllerProvider);
    ref.invalidate(categoryWeightsControllerProvider);
  }
}

/// Manages the user-defined category basket weights.
///
/// The map is keyed by categoryId. Values are fractions 0.0–1.0 that sum
/// to 1.0 when all categories are covered. An empty map means "use
/// spend-weighted averaging" (the default behaviour).
@riverpod
class CategoryWeightsController extends _$CategoryWeightsController {
  @override
  Future<Map<int, double>> build() async {
    final repo = ref.watch(entryRepositoryProvider);
    return repo.getCategoryWeights();
  }

  /// Persists [weights] (categoryId → fraction). Caller must ensure they
  /// sum to 1.0 before calling.
  Future<void> saveWeights(Map<int, double> weights) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);
      await repo.saveCategoryWeights(weights);
      return weights;
    });
  }

  /// Removes all custom weights; basket reverts to spend-weighted averaging.
  Future<void> clearWeights() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);
      await repo.clearCategoryWeights();
      return <int, double>{};
    });
  }
}
