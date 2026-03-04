import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'entry_providers.g.dart';

@riverpod
Stream<List<PurchaseEntry>> purchaseEntries(PurchaseEntriesRef ref) {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.watchEntries();
}

@riverpod
Stream<List<EntryWithDetails>> entriesWithDetails(EntriesWithDetailsRef ref) {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.watchEntriesWithDetails();
}

@riverpod
Stream<List<Category>> categories(CategoriesRef ref) {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.watchCategories();
}

enum HistoryDateRange { last30Days, last6Months, allTime }

class HistoryFilter {
  final HistoryDateRange range;
  final int? categoryId;

  const HistoryFilter({
    this.range = HistoryDateRange.allTime,
    this.categoryId,
  });

  HistoryFilter copyWith({HistoryDateRange? range, int? categoryId}) {
    return HistoryFilter(
      range: range ?? this.range,
      categoryId: categoryId,
    );
  }
}

@riverpod
class HistoryFilterController extends _$HistoryFilterController {
  @override
  HistoryFilter build() => const HistoryFilter();

  void setRange(HistoryDateRange range) {
    state = state.copyWith(range: range, categoryId: state.categoryId);
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(categoryId: categoryId, range: state.range);
  }
}

@riverpod
List<EntryWithDetails> filteredEntries(FilteredEntriesRef ref) {
  final entries =
      ref.watch(entriesWithDetailsProvider).valueOrNull ?? <EntryWithDetails>[];
  final filter = ref.watch(historyFilterControllerProvider);

  DateTime? cutoff;
  final now = DateTime.now();
  switch (filter.range) {
    case HistoryDateRange.last30Days:
      cutoff = now.subtract(const Duration(days: 30));
      break;
    case HistoryDateRange.last6Months:
      cutoff = now.subtract(const Duration(days: 180));
      break;
    case HistoryDateRange.allTime:
      cutoff = null;
      break;
  }

  return entries.where((entry) {
    final matchesDate =
        cutoff == null || entry.entry.purchaseDate.isAfter(cutoff);
    final matchesCategory =
        filter.categoryId == null || entry.category.id == filter.categoryId;
    return matchesDate && matchesCategory;
  }).toList();
}

@riverpod
class AddEntryController extends _$AddEntryController {
  @override
  FutureOr<void> build() {}

  Future<void> submitEntry({
    required String productName,
    required String categoryName,
    required String storeName,
    required double price,
    required double quantity,
    required DateTime date,
    String? location,
    int? existingEntryId,
  }) async {
    await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);

      // 1. Resolve or create category
      final existingCategories = await repo.watchCategories().first;
      int catId;
      try {
        final existingCat = existingCategories.firstWhere(
            (c) => c.name.toLowerCase() == categoryName.toLowerCase());
        catId = existingCat.id;
      } catch (e) {
        catId = await repo.addCategory(categoryName);
      }

      // 2. Resolve or create product
      Product? product = await repo.getProductByName(productName);
      final productId =
          product?.id ?? await repo.addProduct(productName, catId);

      // 3. Update or Add purchase entry
      if (existingEntryId != null) {
        await repo.updatePurchaseEntry(
          PurchaseEntry(
            id: existingEntryId,
            productId: productId,
            storeName: storeName,
            purchaseDate: date,
            price: price,
            quantity: quantity,
            location: location,
          ),
        );
      } else {
        await repo.addPurchaseEntry(
          productId: productId,
          storeName: storeName,
          purchaseDate: date,
          price: price,
          quantity: quantity,
          location: location,
        );
      }
    });
  }
}
