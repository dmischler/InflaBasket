import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/utils/inflation_calculator.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

enum ProductDetailRange { oneMonth, threeMonths, sixMonths, oneYear, all }

extension ProductDetailRangeX on ProductDetailRange {
  DateTime startDate(DateTime firstDataPoint) {
    final now = DateTime.now();
    final candidate = switch (this) {
      ProductDetailRange.oneMonth => DateTime(now.year, now.month - 1, 1),
      ProductDetailRange.threeMonths => DateTime(now.year, now.month - 3, 1),
      ProductDetailRange.sixMonths => DateTime(now.year, now.month - 6, 1),
      ProductDetailRange.oneYear => DateTime(now.year - 1, now.month, 1),
      ProductDetailRange.all => firstDataPoint,
    };
    return candidate.isBefore(firstDataPoint) ? firstDataPoint : candidate;
  }
}

class ProductDetailFacts {
  const ProductDetailFacts({
    required this.entryCount,
    required this.firstPurchase,
    required this.latestPurchase,
    required this.canonicalStore,
  });

  final int entryCount;
  final DateTime? firstPurchase;
  final DateTime? latestPurchase;
  final String canonicalStore;
}

class ProductPricePoint {
  const ProductPricePoint({
    required this.date,
    required this.value,
    required this.entry,
    this.isSynthetic = false,
  });

  final DateTime date;
  final double value;
  final EntryWithDetails entry;
  final bool isSynthetic;
}

class ProductInflationResult {
  const ProductInflationResult({
    required this.inflationPercent,
    required this.isPartialPeriod,
    required this.startDate,
    required this.endDate,
  });

  final double inflationPercent;
  final bool isPartialPeriod;
  final DateTime startDate;
  final DateTime endDate;
}

final productWithCategoryProvider =
    StreamProvider.autoDispose.family<ProductWithCategory?, int>(
  (ref, productId) {
    final repo = ref.watch(entryRepositoryProvider);
    return repo.watchProductWithCategory(productId);
  },
);

final productEntriesProvider =
    StreamProvider.autoDispose.family<List<EntryWithDetails>, int>(
  (ref, productId) {
    final repo = ref.watch(entryRepositoryProvider);
    return repo.watchEntriesWithDetailsForProduct(productId);
  },
);

class ProductDetailController extends StateNotifier<AsyncValue<void>> {
  ProductDetailController(this._ref, this._productId)
      : super(const AsyncData(null));

  final Ref _ref;
  final int _productId;

  Future<void> saveDetails({
    required String productName,
    required int categoryId,
    required String storeName,
  }) async {
    state = const AsyncLoading();
    try {
      await _ref.read(entryRepositoryProvider).updateProductDetailFields(
            productId: _productId,
            name: productName.trim(),
            categoryId: categoryId,
            storeName: storeName.trim(),
          );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteEntry(int entryId) async {
    state = const AsyncLoading();
    try {
      await _ref.read(entryRepositoryProvider).deletePurchaseEntry(entryId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteProduct() async {
    state = const AsyncLoading();
    try {
      await _ref.read(entryRepositoryProvider).deleteProductAndRelatedData(
            _productId,
          );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final productDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<ProductDetailController, AsyncValue<void>, int>(
  (ref, productId) => ProductDetailController(ref, productId),
);

double normalizedUnitPrice(PurchaseEntry entry) {
  final price = entry.price;
  final quantity = entry.quantity;
  if (!price.isFinite || !quantity.isFinite || quantity <= 0 || price <= 0) {
    return 0;
  }
  return unitTypeFromString(entry.unit).normalizedPrice(price, quantity);
}

ProductDetailFacts buildProductDetailFacts(
  List<EntryWithDetails> entries,
  Product product,
) {
  if (entries.isEmpty) {
    return ProductDetailFacts(
      entryCount: 0,
      firstPurchase: null,
      latestPurchase: null,
      canonicalStore: product.storeName ?? '',
    );
  }

  final sorted = List<EntryWithDetails>.from(entries)
    ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));

  return ProductDetailFacts(
    entryCount: entries.length,
    firstPurchase: sorted.first.entry.purchaseDate,
    latestPurchase: sorted.last.entry.purchaseDate,
    canonicalStore: product.storeName ?? '',
  );
}

ProductInflationResult? buildProductInflation({
  required List<EntryWithDetails> entries,
  required Product product,
  required ProductDetailRange range,
  required bool isBitcoinMode,
  Map<String, double> btcPriceCache = const {},
}) {
  if (entries.isEmpty) return null;

  final tracked = isBitcoinMode
      ? _buildTrackedProductInSats(entries, product, btcPriceCache)
      : _buildTrackedProductInFiat(entries, product);

  if (tracked.priceHistory.isEmpty) return null;

  final first = tracked.priceHistory.first.date;
  final start = range.startDate(first);
  final end = DateTime.now();
  final inflationPct =
      InflationCalculator.productPercentChange(tracked, start, end);
  if (inflationPct == null) return null;

  final hasBaseline = tracked.priceHistory.any((e) => !e.date.isAfter(start));

  return ProductInflationResult(
    inflationPercent: inflationPct,
    isPartialPeriod: !hasBaseline,
    startDate: start,
    endDate: end,
  );
}

List<ProductPricePoint> buildProductPricePoints({
  required List<EntryWithDetails> entries,
  required Product product,
  required ProductDetailRange range,
  required bool isBitcoinMode,
  Map<String, double> btcPriceCache = const {},
}) {
  if (entries.isEmpty) return const [];

  final tracked = isBitcoinMode
      ? _buildTrackedProductInSats(entries, product, btcPriceCache)
      : _buildTrackedProductInFiat(entries, product);

  if (tracked.priceHistory.isEmpty) return const [];

  final sortedEntries = List<EntryWithDetails>.from(entries)
    ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));
  final first = tracked.priceHistory.first.date;
  final start = range.startDate(first);
  final visible = <ProductPricePoint>[];

  EntryWithDetails? baselineEntry;
  ProductPricePoint? baselinePoint;

  for (final entry in sortedEntries) {
    if (!entry.entry.purchaseDate.isAfter(start)) {
      baselineEntry = entry;
      final value = isBitcoinMode
          ? _normalizedSatsValue(entry, btcPriceCache)
          : normalizedUnitPrice(entry.entry);
      if (value != null && value > 0) {
        baselinePoint = ProductPricePoint(
          date: start,
          value: value.toDouble(),
          entry: entry,
          isSynthetic: entry.entry.purchaseDate.isBefore(start),
        );
      }
    }
  }

  if (baselinePoint != null) {
    visible.add(baselinePoint);
  }

  for (final entry in sortedEntries) {
    if (entry.entry.purchaseDate.isBefore(start)) continue;
    final value = isBitcoinMode
        ? _normalizedSatsValue(entry, btcPriceCache)
        : normalizedUnitPrice(entry.entry);
    if (value == null || value <= 0) continue;

    if (visible.isNotEmpty) {
      final previous = visible.last;
      final isDuplicateBaseline = previous.isSynthetic == false &&
          previous.date.year == entry.entry.purchaseDate.year &&
          previous.date.month == entry.entry.purchaseDate.month &&
          previous.date.day == entry.entry.purchaseDate.day;
      if (isDuplicateBaseline) {
        visible.removeLast();
      }
    }

    visible.add(ProductPricePoint(
      date: entry.entry.purchaseDate,
      value: value.toDouble(),
      entry: entry,
    ));
  }

  if (visible.isEmpty && baselineEntry != null) {
    final value = isBitcoinMode
        ? _normalizedSatsValue(baselineEntry, btcPriceCache)
        : normalizedUnitPrice(baselineEntry.entry);
    if (value != null && value > 0) {
      visible.add(ProductPricePoint(
        date: start,
        value: value.toDouble(),
        entry: baselineEntry,
      ));
    }
  }

  return visible;
}

TrackedProduct _buildTrackedProductInFiat(
  List<EntryWithDetails> entries,
  Product product,
) {
  final sortedEntries = List<EntryWithDetails>.from(entries)
    ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));

  return TrackedProduct(
    name: product.name,
    isActive: true,
    priceHistory: sortedEntries
        .map(
          (entry) => PriceEntry(
            date: entry.entry.purchaseDate,
            price: normalizedUnitPrice(entry.entry),
          ),
        )
        .where((entry) => entry.price > 0 && entry.price.isFinite)
        .toList(),
  );
}

TrackedProduct _buildTrackedProductInSats(
  List<EntryWithDetails> entries,
  Product product,
  Map<String, double> btcPriceCache,
) {
  final sortedEntries = List<EntryWithDetails>.from(entries)
    ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));

  final history = sortedEntries
      .map((entry) {
        final sats = _normalizedSatsValue(entry, btcPriceCache);
        if (sats == null || sats <= 0) return null;
        return PriceEntry(
          date: entry.entry.purchaseDate,
          price: sats.toDouble(),
        );
      })
      .whereType<PriceEntry>()
      .toList();

  return TrackedProduct(
    name: product.name,
    isActive: true,
    priceHistory: history,
  );
}

int? _normalizedSatsValue(
  EntryWithDetails entry,
  Map<String, double> btcPriceCache,
) {
  final btcPrice = _btcPriceForDate(btcPriceCache, entry.entry.purchaseDate);
  final normalizedFiat = normalizedUnitPrice(entry.entry);
  if (btcPrice == null || btcPrice <= 0 || normalizedFiat <= 0) {
    return null;
  }
  return SatsConverter.fiatToSats(normalizedFiat, btcPrice);
}

int? normalizedSatsValueForEntry(
  EntryWithDetails entry,
  Map<String, double> btcPriceCache,
) {
  return _normalizedSatsValue(entry, btcPriceCache);
}

double? _btcPriceForDate(Map<String, double> cache, DateTime date) {
  return cache['${date.year}-${date.month}'];
}
