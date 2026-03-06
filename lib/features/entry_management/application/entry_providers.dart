import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';
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

// ─── Template providers ───────────────────────────────────────────────────────

@riverpod
Stream<List<TemplateWithDetails>> templates(TemplatesRef ref) {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.watchTemplatesWithDetails();
}

@riverpod
class AddTemplateController extends _$AddTemplateController {
  @override
  FutureOr<void> build() {}

  Future<void> addTemplate({
    required int productId,
    required String storeName,
    String? location,
    double quantity = 1.0,
    UnitType? unit,
    String? notes,
  }) async {
    await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);
      await repo.addTemplate(
        productId: productId,
        storeName: storeName,
        location: location,
        quantity: quantity,
        unit: unit,
        notes: notes,
      );
    });
  }

  Future<void> deleteTemplate(int templateId) async {
    await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);
      await repo.deleteTemplate(templateId);
    });
  }
}

// ─── History filter ───────────────────────────────────────────────────────────

enum HistoryDateRange { last30Days, last6Months, allTime }

/// Sentinel value used to explicitly clear [HistoryFilter.categoryId].
/// Using a plain `null` default in `copyWith` makes it impossible to
/// distinguish "not provided" from "set to null".
const _clearCategory = Object();

class HistoryFilter {
  final HistoryDateRange range;
  final int? categoryId;

  const HistoryFilter({
    this.range = HistoryDateRange.allTime,
    this.categoryId,
  });

  HistoryFilter copyWith({
    HistoryDateRange? range,
    Object? categoryId = _clearCategory,
  }) {
    return HistoryFilter(
      range: range ?? this.range,
      // If caller passed categoryId explicitly (even null), use it;
      // otherwise keep the current value.
      categoryId: identical(categoryId, _clearCategory)
          ? this.categoryId
          : categoryId as int?,
    );
  }
}

@riverpod
class HistoryFilterController extends _$HistoryFilterController {
  @override
  HistoryFilter build() => const HistoryFilter();

  void setRange(HistoryDateRange range) {
    state = state.copyWith(range: range);
  }

  void setCategory(int? categoryId) {
    state = HistoryFilter(range: state.range, categoryId: categoryId);
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
    UnitType? unit,
    String? location,
    String? notes,
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

      // Normalise: store null for count (default)
      final storedUnit = (unit == null || unit == UnitType.count) ? null : unit;

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
            unit: storedUnit?.name,
            location: location,
            notes: notes,
          ),
        );
      } else {
        await repo.addPurchaseEntry(
          productId: productId,
          storeName: storeName,
          purchaseDate: date,
          price: price,
          quantity: quantity,
          unit: storedUnit,
          location: location,
          notes: notes,
        );
      }
    });
  }
}
