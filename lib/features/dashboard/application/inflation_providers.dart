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
  final start = filter.getStartDate(first) ?? first;
  final end = filter.getEndDate();
  return InflationRange(start: start, end: end);
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
  final products = ref.watch(trackedProductsProvider);
  if (products.isEmpty) return [];
  final baseline =
      products.expand((p) => p.priceHistory).map((e) => e.date).minOrNull;
  if (baseline == null) return [];
  final now = DateTime.now();
  final points =
      InflationCalculator.generateInflationChart(baseline, now, products);
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
  final filtered = all
      .where(
          (p) => !p.month.isBefore(range.start) && !p.month.isAfter(range.end))
      .toList();
  if (filtered.isEmpty) return [];

  final base = filtered.first.index;
  if (!base.isFinite || base == 0) return filtered;
  return filtered
      .map((p) => MonthlyIndex(
            month: p.month,
            index: (p.index / base) * 100,
            chartPoint: p.chartPoint,
          ))
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
List<ItemInflation> itemInflationList(ItemInflationListRef ref) {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];
  final range = ref.watch(activeInflationRangeProvider);

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final result = <ItemInflation>[];

  for (final list in grouped.values) {
    final sorted = List<EntryWithDetails>.from(list)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    final first = sorted.first;

    var base = sorted.lastWhereOrNull(
      (e) => !e.entry.purchaseDate.isAfter(range.start),
    );
    var isPartialPeriod = false;
    if (base == null) {
      base = sorted.firstWhereOrNull(
        (e) => !e.entry.purchaseDate.isBefore(range.start),
      );
      isPartialPeriod = base != null;
    }

    final current = sorted.lastWhereOrNull(
      (e) => !e.entry.purchaseDate.isAfter(range.end),
    );

    if (base == null ||
        current == null ||
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
      isPartialPeriod: isPartialPeriod,
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
Future<List<ItemInflationSats>> itemInflationListSats(
    ItemInflationListSatsRef ref) async {
  final entries = ref.watch(entriesWithDetailsProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];
  final range = ref.watch(activeInflationRangeProvider);
  final btc = await ref.watch(btcPriceCacheProvider.future);

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final out = <ItemInflationSats>[];
  for (final list in grouped.values) {
    final sorted = List<EntryWithDetails>.from(list)
      ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
    final first = sorted.first;

    var base = sorted.lastWhereOrNull(
      (e) => !e.entry.purchaseDate.isAfter(range.start),
    );
    var isPartialPeriod = false;
    if (base == null) {
      base = sorted.firstWhereOrNull(
        (e) => !e.entry.purchaseDate.isBefore(range.start),
      );
      isPartialPeriod = base != null;
    }

    final current = sorted.lastWhereOrNull(
      (e) => !e.entry.purchaseDate.isAfter(range.end),
    );

    if (base == null ||
        current == null ||
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
      isPartialPeriod: isPartialPeriod,
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
Future<List<MonthlyIndex>> dynamicLaspeyresIndexSats(
    DynamicLaspeyresIndexSatsRef ref) async {
  final isBitcoin = ref.watch(isBitcoinModeProvider);
  if (!isBitcoin) return [];

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
    products.add(TrackedProduct(
        name: first.product.name, isActive: true, priceHistory: history));
  }

  if (products.isEmpty) return [];
  final baseline =
      products.expand((p) => p.priceHistory).map((e) => e.date).minOrNull;
  if (baseline == null) return [];
  final now = DateTime.now();
  final points =
      InflationCalculator.generateInflationChart(baseline, now, products);
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
  final filtered = all
      .where(
          (p) => !p.month.isBefore(range.start) && !p.month.isAfter(range.end))
      .toList();
  if (filtered.isEmpty) return [];

  final base = filtered.first.index;
  if (!base.isFinite || base == 0) return filtered;
  return filtered
      .map((p) => MonthlyIndex(
            month: p.month,
            index: (p.index / base) * 100,
            chartPoint: p.chartPoint,
          ))
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
