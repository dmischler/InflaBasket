import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/core/database/database.dart';

part 'inflation_providers.g.dart';

class ItemInflation {
  final Product product;
  final Category category;
  final double basePrice;
  final double currentPrice;
  final double inflationPercent;

  ItemInflation({
    required this.product,
    required this.category,
    required this.basePrice,
    required this.currentPrice,
    required this.inflationPercent,
  });
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
    final currentEntry = productEntries.last;

    final basePrice = baseEntry.entry.price / baseEntry.entry.quantity;
    final currentPrice = currentEntry.entry.price / currentEntry.entry.quantity;

    double inflation = 0;
    if (basePrice > 0) {
      inflation = ((currentPrice - basePrice) / basePrice) * 100;
    }

    result.add(ItemInflation(
      product: baseEntry.product,
      category: baseEntry.category,
      basePrice: basePrice,
      currentPrice: currentPrice,
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

  final baseBasketQuantities = <int, double>{};
  for (final entry in baseBasket) {
    baseBasketQuantities[entry.product.id] =
        (baseBasketQuantities[entry.product.id] ?? 0) + entry.entry.quantity;
    baseCost += entry.entry.price;
  }

  if (baseCost == 0) return [];

  final latestPrices = <int, double>{};
  final sortedMonths = groupedByMonth.keys.toList()..sort();

  for (final month in sortedMonths) {
    final monthEntries = groupedByMonth[month]!;

    for (final entry in monthEntries) {
      latestPrices[entry.product.id] = entry.entry.price / entry.entry.quantity;
    }

    double currentCost = 0;
    for (final productId in baseBasketQuantities.keys) {
      final qty = baseBasketQuantities[productId]!;
      final price = latestPrices[productId] ?? 0;

      if (price == 0) {
        final originalEntry =
            baseBasket.firstWhere((e) => e.product.id == productId);
        currentCost +=
            (originalEntry.entry.price / originalEntry.entry.quantity) * qty;
      } else {
        currentCost += price * qty;
      }
    }

    final index = (currentCost / baseCost) * 100;
    result.add(MonthlyIndex(month, index));
  }

  return result;
}
