import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/core/api/money_supply_client.dart';
import 'package:inflabasket/core/api/snb_client.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'cpi_provider.g.dart';

enum ComparisonOverlayType {
  moneySupply,
  snbCoreInflation,
}

List<ComparisonOverlayType> availableComparisonOverlayTypes(String currency) {
  final available = <ComparisonOverlayType>[];
  if (moneySupplySourceForCurrency(currency) != null) {
    available.add(ComparisonOverlayType.moneySupply);
  }
  // SNB Core Inflation 1 is available for CHF
  if (currency.toUpperCase() == 'CHF') {
    available.add(ComparisonOverlayType.snbCoreInflation);
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

const _freshCurrentMonthCacheTtl = Duration(days: 1);
const _historicalCacheTtl = Duration(days: 30);

@visibleForTesting
ComparisonRequestWindow comparisonWindowForHistory(List<MonthlyIndex> history) {
  final validHistory = history.where((item) => item.index.isFinite).toList();
  if (validHistory.length < 2) {
    final now = DateTime.now();
    return ComparisonRequestWindow(
      startMonth: DateTime(now.year - 2, now.month),
      observationCount: 24,
    );
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

@visibleForTesting
List<ComparisonDataPoint> rebaseComparisonSeries(
    List<(DateTime, double)> points) {
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

ComparisonRequestWindow _comparisonWindow(List<MonthlyIndex> history) {
  return comparisonWindowForHistory(history);
}

@riverpod
SnbClient snbClient(SnbClientRef ref) =>
    SnbClient(Dio(BaseOptions(headers: {'User-Agent': 'InflaBasket/1.0'})));

@riverpod
MoneySupplyClient moneySupplyClient(MoneySupplyClientRef ref) =>
    MoneySupplyClient(
      Dio(BaseOptions(headers: {'User-Agent': 'InflaBasket/1.0'})),
    );

@riverpod
Future<List<MoneySupplyDataPoint>> moneySupplyData(
    MoneySupplyDataRef ref) async {
  final currency = ref.watch(settingsControllerProvider).currency;
  final window = _comparisonWindow(ref.watch(basketIndexHistoryProvider));
  final source = moneySupplySourceForCurrency(currency);
  if (source == null) return [];

  final repo = ref.read(entryRepositoryProvider);
  final client = ref.read(moneySupplyClientProvider);
  return _loadCachedSeries<MoneySupplyDataPoint>(
    repo: repo,
    sourceKey: source.name,
    currency: currency,
    metric: EntryRepository.metricMoneySupplyM2,
    startMonth: window.startMonth,
    fetchLive: () => client.fetchMoneySupply(
      source,
      startMonth: window.startMonth,
      observationCount: window.observationCount,
    ),
    toPairs: (points) =>
        points.map((point) => (point.month, point.value)).toList(),
    fromCache: (rows) => rows
        .map<MoneySupplyDataPoint>(
          (ExternalSeriesCacheEntry row) =>
              MoneySupplyDataPoint(month: row.month, value: row.value),
        )
        .toList(),
  );
}

@riverpod
Future<List<CpiDataPoint>> snbCoreInflationData(
    SnbCoreInflationDataRef ref) async {
  final currency = ref.watch(settingsControllerProvider).currency;
  final window = _comparisonWindow(ref.watch(basketIndexHistoryProvider));

  if (currency.toUpperCase() != 'CHF') {
    return []; // Only available for CHF
  }

  final repo = ref.read(entryRepositoryProvider);
  final client = ref.read(snbClientProvider);
  return _loadCachedSeries<CpiDataPoint>(
    repo: repo,
    sourceKey: 'snb_core_inflation_1',
    currency: currency,
    metric: EntryRepository.metricSnbCoreInflation1,
    startMonth: window.startMonth,
    fetchLive: () => client.fetchCoreInflation1(
      startMonth: window.startMonth,
      observationCount: window.observationCount,
    ),
    toPairs: (points) =>
        points.map((point) => (point.month, point.index)).toList(),
    fromCache: (rows) => rows
        .map<CpiDataPoint>(
          (ExternalSeriesCacheEntry row) =>
              CpiDataPoint(month: row.month, index: row.value),
        )
        .toList(),
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
  if (selected == null) return [];

  // Use the actual inflation range baseline for proper alignment
  final range = ref.watch(activeInflationRangeProvider);
  final baselineDate = range.start;
  final endDate = range.end;

  // Get raw M2/inflation data
  List<(DateTime, double)> rawPoints = [];
  switch (selected) {
    case ComparisonOverlayType.moneySupply:
      final points = await ref.watch(moneySupplyDataProvider.future);
      rawPoints = points.map((p) => (p.month, p.value)).toList();
    case ComparisonOverlayType.snbCoreInflation:
      final points = await ref.watch(snbCoreInflationDataProvider.future);
      rawPoints = points.map((p) => (p.month, p.index)).toList();
  }

  if (rawPoints.isEmpty) return [];

  // Sort by date
  final sorted = [...rawPoints]..sort((a, b) => a.$1.compareTo(b.$1));

  // Find the baseline value at or immediately before baselineDate
  // This ensures both curves start at index 100 at the same date
  double? baselineValue;
  for (final point in sorted) {
    if (!point.$1.isAfter(baselineDate)) {
      baselineValue = point.$2;
    }
  }

  // If no baseline value found before/at baselineDate, use the first available
  if (baselineValue == null && sorted.isNotEmpty) {
    baselineValue = sorted.first.$2;
  }

  if (baselineValue == null || !baselineValue.isFinite || baselineValue == 0) {
    return [];
  }

  // Filter to the date range and rebase using the found baseline
  final filtered = sorted
      .where((p) => !p.$1.isBefore(baselineDate) && !p.$1.isAfter(endDate))
      .toList();

  return filtered
      .map((point) => ComparisonDataPoint(
            month: point.$1,
            index: (point.$2 / baselineValue!) * 100,
          ))
      .toList();
}

Future<List<T>> _loadCachedSeries<T>({
  required EntryRepository repo,
  required String sourceKey,
  required String currency,
  required String metric,
  required DateTime startMonth,
  required Future<List<T>> Function() fetchLive,
  required List<(DateTime, double)> Function(List<T> values) toPairs,
  required List<T> Function(List<ExternalSeriesCacheEntry> rows) fromCache,
}) async {
  final cachedRows = await repo.getExternalSeriesCache(
    source: sourceKey,
    currency: currency,
    metric: metric,
    startMonth: startMonth,
  );

  final isCacheFresh = cachedRows.isNotEmpty && _isCacheFresh(cachedRows);
  final cacheCoversRange =
      cachedRows.isNotEmpty && !cachedRows.first.month.isAfter(startMonth);

  if (isCacheFresh && cacheCoversRange) {
    return fromCache(cachedRows);
  }

  final live = await fetchLive();
  if (live.isNotEmpty) {
    await repo.replaceExternalSeriesCache(
      source: sourceKey,
      currency: currency,
      metric: metric,
      points: toPairs(live),
    );
    return live;
  }

  return fromCache(cachedRows);
}

bool _isCacheFresh(List<ExternalSeriesCacheEntry> rows) {
  return isExternalSeriesCacheFresh(rows);
}

@visibleForTesting
bool isExternalSeriesCacheFresh(List<ExternalSeriesCacheEntry> rows) {
  if (rows.isEmpty) return false;
  final fetchedAt = rows.first.fetchedAt;
  final latestMonth = rows.last.month;
  final now = DateTime.now();
  final hasCurrentMonth =
      latestMonth.year == now.year && latestMonth.month == now.month;
  final ttl =
      hasCurrentMonth ? _freshCurrentMonthCacheTtl : _historicalCacheTtl;
  return now.difference(fetchedAt) <= ttl;
}

@riverpod
class SelectedComparisonOverlayType extends _$SelectedComparisonOverlayType {
  @override
  ComparisonOverlayType build() => ComparisonOverlayType.moneySupply;

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
