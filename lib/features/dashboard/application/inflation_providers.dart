import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/core/database/database.dart';

part 'inflation_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the price normalised to the *base unit* for the given entry.
///
/// Base units: mass → g, volume → ml, count → 1 item.
/// E.g. 2.00 CHF / 500 g  → 0.004 CHF/g
///      3.50 CHF / 1.5 kg → 0.002333… CHF/g
double _normalizedUnitPrice(PurchaseEntry e) {
  final price = e.price;
  final quantity = e.quantity;
  if (price.isNaN || price.isInfinite ||
      quantity.isNaN || quantity.isInfinite ||
      quantity <= 0) return 0;

  final unit = unitTypeFromString(e.unit);
  return unit.normalizedPrice(price, quantity);
}

/// Returns true when two entries for the same product can be meaningfully
/// compared (same physical dimension: both mass, both volume, or both count).
bool _compatible(PurchaseEntry a, PurchaseEntry b) {
  final ua = unitTypeFromString(a.unit);
  final ub = unitTypeFromString(b.unit);
  return ua.compatibleWith(ub);
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class ItemInflation {
  final Product product;
  final Category category;

  /// Per-base-unit price at the earliest entry (CHF/g, CHF/ml, or CHF/item).
  final double baseUnitPrice;

  /// Per-base-unit price at the most recent entry.
  final double currentUnitPrice;

  /// The unit stored on the base entry (used for display).
  final UnitType baseUnit;

  final double inflationPercent;

  ItemInflation({
    required this.product,
    required this.category,
    required this.baseUnitPrice,
    required this.currentUnitPrice,
    required this.baseUnit,
    required this.inflationPercent,
  });

  // Legacy aliases kept so existing UI code compiles without changes.
  double get basePrice => baseUnitPrice;
  double get currentPrice => currentUnitPrice;
}

class CategoryInflation {
  final Category category;
  final double inflationPercent;
  final double totalSpend;

  CategoryInflation({
    required this.category,
    required this.inflationPercent,
    required this.totalSpend,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
List<ItemInflation> itemInflationList(ItemInflationListRef ref) {
  final entries =
      ref.watch(entriesWithDetailsProvider).valueOrNull ?? <EntryWithDetails>[];
  if (entries.isEmpty) return [];

  final grouped = groupBy<EntryWithDetails, int>(entries, (e) => e.product.id);
  final result = <ItemInflation>[];

  for (final productEntries in grouped.values) {
    if (productEntries.length < 2) continue;

    productEntries
        .sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));

    final baseEntry = productEntries.first;

    // Walk forward to find the most recent entry that is unit-compatible with
    // the base entry. This allows g↔kg etc. while skipping incompatible units.
    EntryWithDetails? currentEntry;
    for (int i = productEntries.length - 1; i > 0; i--) {
      if (_compatible(baseEntry.entry, productEntries[i].entry)) {
        currentEntry = productEntries[i];
        break;
      }
    }

    // No compatible pair found — skip this product
    if (currentEntry == null) continue;

    final baseUnitPrice = _normalizedUnitPrice(baseEntry.entry);
    final currentUnitPrice = _normalizedUnitPrice(currentEntry.entry);

    double inflation = 0;
    if (baseUnitPrice > 0) {
      inflation = ((currentUnitPrice - baseUnitPrice) / baseUnitPrice) * 100;
    }

    result.add(ItemInflation(
      product: baseEntry.product,
      category: baseEntry.category,
      baseUnitPrice: baseUnitPrice,
      currentUnitPrice: currentUnitPrice,
      baseUnit: unitTypeFromString(baseEntry.entry.unit),
      inflationPercent: inflation,
    ));
  }

  result.sort((a, b) => b.inflationPercent.compareTo(a.inflationPercent));
  return result;
}

@riverpod
List<CategoryInflation> categoryInflationList(CategoryInflationListRef ref) {
  final itemInflations = ref.watch(itemInflationListProvider);
  final entries =
      ref.watch(entriesWithDetailsProvider).valueOrNull ?? <EntryWithDetails>[];

  if (itemInflations.isEmpty || entries.isEmpty) return [];

  final groupedItems =
      groupBy<ItemInflation, int>(itemInflations, (i) => i.category.id);
  final result = <CategoryInflation>[];

  for (final entry in groupedItems.entries) {
    final items = entry.value;
    final category = items.first.category;

    double categoryTotalSpend = 0;
    double weightedInflationSum = 0;

    for (final item in items) {
      final itemEntries = entries.where((e) => e.product.id == item.product.id);
      final itemSpend =
          itemEntries.fold(0.0, (sum, e) => sum + (e.entry.price));

      categoryTotalSpend += itemSpend;
      weightedInflationSum += (item.inflationPercent * itemSpend);
    }

    double categoryInflation = 0;
    if (categoryTotalSpend > 0) {
      categoryInflation = weightedInflationSum / categoryTotalSpend;
    }

    result.add(CategoryInflation(
      category: category,
      inflationPercent: categoryInflation,
      totalSpend: categoryTotalSpend,
    ));
  }

  result.sort((a, b) => b.inflationPercent.compareTo(a.inflationPercent));
  return result;
}

@riverpod
double basketInflation(BasketInflationRef ref) {
  final categoryInflations = ref.watch(categoryInflationListProvider);
  if (categoryInflations.isEmpty) return 0.0;

  double totalSpend = 0;
  double weightedInflationSum = 0;

  for (final cat in categoryInflations) {
    if (!cat.inflationPercent.isFinite) continue;
    totalSpend += cat.totalSpend;
    weightedInflationSum += (cat.inflationPercent * cat.totalSpend);
  }

  if (totalSpend == 0) return 0.0;
  return weightedInflationSum / totalSpend;
}

class MonthlyIndex {
  final DateTime month;
  final double index;
  MonthlyIndex(this.month, this.index);
}

@riverpod
List<MonthlyIndex> basketIndexHistory(BasketIndexHistoryRef ref) {
  final entries =
      ref.watch(entriesWithDetailsProvider).valueOrNull ?? <EntryWithDetails>[];
  if (entries.isEmpty) return [];

  final sorted = List<EntryWithDetails>.of(entries)
    ..sort((a, b) => a.entry.purchaseDate.compareTo(b.entry.purchaseDate));

  final groupedByMonth = groupBy<EntryWithDetails, DateTime>(sorted,
      (e) => DateTime(e.entry.purchaseDate.year, e.entry.purchaseDate.month));

  final result = <MonthlyIndex>[];
  double baseCost = 0;

  final firstMonthDate =
      groupedByMonth.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  final baseBasket = groupedByMonth[firstMonthDate]!;

  // Base basket: quantities in base units (g or ml) per product.
  final baseBasketBaseQty = <int, double>{};
  for (final e in baseBasket) {
    final unit = unitTypeFromString(e.entry.unit);
    final baseQty = e.entry.quantity * unit.toBaseMultiplier;
    baseBasketBaseQty[e.product.id] =
        (baseBasketBaseQty[e.product.id] ?? 0) + baseQty;
    baseCost += e.entry.price;
  }

  if (baseCost == 0) return [];

  // Latest normalised unit price (CHF per base unit) seen up to current month.
  final latestUnitPrices = <int, double>{};
  final sortedMonths = groupedByMonth.keys.toList()..sort();

  for (final month in sortedMonths) {
    final monthEntries = groupedByMonth[month]!;

    for (final e in monthEntries) {
      latestUnitPrices[e.product.id] = _normalizedUnitPrice(e.entry);
    }

    double currentCost = 0;
    for (final productId in baseBasketBaseQty.keys) {
      final baseQty = baseBasketBaseQty[productId]!;
      final unitPrice = latestUnitPrices[productId];

      if (unitPrice == null || unitPrice == 0) {
        // Use original base unit price for this product
        final originalEntry =
            baseBasket.firstWhere((e) => e.product.id == productId);
        currentCost += _normalizedUnitPrice(originalEntry.entry) * baseQty;
      } else {
        currentCost += unitPrice * baseQty;
      }
    }

    final index = (currentCost / baseCost) * 100;
    if (!index.isFinite) continue;
    result.add(MonthlyIndex(month, index));
  }

  return result;
}
