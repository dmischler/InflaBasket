import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
}

class AppSettings {
  final String currency;
  final bool isMetric;

  const AppSettings({
    this.currency = 'CHF',
    this.isMetric = true,
  });

  AppSettings copyWith({
    String? currency,
    bool? isMetric,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      isMetric: isMetric ?? this.isMetric,
    );
  }
}

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  static const _currencyKey = 'settings_currency';
  static const _metricKey = 'settings_is_metric';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      currency: prefs.getString(_currencyKey) ?? 'CHF',
      isMetric: prefs.getBool(_metricKey) ?? true,
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
}
