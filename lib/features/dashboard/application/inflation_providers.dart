import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/api/bitcoin_price_client.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/utils/inflation_calculator.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

export 'package:inflabasket/features/entry_management/application/entry_providers.dart'
    show
        ChartTimeRange,
        ChartTimeFilter,
        monthsBetween,
        availableTimeRanges,
        chartTimeFilterControllerProvider;

part 'inflation_providers.g.dart';

class InflationRange {
  const InflationRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class ItemInflation {
  ItemInflation({
    required this.product,
    required this.category,
    required this.baseUnitPrice,
    required this.currentUnitPrice,
    required this.baseUnit,
    required this.inflationPercent,
    this.isPartialPeriod = false,
    this.baseDate,
  });

  final Product product;
  final Category category;
  final double baseUnitPrice;
  final double currentUnitPrice;
  final UnitType baseUnit;
  final double inflationPercent;
  final bool isPartialPeriod;
  final DateTime? baseDate;
}

class ItemInflationSats {
  ItemInflationSats({
    required this.product,
    required this.category,
    required this.baseSatsPrice,
    required this.currentSatsPrice,
    required this.baseUnit,
    required this.inflationPercent,
    required this.btcPriceAtBase,
    required this.btcPriceAtCurrent,
    this.isPartialPeriod = false,
  });

  final Product product;
  final Category category;
  final int baseSatsPrice;
  final int currentSatsPrice;
  final UnitType baseUnit;
  final double inflationPercent;
  final double btcPriceAtBase;
  final double btcPriceAtCurrent;
  final bool isPartialPeriod;
}

class CategoryInflation {
  CategoryInflation({
    required this.category,
    required this.inflationPercent,
    required this.totalSpend,
  });

  final Category category;
  final double inflationPercent;
  final double totalSpend;
}

class MonthlyIndex {
  MonthlyIndex({required this.month, required this.index, this.chartPoint});

  final DateTime month;
  final double index;
  final ChartPoint? chartPoint;
}

class YearlyInflationSummary {
  const YearlyInflationSummary({
    required this.yearlyInflationPercent,
    required this.qualifyingProducts,
  });

  const YearlyInflationSummary.empty()
      : yearlyInflationPercent = 0,
        qualifyingProducts = 0;

  final double yearlyInflationPercent;
  final int qualifyingProducts;
}

double _normalizedUnitPrice(PurchaseEntry e) {
  final price = e.price;
  final quantity = e.quantity;
  if (!price.isFinite || !quantity.isFinite || quantity <= 0 || price <= 0) {
    return 0;
  }
  return unitTypeFromString(e.unit).normalizedPrice(price, quantity);
}

bool _compatible(PurchaseEntry a, PurchaseEntry b) {
  return unitTypeFromString(a.unit).compatibleWith(unitTypeFromString(b.unit));
}

double _yearsBetween(DateTime start, DateTime end) {
  final diffMs = end.difference(start).inMilliseconds;
  if (diffMs <= 0) return 0;
  return diffMs / Duration.millisecondsPerDay / 365.25;
}

@riverpod
BtcPriceClient btcPriceClient(BtcPriceClientRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return BtcPriceClient(db: db);
}

@riverpod
Future<Map<String, double>> btcPriceCache(BtcPriceCacheRef ref) async {
  final client = ref.watch(btcPriceClientProvider);
  final settings = ref.watch(settingsControllerProvider);
  var map = await client.getCachedPriceMap(settings.currency);
  if (map.isEmpty) {
    final now = DateTime.now();
    final startDate = DateTime(now.year - 10, 1, 1);
    await client.fetchBtcPriceRange(settings.currency, startDate, now);
    map = await client.getCachedPriceMap(settings.currency);
  }
  return map;
}

@riverpod
InflationRange activeInflationRange(ActiveInflationRangeRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  final filter = ref.watch(chartTimeFilterControllerProvider);
  if (entries.isEmpty) {
    final now = DateTime.now();
    return InflationRange(start: now, end: now);
  }

  final sorted = List<EntryWithDetails>.from(entries)
    ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
  final first = sorted.first.entry.purchaseDate;
  final availableRanges = availableTimeRanges(sorted);
  final resolvedRange = resolveTimeRangeSelection(filter, availableRanges);
  final effectiveFilter = resolvedRange == filter.range
      ? filter
      : filter.copyWith(range: resolvedRange);
  final start = effectiveFilter.getStartDate(first) ?? first;
  final end = effectiveFilter.getEndDate();
  return InflationRange(start: start, end: end);
}

@riverpod
List<EntryWithDetails> entriesInActiveRange(EntriesInActiveRangeRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return const [];

  final range = ref.watch(activeInflationRangeProvider);
  return entries
      .where((entry) =>
          !entry.entry.purchaseDate.isBefore(range.start) &&
          !entry.entry.purchaseDate.isAfter(range.end))
      .toList();
}

class YearlyInflationEntry {
  YearlyInflationEntry({
    required this.product,
    required this.category,
    required this.baselineEntry,
    required this.currentEntry,
  });

  final Product product;
  final Category category;
  final EntryWithDetails baselineEntry;
  final EntryWithDetails currentEntry;
}

@riverpod
List<YearlyInflationEntry> entriesForYearlyInflation(
    EntriesForYearlyInflationRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];

  final range = ref.watch(activeInflationRangeProvider);
  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final result = <YearlyInflationEntry>[];

  for (final productEntries in grouped.values) {
    final inRange = productEntries
        .where((e) =>
            !e.entry.purchaseDate.isBefore(range.start) &&
            !e.entry.purchaseDate.isAfter(range.end))
        .toList()
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));

    if (inRange.length < 2) continue;

    final baseline = inRange.first;
    final current = inRange.last;

    if (baseline.entry.purchaseDate == current.entry.purchaseDate) continue;
    if (!_compatible(baseline.entry, current.entry)) continue;

    result.add(YearlyInflationEntry(
      product: baseline.product,
      category: baseline.category,
      baselineEntry: baseline,
      currentEntry: current,
    ));
  }

  return result;
}

@riverpod
List<TrackedProduct> trackedProducts(TrackedProductsRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return const [];

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final products = <TrackedProduct>[];
  for (final productEntries in grouped.values) {
    final first = productEntries.first;
    final priceHistory = productEntries
        .map((e) => PriceEntry(
              date: e.entry.purchaseDate,
              price: _normalizedUnitPrice(e.entry),
            ))
        .where((e) => e.price > 0 && e.price.isFinite)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (priceHistory.length < 2) continue;
    if (priceHistory.first.date == priceHistory.last.date) continue;

    products.add(TrackedProduct(
      name: first.product.name,
      isActive: true,
      priceHistory: priceHistory,
    ));
  }

  return products;
}

@riverpod
List<MonthlyIndex> basketIndexHistory(BasketIndexHistoryRef ref) {
  final range = ref.watch(activeInflationRangeProvider);
  final products = ref.watch(trackedProductsProvider);
  if (products.isEmpty) return [];

  final baseline = range.start;
  final endDate = range.end;

  final points =
      InflationCalculator.generateInflationChart(baseline, endDate, products);
  return points
      .map((p) => MonthlyIndex(
            month: p.date,
            index: 100 + p.inflationPct,
            chartPoint: p,
          ))
      .toList();
}

@riverpod
List<MonthlyIndex> filteredBasketIndexHistory(
    FilteredBasketIndexHistoryRef ref) {
  final all = ref.watch(basketIndexHistoryProvider);
  if (all.isEmpty) return [];

  final range = ref.watch(activeInflationRangeProvider);
  return all
      .where(
          (p) => !p.month.isBefore(range.start) && !p.month.isAfter(range.end))
      .toList();
}

@riverpod
double basketInflation(BasketInflationRef ref) {
  final range = ref.watch(activeInflationRangeProvider);
  final products = ref.watch(trackedProductsProvider);
  return InflationCalculator.overallInflationPercent(
        range.start,
        range.end,
        products,
      ) ??
      0.0;
}

@riverpod
YearlyInflationSummary overallYearlyInflationSummary(
    OverallYearlyInflationSummaryRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return const YearlyInflationSummary.empty();

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final yearlyRates = <double>[];

  for (final productEntries in grouped.values) {
    final sorted = List<EntryWithDetails>.from(productEntries)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    if (sorted.length < 2) continue;

    final base = sorted.first;
    final current = sorted.last;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final basePrice = _normalizedUnitPrice(base.entry);
    final currentPrice = _normalizedUnitPrice(current.entry);
    if (basePrice <= 0 || !basePrice.isFinite || !currentPrice.isFinite) {
      continue;
    }

    final years =
        _yearsBetween(base.entry.purchaseDate, current.entry.purchaseDate);
    if (years <= 0) continue;

    final totalInflationPct = ((currentPrice - basePrice) / basePrice) * 100;
    yearlyRates.add(totalInflationPct / years);
  }

  if (yearlyRates.isEmpty) return const YearlyInflationSummary.empty();
  return YearlyInflationSummary(
    yearlyInflationPercent: yearlyRates.average,
    qualifyingProducts: yearlyRates.length,
  );
}

@riverpod
YearlyInflationSummary yearlyBasketInflationSummary(
    YearlyBasketInflationSummaryRef ref) {
  final entries = ref.watch(entriesForYearlyInflationProvider);
  if (entries.isEmpty) return const YearlyInflationSummary.empty();

  final yearlyRates = <double>[];

  for (final entry in entries) {
    final base = entry.baselineEntry;
    final current = entry.currentEntry;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final basePrice = _normalizedUnitPrice(base.entry);
    final currentPrice = _normalizedUnitPrice(current.entry);
    if (basePrice <= 0 || !basePrice.isFinite || !currentPrice.isFinite) {
      continue;
    }

    final years =
        _yearsBetween(base.entry.purchaseDate, current.entry.purchaseDate);
    if (years <= 0) continue;

    final totalInflationPct = ((currentPrice - basePrice) / basePrice) * 100;
    yearlyRates.add(totalInflationPct / years);
  }

  if (yearlyRates.isEmpty) return const YearlyInflationSummary.empty();
  return YearlyInflationSummary(
    yearlyInflationPercent: yearlyRates.average,
    qualifyingProducts: yearlyRates.length,
  );
}

@riverpod
List<ItemInflation> overallItemInflationList(OverallItemInflationListRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final result = <ItemInflation>[];

  for (final list in grouped.values) {
    final sorted = List<EntryWithDetails>.from(list)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    if (sorted.length < 2) continue;

    final first = sorted.first;
    final base = sorted.first;
    final current = sorted.last;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final basePrice = _normalizedUnitPrice(base.entry);
    final currentPrice = _normalizedUnitPrice(current.entry);
    if (basePrice <= 0 || !basePrice.isFinite || !currentPrice.isFinite) {
      continue;
    }

    final inflationPct = (base == current)
        ? 0.0
        : ((currentPrice - basePrice) / basePrice) * 100;

    result.add(ItemInflation(
      product: first.product,
      category: first.category,
      baseUnitPrice: basePrice,
      currentUnitPrice: currentPrice,
      baseUnit: unitTypeFromString(base.entry.unit),
      inflationPercent: inflationPct,
      isPartialPeriod: false,
      baseDate: base.entry.purchaseDate,
    ));
  }

  result.sort((a, b) => b.inflationPercent.compareTo(a.inflationPercent));
  return result;
}

@riverpod
List<ItemInflation> itemInflationList(ItemInflationListRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final result = <ItemInflation>[];

  for (final list in grouped.values) {
    final sorted = List<EntryWithDetails>.from(list)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    if (sorted.length < 2) continue;

    final first = sorted.first;
    final base = sorted.first;
    final current = sorted.last;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final basePrice = _normalizedUnitPrice(base.entry);
    final currentPrice = _normalizedUnitPrice(current.entry);
    if (basePrice <= 0 || !basePrice.isFinite || !currentPrice.isFinite) {
      continue;
    }

    final inflationPct = (base == current)
        ? 0.0
        : ((currentPrice - basePrice) / basePrice) * 100;

    result.add(ItemInflation(
      product: first.product,
      category: first.category,
      baseUnitPrice: basePrice,
      currentUnitPrice: currentPrice,
      baseUnit: unitTypeFromString(base.entry.unit),
      inflationPercent: inflationPct,
      isPartialPeriod: false,
      baseDate: base.entry.purchaseDate,
    ));
  }

  result.sort((a, b) => b.inflationPercent.compareTo(a.inflationPercent));
  return result;
}

@riverpod
List<CategoryInflation> categoryInflationList(CategoryInflationListRef ref) {
  final items = ref.watch(itemInflationListProvider);
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (items.isEmpty || entries.isEmpty) return [];

  final spendByProduct = <int, double>{};
  for (final e in entries) {
    spendByProduct[e.product.id] =
        (spendByProduct[e.product.id] ?? 0) + e.entry.price;
  }

  final grouped = groupBy<ItemInflation, int>(items, (i) => i.category.id);
  final out = <CategoryInflation>[];
  for (final group in grouped.values) {
    final category = group.first.category;
    var spend = 0.0;
    var weighted = 0.0;
    for (final i in group) {
      final s = spendByProduct[i.product.id] ?? 0;
      spend += s;
      weighted += i.inflationPercent * (s <= 0 ? 1 : s);
    }
    final denom = spend <= 0 ? group.length.toDouble() : spend;
    out.add(CategoryInflation(
      category: category,
      inflationPercent: denom > 0 ? weighted / denom : 0,
      totalSpend: spend,
    ));
  }

  out.sort((a, b) => b.inflationPercent.compareTo(a.inflationPercent));
  return out;
}

double? _getBtcPriceForDate(Map<String, double> cache, DateTime date) {
  final key = '${date.year}-${date.month}';
  return cache[key];
}

@riverpod
Future<List<ItemInflationSats>> overallItemInflationListSats(
    OverallItemInflationListSatsRef ref) async {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];
  final btc = await ref.watch(btcPriceCacheProvider.future);

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final out = <ItemInflationSats>[];
  for (final list in grouped.values) {
    final sorted = List<EntryWithDetails>.from(list)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    if (sorted.length < 2) continue;

    final first = sorted.first;

    final base = sorted.first;
    final current = sorted.last;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final baseBtc = _getBtcPriceForDate(btc, base.entry.purchaseDate);
    final currentBtc = _getBtcPriceForDate(btc, current.entry.purchaseDate);
    if (baseBtc == null ||
        currentBtc == null ||
        baseBtc <= 0 ||
        currentBtc <= 0) {
      continue;
    }

    final baseNorm = _normalizedUnitPrice(base.entry);
    final currentNorm = _normalizedUnitPrice(current.entry);
    if (baseNorm <= 0 || !baseNorm.isFinite || !currentNorm.isFinite) continue;

    final baseSats = SatsConverter.fiatToSats(baseNorm, baseBtc);
    final currentSats = SatsConverter.fiatToSats(currentNorm, currentBtc);
    if (baseSats <= 0) continue;

    final inflationPct =
        (base == current) ? 0.0 : ((currentSats - baseSats) / baseSats) * 100;

    out.add(ItemInflationSats(
      product: first.product,
      category: first.category,
      baseSatsPrice: baseSats,
      currentSatsPrice: currentSats,
      baseUnit: unitTypeFromString(base.entry.unit),
      inflationPercent: inflationPct,
      btcPriceAtBase: baseBtc,
      btcPriceAtCurrent: currentBtc,
      isPartialPeriod: false,
    ));
  }

  out.sort((a, b) => b.inflationPercent.compareTo(a.inflationPercent));
  return out;
}

@riverpod
Future<List<ItemInflationSats>> itemInflationListSats(
    ItemInflationListSatsRef ref) async {
  final entries = ref.watch(entriesInActiveRangeProvider);
  if (entries.isEmpty) return [];
  final btc = await ref.watch(btcPriceCacheProvider.future);

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final out = <ItemInflationSats>[];
  for (final list in grouped.values) {
    final sorted = List<EntryWithDetails>.from(list)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    if (sorted.length < 2) continue;

    final first = sorted.first;

    final base = sorted.first;
    final current = sorted.last;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final baseBtc = _getBtcPriceForDate(btc, base.entry.purchaseDate);
    final currentBtc = _getBtcPriceForDate(btc, current.entry.purchaseDate);
    if (baseBtc == null ||
        currentBtc == null ||
        baseBtc <= 0 ||
        currentBtc <= 0) {
      continue;
    }

    final baseNorm = _normalizedUnitPrice(base.entry);
    final currentNorm = _normalizedUnitPrice(current.entry);
    if (baseNorm <= 0 || !baseNorm.isFinite || !currentNorm.isFinite) continue;

    final baseSats = SatsConverter.fiatToSats(baseNorm, baseBtc);
    final currentSats = SatsConverter.fiatToSats(currentNorm, currentBtc);
    if (baseSats <= 0) continue;

    final inflationPct =
        (base == current) ? 0.0 : ((currentSats - baseSats) / baseSats) * 100;

    out.add(ItemInflationSats(
      product: first.product,
      category: first.category,
      baseSatsPrice: baseSats,
      currentSatsPrice: currentSats,
      baseUnit: unitTypeFromString(base.entry.unit),
      inflationPercent: inflationPct,
      btcPriceAtBase: baseBtc,
      btcPriceAtCurrent: currentBtc,
      isPartialPeriod: false,
    ));
  }

  out.sort((a, b) => b.inflationPercent.compareTo(a.inflationPercent));
  return out;
}

@riverpod
double basketInflationSats(BasketInflationSatsRef ref) {
  final items = ref.watch(itemInflationListSatsProvider).valueOrNull ?? [];
  if (items.isEmpty) return 0.0;
  return items.map((e) => e.inflationPercent).average;
}

@riverpod
Future<YearlyInflationSummary> overallYearlyInflationSummarySats(
    OverallYearlyInflationSummarySatsRef ref) async {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return const YearlyInflationSummary.empty();

  final btc = await ref.watch(btcPriceCacheProvider.future);
  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final yearlyRates = <double>[];

  for (final productEntries in grouped.values) {
    final sorted = List<EntryWithDetails>.from(productEntries)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    if (sorted.length < 2) continue;

    final base = sorted.first;
    final current = sorted.last;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final baseBtc = _getBtcPriceForDate(btc, base.entry.purchaseDate);
    final currentBtc = _getBtcPriceForDate(btc, current.entry.purchaseDate);
    if (baseBtc == null ||
        currentBtc == null ||
        baseBtc <= 0 ||
        currentBtc <= 0) {
      continue;
    }

    final baseNorm = _normalizedUnitPrice(base.entry);
    final currentNorm = _normalizedUnitPrice(current.entry);
    if (baseNorm <= 0 || !baseNorm.isFinite || !currentNorm.isFinite) {
      continue;
    }

    final baseSats = SatsConverter.fiatToSats(baseNorm, baseBtc);
    final currentSats = SatsConverter.fiatToSats(currentNorm, currentBtc);
    if (baseSats <= 0) continue;

    final years =
        _yearsBetween(base.entry.purchaseDate, current.entry.purchaseDate);
    if (years <= 0) continue;

    final totalInflationPct = ((currentSats - baseSats) / baseSats) * 100;
    yearlyRates.add(totalInflationPct / years);
  }

  if (yearlyRates.isEmpty) return const YearlyInflationSummary.empty();
  return YearlyInflationSummary(
    yearlyInflationPercent: yearlyRates.average,
    qualifyingProducts: yearlyRates.length,
  );
}

@riverpod
Future<YearlyInflationSummary> yearlyBasketInflationSummarySats(
    YearlyBasketInflationSummarySatsRef ref) async {
  final entries = ref.watch(entriesForYearlyInflationProvider);
  if (entries.isEmpty) return const YearlyInflationSummary.empty();

  final btc = await ref.watch(btcPriceCacheProvider.future);
  final yearlyRates = <double>[];

  for (final entry in entries) {
    final base = entry.baselineEntry;
    final current = entry.currentEntry;

    if (base.entry.purchaseDate == current.entry.purchaseDate ||
        !_compatible(base.entry, current.entry)) {
      continue;
    }

    final baseBtc = _getBtcPriceForDate(btc, base.entry.purchaseDate);
    final currentBtc = _getBtcPriceForDate(btc, current.entry.purchaseDate);
    if (baseBtc == null ||
        currentBtc == null ||
        baseBtc <= 0 ||
        currentBtc <= 0) {
      continue;
    }

    final baseNorm = _normalizedUnitPrice(base.entry);
    final currentNorm = _normalizedUnitPrice(current.entry);
    if (baseNorm <= 0 || !baseNorm.isFinite || !currentNorm.isFinite) {
      continue;
    }

    final baseSats = SatsConverter.fiatToSats(baseNorm, baseBtc);
    final currentSats = SatsConverter.fiatToSats(currentNorm, currentBtc);
    if (baseSats <= 0) continue;

    final years =
        _yearsBetween(base.entry.purchaseDate, current.entry.purchaseDate);
    if (years <= 0) continue;

    final totalInflationPct = ((currentSats - baseSats) / baseSats) * 100;
    yearlyRates.add(totalInflationPct / years);
  }

  if (yearlyRates.isEmpty) return const YearlyInflationSummary.empty();
  return YearlyInflationSummary(
    yearlyInflationPercent: yearlyRates.average,
    qualifyingProducts: yearlyRates.length,
  );
}

@riverpod
Future<List<MonthlyIndex>> dynamicLaspeyresIndexSats(
    DynamicLaspeyresIndexSatsRef ref) async {
  final isBitcoin = ref.watch(isBitcoinModeProvider);
  if (!isBitcoin) return [];

  final range = ref.watch(activeInflationRangeProvider);
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];
  final btc = await ref.watch(btcPriceCacheProvider.future);

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final products = <TrackedProduct>[];
  for (final list in grouped.values) {
    final first = list.first;
    final history = list
        .map((e) {
          final btcPrice = _getBtcPriceForDate(btc, e.entry.purchaseDate);
          if (btcPrice == null || btcPrice <= 0) return null;
          final norm = _normalizedUnitPrice(e.entry);
          if (norm <= 0) return null;
          return PriceEntry(
            date: e.entry.purchaseDate,
            price: SatsConverter.fiatToSats(norm, btcPrice).toDouble(),
          );
        })
        .whereType<PriceEntry>()
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (history.length < 2) continue;
    if (history.first.date == history.last.date) continue;

    products.add(TrackedProduct(
        name: first.product.name, isActive: true, priceHistory: history));
  }

  if (products.isEmpty) return [];
  final baseline = range.start;
  final endDate = range.end;
  final points =
      InflationCalculator.generateInflationChart(baseline, endDate, products);
  return points
      .map((p) => MonthlyIndex(
          month: p.date, index: 100 + p.inflationPct, chartPoint: p))
      .toList();
}

@riverpod
Future<List<MonthlyIndex>> filteredDynamicIndexSats(
    FilteredDynamicIndexSatsRef ref) async {
  final isBitcoin = ref.watch(isBitcoinModeProvider);
  if (!isBitcoin) return [];

  final all = await ref.watch(dynamicLaspeyresIndexSatsProvider.future);
  if (all.isEmpty) return [];

  final range = ref.watch(activeInflationRangeProvider);
  return all
      .where(
          (p) => !p.month.isBefore(range.start) && !p.month.isAfter(range.end))
      .toList();
}

@riverpod
bool isBitcoinMode(IsBitcoinModeRef ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.isBitcoinMode;
}

@riverpod
List<MonthlyIndex> dynamicLaspeyresIndex(DynamicLaspeyresIndexRef ref) {
  return ref.watch(basketIndexHistoryProvider);
}

@riverpod
List<MonthlyIndex> filteredDynamicIndex(FilteredDynamicIndexRef ref) {
  return ref.watch(filteredBasketIndexHistoryProvider);
}
