import 'dart:ui';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
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

  const AppSettings({
    this.currency = 'CHF',
    this.isMetric = true,
    this.locale = 'en',
  });

  AppSettings copyWith({
    String? currency,
    bool? isMetric,
    String? locale,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      isMetric: isMetric ?? this.isMetric,
      locale: locale ?? this.locale,
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
  static const supportedLocales = <String>['en', 'de', 'fr', 'it'];
  static const _currencyKey = 'settings_currency';
  static const _metricKey = 'settings_is_metric';
  static const _localeKey = 'settings_locale';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      currency: prefs.getString(_currencyKey) ?? 'CHF',
      isMetric: prefs.getBool(_metricKey) ?? true,
      locale: resolveAppLanguageCode(prefs.getString(_localeKey)),
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
