import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/services/price_alert_service.dart';
import 'package:inflabasket/core/services/store_logo_cache.dart';
import 'package:inflabasket/core/services/auto_backup_service.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/entry_management/presentation/entry_duplicate_dialog.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/core/services/entry_duplicate_detector.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'entry_providers.g.dart';

class ExactDuplicateDiscardedException implements Exception {
  const ExactDuplicateDiscardedException();
}

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

@riverpod
Future<List<String>> allStores(AllStoresRef ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getAllStores();
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
  final String? searchQuery;

  const HistoryFilter({
    this.range = HistoryDateRange.allTime,
    this.categoryId,
    this.searchQuery,
  });

  HistoryFilter copyWith({
    HistoryDateRange? range,
    Object? categoryId = _clearCategory,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return HistoryFilter(
      range: range ?? this.range,
      // If caller passed categoryId explicitly (even null), use it;
      // otherwise keep the current value.
      categoryId: identical(categoryId, _clearCategory)
          ? this.categoryId
          : categoryId as int?,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
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

  void setSearchQuery(String? query) {
    if (query == null || query.isEmpty) {
      state = state.copyWith(clearSearch: true);
    } else {
      state = state.copyWith(searchQuery: query);
    }
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

  final searchQuery = filter.searchQuery;
  final useFuzzySearch = searchQuery != null && searchQuery.length >= 3;

  return entries.where((entry) {
    final matchesDate =
        cutoff == null || entry.entry.purchaseDate.isAfter(cutoff);
    final matchesCategory =
        filter.categoryId == null || entry.category.id == filter.categoryId;

    bool matchesSearch = true;
    if (useFuzzySearch) {
      final productName = entry.product.name.toLowerCase();
      final query = searchQuery.toLowerCase();
      final score = tokenSetRatio(query, productName);
      final substringMatch = productName.contains(query);
      matchesSearch = score >= 70 || substringMatch;
    }

    return matchesDate && matchesCategory && matchesSearch;
  }).toList();
}

// ─── Chart Time Filter ────────────────────────────────────────────────────────

enum ChartTimeRange {
  sixMonths,
  oneYear,
  twoYears,
  threeYears,
  fiveYears,
  tenYears,
  allTime,
  custom,
}

class ChartTimeFilter {
  final ChartTimeRange range;
  final DateTime? customStart;
  final DateTime? customEnd;

  const ChartTimeFilter({
    this.range = ChartTimeRange.oneYear,
    this.customStart,
    this.customEnd,
  });

  static DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 - months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    return DateTime(year, month, 1);
  }

  ChartTimeFilter copyWith({
    ChartTimeRange? range,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return ChartTimeFilter(
      range: range ?? this.range,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }

  /// Returns the start date for this filter based on the provided data range
  DateTime? getStartDate(DateTime firstDataPoint) {
    final now = DateTime.now();
    switch (range) {
      case ChartTimeRange.sixMonths:
        return _subtractMonths(now, 6);
      case ChartTimeRange.oneYear:
        return _subtractMonths(now, 12);
      case ChartTimeRange.twoYears:
        return _subtractMonths(now, 24);
      case ChartTimeRange.threeYears:
        return _subtractMonths(now, 36);
      case ChartTimeRange.fiveYears:
        return _subtractMonths(now, 60);
      case ChartTimeRange.tenYears:
        return _subtractMonths(now, 120);
      case ChartTimeRange.allTime:
        return firstDataPoint;
      case ChartTimeRange.custom:
        return customStart ?? firstDataPoint;
    }
  }

  DateTime getEndDate() {
    if (range == ChartTimeRange.custom && customEnd != null) {
      return customEnd!;
    }
    return DateTime.now();
  }
}

/// Helper to calculate months between two dates
int monthsBetween(DateTime start, DateTime end) {
  return (end.year - start.year) * 12 + end.month - start.month;
}

ChartTimeRange resolveTimeRangeSelection(
  ChartTimeFilter filter,
  List<ChartTimeRange> available,
) {
  if (filter.range == ChartTimeRange.custom) {
    return ChartTimeRange.custom;
  }
  if (available.contains(filter.range)) {
    return filter.range;
  }
  return available.firstWhere(
    (range) =>
        range != ChartTimeRange.custom && range != ChartTimeRange.allTime,
    orElse: () => ChartTimeRange.custom,
  );
}

/// Returns which time range options are available based on purchase activity.
///
/// A fixed range is shown only when at least one product has entries
/// that span that time range (earliest entry is at least that old).
/// Custom is always available.
List<ChartTimeRange> availableTimeRanges(Iterable<EntryWithDetails> entries) {
  final entryList = entries.toList();
  if (entryList.isEmpty) {
    return [ChartTimeRange.custom];
  }

  final grouped =
      groupBy<EntryWithDetails, int>(entryList, (e) => e.product.id);

  bool hasSpan(double years) {
    for (final productEntries in grouped.values) {
      final sorted = productEntries.map((e) => e.entry.purchaseDate).toList()
        ..sort();
      if (sorted.length < 2) continue;
      final span = sorted.last.difference(sorted.first).inDays / 365.25;
      if (span >= years) return true;
    }
    return false;
  }

  final available = <ChartTimeRange>[];
  if (hasSpan(0.5)) {
    available.add(ChartTimeRange.sixMonths);
  }
  if (hasSpan(1)) {
    available.add(ChartTimeRange.oneYear);
  }
  if (hasSpan(2)) {
    available.add(ChartTimeRange.twoYears);
  }
  if (hasSpan(3)) {
    available.add(ChartTimeRange.threeYears);
  }
  if (hasSpan(5)) {
    available.add(ChartTimeRange.fiveYears);
  }
  if (hasSpan(10)) {
    available.add(ChartTimeRange.tenYears);
  }
  available.add(ChartTimeRange.allTime);
  available.add(ChartTimeRange.custom);

  return available;
}

@riverpod
class ChartTimeFilterController extends _$ChartTimeFilterController {
  @override
  ChartTimeFilter build() => const ChartTimeFilter();

  void setRange(ChartTimeRange range) {
    state = state.copyWith(range: range);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = ChartTimeFilter(
      range: ChartTimeRange.custom,
      customStart: start,
      customEnd: end,
    );
  }
}

@riverpod
class AddEntryController extends _$AddEntryController {
  @override
  FutureOr<void> build() => null;

  Future<void> submitEntry({
    required String productName,
    required String categoryName,
    required String storeName,
    required double price,
    required double quantity,
    required DateTime date,
    required BuildContext context,
    UnitType? unit,
    String? notes,
    int? existingEntryId,
    String? barcode,
    int? forcedProductId,
    String? storeWebsite,
  }) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(entryRepositoryProvider);
      final isPremium =
          ref.read(subscriptionControllerProvider).valueOrNull ?? false;

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

      final normalizedBarcode = barcode?.trim();
      Product? barcodeProduct;
      if (normalizedBarcode != null && normalizedBarcode.isNotEmpty) {
        barcodeProduct = await repo.getProductByBarcode(normalizedBarcode);
      }

      Product? existingNamedProduct;
      if (barcodeProduct == null) {
        existingNamedProduct = await repo.getProductByName(productName);
      }

      final candidateProduct = forcedProductId != null
          ? await (_resolveForcedProduct(repo, forcedProductId))
          : barcodeProduct ?? existingNamedProduct;

      // When forcedProductId is set (quick-add from product detail),
      // use the product's storeName for the new entry
      final entryStoreName = forcedProductId != null && candidateProduct != null
          ? candidateProduct.storeName ?? storeName
          : storeName;

      // 2. Check for duplicate entries (only for new entries)
      if (existingEntryId == null) {
        final detector = EntryDuplicateDetectorService();
        final duplicate = await detector.findDuplicate(
          productName: productName,
          price: price,
          storeName: entryStoreName,
          repository: repo,
          barcode: normalizedBarcode,
          existingProductId: candidateProduct?.id,
          quantity: quantity,
          unit: unit,
        );

        if (duplicate != null && context.mounted) {
          if (duplicate.matchType == DuplicateMatchType.exact) {
            throw const ExactDuplicateDiscardedException();
          }

          final action = await showEntryDuplicateDialog(
            context: context,
            existingEntry: duplicate.existingEntry,
          );

          if (action == EntryDuplicateAction.dontSave) {
            return;
          }
        }
      }

      // 3. Resolve or create product (prefer barcode when available)
      Product? product = candidateProduct;
      final productId = forcedProductId ??
          product?.id ??
          await repo.addProduct(productName, catId, barcode: normalizedBarcode);

      // Normalise: store null for count (default)
      final storedUnit = (unit == null || unit == UnitType.count) ? null : unit;
      final previousEntry = existingEntryId == null
          ? await repo.getLatestEntryForProduct(productId)
          : null;

      // 4. Update or Add purchase entry
      if (existingEntryId != null) {
        await repo.updatePurchaseEntry(
          PurchaseEntry(
            id: existingEntryId,
            productId: productId,
            storeName: entryStoreName,
            purchaseDate: date,
            price: price,
            quantity: quantity,
            unit: storedUnit?.name,
            notes: notes,
          ),
        );
      } else {
        await repo.addPurchaseEntry(
          productId: productId,
          storeName: entryStoreName,
          purchaseDate: date,
          price: price,
          quantity: quantity,
          unit: storedUnit,
          notes: notes,
        );

        await ref.read(priceAlertServiceProvider).checkAndNotify(
              productId: productId,
              productName: productName,
              newPrice: price,
              isPremium: isPremium,
              previousPrice: previousEntry?.price,
            );

        final settings = ref.read(settingsControllerProvider);
        if (settings.autoSaveEnabled) {
          unawaited(
            ref.read(autoBackupServiceProvider).performBackup(),
          );
        }
      }

      if (storeWebsite != null && storeWebsite.trim().isNotEmpty) {
        await ref
            .read(storeLogoCacheProvider)
            .setWebsite(entryStoreName, storeWebsite);
      }
    });
  }

  Future<Product?> _resolveForcedProduct(
    EntryRepository repo,
    int productId,
  ) async {
    return repo.getProductById(productId);
  }
}
