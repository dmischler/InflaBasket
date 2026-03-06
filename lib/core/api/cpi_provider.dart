import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'cpi_provider.g.dart';

@riverpod
CpiClient cpiClient(CpiClientRef ref) => CpiClient(Dio());

/// Returns the CPI data points for the currently selected currency, or an
/// empty list if the currency has no supported CPI source.
///
/// Re-fetches whenever the currency changes. Results are not cached between
/// app restarts — the network call is cheap and infrequent.
@riverpod
Future<List<CpiDataPoint>> cpiData(CpiDataRef ref) async {
  final currency = ref.watch(settingsControllerProvider).currency;
  final source = cpiSourceForCurrency(currency);
  if (source == null) return [];
  final client = ref.read(cpiClientProvider);
  return client.fetchCpi(source);
}

/// Whether the CPI overlay is currently shown on the basket chart.
/// Persisted only for the session (not in SharedPreferences — that would
/// require an async provider here).
@riverpod
class ShowCpiOverlay extends _$ShowCpiOverlay {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}
