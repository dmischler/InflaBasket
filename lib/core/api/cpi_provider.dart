import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/core/api/money_supply_client.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'cpi_provider.g.dart';

enum ComparisonOverlayType {
  cpi,
  moneySupply,
}

List<ComparisonOverlayType> availableComparisonOverlayTypes(String currency) {
  final available = <ComparisonOverlayType>[];
  if (cpiSourceForCurrency(currency) != null) {
    available.add(ComparisonOverlayType.cpi);
  }
  if (moneySupplySourceForCurrency(currency) != null) {
    available.add(ComparisonOverlayType.moneySupply);
  }
  return available;
}

class ComparisonRequestWindow {
  const ComparisonRequestWindow({
    required this.startMonth,
    required this.observationCount,
  });

  final DateTime startMonth;
  final int observationCount;
}

ComparisonRequestWindow _comparisonWindow(List<MonthlyIndex> history) {
  final validHistory = history.where((item) => item.index.isFinite).toList();
  if (validHistory.length < 2) {
    final now = DateTime.now();
    final startMonth = DateTime(now.year - 2, now.month);
    return ComparisonRequestWindow(
        startMonth: startMonth, observationCount: 24);
  }

  final start = validHistory.first.month;
  final end = validHistory.last.month;
  final observationCount =
      (end.year - start.year) * 12 + end.month - start.month + 1;

  return ComparisonRequestWindow(
    startMonth: DateTime(start.year, start.month),
    observationCount: observationCount.clamp(2, 240),
  );
}

@riverpod
CpiClient cpiClient(CpiClientRef ref) =>
    CpiClient(Dio(BaseOptions(headers: {'User-Agent': 'InflaBasket/1.0'})));

@riverpod
MoneySupplyClient moneySupplyClient(MoneySupplyClientRef ref) =>
    MoneySupplyClient(
      Dio(BaseOptions(headers: {'User-Agent': 'InflaBasket/1.0'})),
    );

/// Returns the CPI data points for the currently selected currency, or an
/// empty list if the currency has no supported CPI source.
///
/// Re-fetches whenever the currency changes. Results are not cached between
/// app restarts — the network call is cheap and infrequent.
@riverpod
Future<List<CpiDataPoint>> cpiData(CpiDataRef ref) async {
  final currency = ref.watch(settingsControllerProvider).currency;
  final window = _comparisonWindow(ref.watch(basketIndexHistoryProvider));
  final source = cpiSourceForCurrency(currency);
  if (source == null) return [];
  final client = ref.read(cpiClientProvider);
  return client.fetchCpi(
    source,
    observationCount: window.observationCount,
  );
}

@riverpod
Future<List<MoneySupplyDataPoint>> moneySupplyData(
    MoneySupplyDataRef ref) async {
  final currency = ref.watch(settingsControllerProvider).currency;
  final window = _comparisonWindow(ref.watch(basketIndexHistoryProvider));
  final source = moneySupplySourceForCurrency(currency);
  if (source == null) return [];
  final client = ref.read(moneySupplyClientProvider);
  return client.fetchMoneySupply(
    source,
    startMonth: window.startMonth,
    observationCount: window.observationCount,
  );
}

@riverpod
ComparisonOverlayType? effectiveComparisonOverlayType(
    EffectiveComparisonOverlayTypeRef ref) {
  final currency = ref.watch(settingsControllerProvider).currency;
  final available = availableComparisonOverlayTypes(currency);
  if (available.isEmpty) return null;

  final selected = ref.watch(selectedComparisonOverlayTypeProvider);
  if (available.contains(selected)) return selected;
  return available.first;
}

@riverpod
Future<List<ComparisonDataPoint>> comparisonOverlayData(
    ComparisonOverlayDataRef ref) async {
  final selected = ref.watch(effectiveComparisonOverlayTypeProvider);
  switch (selected) {
    case ComparisonOverlayType.cpi:
      final points = await ref.watch(cpiDataProvider.future);
      return _rebaseTo100(
          points.map((point) => (point.month, point.index)).toList());
    case ComparisonOverlayType.moneySupply:
      final points = await ref.watch(moneySupplyDataProvider.future);
      return _rebaseTo100(
          points.map((point) => (point.month, point.value)).toList());
    case null:
      return [];
  }
}

List<ComparisonDataPoint> _rebaseTo100(List<(DateTime, double)> points) {
  if (points.isEmpty) return const [];

  final sorted = [...points]..sort((a, b) => a.$1.compareTo(b.$1));
  final base = sorted.first.$2;
  if (!base.isFinite || base == 0) return const [];

  return sorted
      .map(
        (point) => ComparisonDataPoint(
          month: point.$1,
          index: (point.$2 / base) * 100,
        ),
      )
      .toList();
}

@riverpod
class SelectedComparisonOverlayType extends _$SelectedComparisonOverlayType {
  @override
  ComparisonOverlayType build() => ComparisonOverlayType.cpi;

  void set(ComparisonOverlayType value) => state = value;
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
