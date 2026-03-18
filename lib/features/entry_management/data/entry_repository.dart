import 'package:drift/drift.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/api/bitcoin_price_client.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entry_repository.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@riverpod
EntryRepository entryRepository(EntryRepositoryRef ref) {
  return EntryRepository(ref.watch(appDatabaseProvider));
}

class EntryWithDetails {
  final PurchaseEntry entry;
  final Product product;
  final Category category;

  EntryWithDetails(
      {required this.entry, required this.product, required this.category});
}

class EntryEditRequest {
  final EntryWithDetails entry;
  final bool lockSharedFields;

  const EntryEditRequest({
    required this.entry,
    this.lockSharedFields = false,
  });
}

class ProductWithCategory {
  final Product product;
  final Category category;

  const ProductWithCategory({required this.product, required this.category});
}

/// A lightweight version for duplicate detection - only includes product name.
class PurchaseEntryWithProduct {
  final PurchaseEntry entry;
  final Product product;

  PurchaseEntryWithProduct({required this.entry, required this.product});

  String get productName => product.name;
  double get price => entry.price;
  DateTime get purchaseDate => entry.purchaseDate;
  String get storeName => entry.storeName;
}

class TemplateWithDetails {
  final EntryTemplate template;
  final Product product;
  final Category category;

  TemplateWithDetails(
      {required this.template, required this.product, required this.category});
}

class ReceiptBulkSaveResult {
  final int savedCount;
  final int skippedDuplicateCount;

  const ReceiptBulkSaveResult({
    required this.savedCount,
    required this.skippedDuplicateCount,
  });
}

class EntryRepository {
  final AppDatabase _db;
  EntryRepository(this._db);

  AppDatabase get database => _db;

  static const metricCpi = 'cpi';
  static const metricMoneySupplyM2 = 'money_supply_m2';
  static const metricSnbCoreInflation1 = 'snb_core_inflation_1';

  String _normalizeDuplicateProductName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(
            RegExp(
                r'\d+(?:\.\d+)?\s*(g|kg|ml|l|cl|oz|lb|stück|pc|pcs|pack|-piece)'),
            '')
        .replaceAll(
            RegExp(r'\b(bio|öko|eco|organic)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^\w\säöüéèà]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeDuplicateStoreName(String storeName) {
    return storeName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _buildDuplicateKey({
    required String productName,
    required String storeName,
    required double price,
  }) {
    return [
      _normalizeDuplicateProductName(productName),
      _normalizeDuplicateStoreName(storeName),
      price.toStringAsFixed(2),
    ].join('|');
  }

  // ─── Categories ─────────────────────────────────────────────────────────────

  Stream<List<Category>> watchCategories() =>
      _db.select(_db.categories).watch();

  Future<int> addCategory(String name,
      {String? iconString, bool isCustom = true}) {
    return _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            name: name,
            iconString: Value(iconString),
            isCustom: Value(isCustom),
          ),
        );
  }

  Future<bool> hasProductsForCategory(int categoryId) async {
    final countExp = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([countExp])
      ..where(_db.products.categoryId.equals(categoryId));
    final row = await query.getSingle();
    final count = row.read(countExp) ?? 0;
    return count > 0;
  }

  Future<int> deleteCategory(int categoryId) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(categoryId)))
        .go();
  }

  // ─── Category Weights ────────────────────────────────────────────────────────

  /// Returns a map of categoryId → weight for all stored weights.
  Future<Map<int, double>> getCategoryWeights() async {
    final rows = await _db.select(_db.categoryWeights).get();
    return {for (final r in rows) r.categoryId: r.weight};
  }

  /// Persists the full set of category weights, replacing any existing ones.
  /// [weights] maps categoryId → weight (values should sum to 1.0).
  Future<void> saveCategoryWeights(Map<int, double> weights) async {
    await _db.transaction(() async {
      await _db.delete(_db.categoryWeights).go();
      for (final entry in weights.entries) {
        await _db.into(_db.categoryWeights).insert(
              CategoryWeightsCompanion.insert(
                categoryId: Value(entry.key),
                weight: entry.value,
              ),
            );
      }
    });
  }

  /// Clears all custom weights so the basket reverts to spend-weighted averaging.
  Future<void> clearCategoryWeights() => _db.delete(_db.categoryWeights).go();

  // ─── Products ────────────────────────────────────────────────────────────────

  Future<Product?> getProductByName(String name) async {
    return (_db.select(_db.products)..where((p) => p.name.equals(name)))
        .getSingleOrNull();
  }

  Future<Product?> getProductById(int productId) {
    return (_db.select(_db.products)..where((p) => p.id.equals(productId)))
        .getSingleOrNull();
  }

  Future<bool> hasOtherProductWithName({
    required String name,
    required int excludedProductId,
  }) async {
    final products = await _db.select(_db.products).get();
    final normalizedName = name.trim().toLowerCase();
    return products.any(
      (product) =>
          product.id != excludedProductId &&
          product.name.trim().toLowerCase() == normalizedName,
    );
  }

  /// Returns the product with the given barcode, or null if not found.
  Future<Product?> getProductByBarcode(String barcode) async {
    return (_db.select(_db.products)..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Returns all product names in a given category (for duplicate detection).
  Future<List<String>> getProductNamesForCategory(int categoryId) async {
    final res = await (_db.select(_db.products)
          ..where((p) => p.categoryId.equals(categoryId)))
        .get();
    return res.map((p) => p.name).toList();
  }

  Future<int> addProduct(String name, int categoryId,
      {String? barcode, String? brand}) {
    return _db.into(_db.products).insert(
          ProductsCompanion(
            name: Value(name),
            categoryId: Value(categoryId),
            barcode: Value(barcode),
            brand: Value(brand),
          ),
        );
  }

  Stream<ProductWithCategory?> watchProductWithCategory(int productId) {
    final query = _db.select(_db.products).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.products.categoryId),
      ),
    ])
      ..where(_db.products.id.equals(productId))
      ..limit(1);

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return ProductWithCategory(
        product: row.readTable(_db.products),
        category: row.readTable(_db.categories),
      );
    });
  }

  Future<void> updateProductDetailFields({
    required int productId,
    required String name,
    required int categoryId,
    required String storeName,
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
          .write(
        ProductsCompanion(
          name: Value(name),
          categoryId: Value(categoryId),
        ),
      );

      await (_db.update(_db.purchaseEntries)
            ..where((e) => e.productId.equals(productId)))
          .write(
        PurchaseEntriesCompanion(storeName: Value(storeName)),
      );

      await (_db.update(_db.entryTemplates)
            ..where((t) => t.productId.equals(productId)))
          .write(
        EntryTemplatesCompanion(storeName: Value(storeName)),
      );
    });
  }

  Future<void> updateProductBrand(int productId, String brand) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(brand: Value(brand)));
  }

  Future<void> updateProductBarcode(int productId, String barcode) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(barcode: Value(barcode)));
  }

  // ─── Entries ─────────────────────────────────────────────────────────────────

  Stream<List<PurchaseEntry>> watchEntries() =>
      _db.select(_db.purchaseEntries).watch();

  Stream<List<EntryWithDetails>> watchEntriesWithDetails() {
    final query = _db.select(_db.purchaseEntries).join([
      innerJoin(_db.products,
          _db.products.id.equalsExp(_db.purchaseEntries.productId)),
      innerJoin(
          _db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return EntryWithDetails(
          entry: row.readTable(_db.purchaseEntries),
          product: row.readTable(_db.products),
          category: row.readTable(_db.categories),
        );
      }).toList();
    });
  }

  Stream<List<EntryWithDetails>> watchEntriesWithDetailsForProduct(
      int productId) {
    final query = _db.select(_db.purchaseEntries).join([
      innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.purchaseEntries.productId),
      ),
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.products.categoryId),
      ),
    ])
      ..where(_db.purchaseEntries.productId.equals(productId))
      ..orderBy([
        OrderingTerm.desc(_db.purchaseEntries.purchaseDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return EntryWithDetails(
          entry: row.readTable(_db.purchaseEntries),
          product: row.readTable(_db.products),
          category: row.readTable(_db.categories),
        );
      }).toList();
    });
  }

  /// Returns entries from the last [days] days with their products.
  /// Used for duplicate detection.
  Future<List<PurchaseEntryWithProduct>> getRecentEntriesWithProduct({
    required int days,
    double? price,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    var query = _db.select(_db.purchaseEntries).join([
      innerJoin(_db.products,
          _db.products.id.equalsExp(_db.purchaseEntries.productId)),
    ])
      ..where(
          _db.purchaseEntries.purchaseDate.isBiggerOrEqualValue(cutoffDate));

    if (price != null) {
      query = query..where(_db.purchaseEntries.price.equals(price));
    }

    final rows = await query.get();
    return rows.map((row) {
      return PurchaseEntryWithProduct(
        entry: row.readTable(_db.purchaseEntries),
        product: row.readTable(_db.products),
      );
    }).toList();
  }

  Future<int?> calculatePriceSats(
      double fiatPrice, String currency, DateTime date) async {
    final btcClient = BtcPriceClient(db: _db);
    final btcPrice = await btcClient.fetchBtcPrice(currency, date);
    if (btcPrice == null || btcPrice <= 0) {
      return null;
    }
    final sats = SatsConverter.fiatToSats(fiatPrice, btcPrice);
    return sats;
  }

  PurchaseEntry _copyEntryWithPriceSats(
    PurchaseEntry entry,
    int? priceSats,
  ) {
    return PurchaseEntry(
      id: entry.id,
      productId: entry.productId,
      storeName: entry.storeName,
      purchaseDate: entry.purchaseDate,
      price: entry.price,
      quantity: entry.quantity,
      unit: entry.unit,
      notes: entry.notes,
      priceSats: priceSats,
    );
  }

  Future<int> addPurchaseEntry({
    required int productId,
    required String storeName,
    required DateTime purchaseDate,
    required double price,
    required double quantity,
    UnitType? unit,
    String? notes,
    String currency = 'CHF',
  }) async {
    final priceSats = await calculatePriceSats(price, currency, purchaseDate);

    return _db.into(_db.purchaseEntries).insert(
          PurchaseEntriesCompanion.insert(
            productId: productId,
            storeName: storeName,
            purchaseDate: purchaseDate,
            price: price,
            priceSats: Value<int?>(priceSats),
            quantity: Value(quantity),
            unit: Value(unit == UnitType.count ? null : unit?.name),
            notes: Value(notes),
          ),
        );
  }

  /// Returns the most recent entry for the given product, or null if none.
  Future<PurchaseEntry?> getLatestEntryForProduct(int productId) async {
    return (_db.select(_db.purchaseEntries)
          ..where((e) => e.productId.equals(productId))
          ..orderBy([(e) => OrderingTerm.desc(e.purchaseDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  // ─── Autocomplete ────────────────────────────────────────────────────────────

  Future<List<String>> searchProductNames(String query) async {
    final res = await (_db.select(_db.products)
          ..where((p) => p.name.like('%$query%'))
          ..limit(10))
        .get();
    return res.map((p) => p.name).toList();
  }

  Future<List<String>> searchStoreNames(String query) async {
    final queryExp = _db.selectOnly(_db.purchaseEntries, distinct: true)
      ..addColumns([_db.purchaseEntries.storeName])
      ..where(_db.purchaseEntries.storeName.like('%$query%'))
      ..orderBy([OrderingTerm.asc(_db.purchaseEntries.storeName)])
      ..limit(10);
    final res = await queryExp.get();
    return res.map((row) => row.read(_db.purchaseEntries.storeName)!).toList();
  }

  Future<List<String>> searchCategoryNames(String query) async {
    final all = await _db.select(_db.categories).get();
    final names = all.map((c) => c.name).toList();

    if (query.isEmpty) return names;

    final queryLower = query.toLowerCase();
    return names.where((englishName) {
      if (englishName.toLowerCase().contains(queryLower)) return true;

      final germanName = CategoryLocalization.displayName(
        englishName,
        languageCode: 'de',
      );
      if (germanName.toLowerCase().contains(queryLower)) return true;

      return false;
    }).toList();
  }

  Future<int> updateMissingPriceSats({String currency = 'CHF'}) async {
    final entriesMissingSats = await (_db.select(_db.purchaseEntries)
          ..where((entry) => entry.priceSats.isNull()))
        .get();

    var updatedEntries = 0;

    for (final entry in entriesMissingSats) {
      final priceSats =
          await calculatePriceSats(entry.price, currency, entry.purchaseDate);

      if (priceSats == null) {
        continue;
      }

      final updated = await _db
          .update(_db.purchaseEntries)
          .replace(_copyEntryWithPriceSats(entry, priceSats));

      if (updated) {
        updatedEntries++;
      }
    }

    return updatedEntries;
  }

  Future<bool> updatePurchaseEntry(
    PurchaseEntry entry, {
    String currency = 'CHF',
  }) async {
    final priceSats =
        await calculatePriceSats(entry.price, currency, entry.purchaseDate);
    final updatedEntry = _copyEntryWithPriceSats(entry, priceSats);
    return _db.update(_db.purchaseEntries).replace(updatedEntry);
  }

  Future<int> deletePurchaseEntry(int entryId) {
    return (_db.delete(_db.purchaseEntries)..where((e) => e.id.equals(entryId)))
        .go();
  }

  Future<void> deleteProductAndRelatedData(int productId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.priceAlerts)
            ..where((alert) => alert.productId.equals(productId)))
          .go();
      await (_db.delete(_db.entryTemplates)
            ..where((template) => template.productId.equals(productId)))
          .go();
      await _db.customStatement(
        'DELETE FROM price_histories WHERE product_id = ?',
        [productId],
      );
      await (_db.delete(_db.purchaseEntries)
            ..where((entry) => entry.productId.equals(productId)))
          .go();
      await (_db.delete(_db.products)..where((p) => p.id.equals(productId)))
          .go();
    });
  }

  /// Saves a list of receipt items atomically. If any item fails, the entire
  /// batch is rolled back. Duplicate entries (same product, store, price within
  /// 30 days) are skipped. Each [items] entry must have keys:
  /// `productName`, `categoryName`, `price`, `quantity`, `unit` (optional).
  Future<ReceiptBulkSaveResult> bulkAddFromReceipt({
    required String storeName,
    required DateTime receiptDate,
    required List<Map<String, dynamic>> items,
  }) async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    var savedCount = 0;
    var skippedDuplicateCount = 0;

    final existingRows = await (_db.select(_db.purchaseEntries).join([
      innerJoin(_db.products,
          _db.products.id.equalsExp(_db.purchaseEntries.productId)),
    ])
          ..where(_db.purchaseEntries.purchaseDate
              .isBiggerOrEqualValue(cutoffDate)))
        .get();

    final duplicateKeys = <String>{
      for (final row in existingRows)
        _buildDuplicateKey(
          productName: row.readTable(_db.products).name,
          storeName: row.readTable(_db.purchaseEntries).storeName,
          price: row.readTable(_db.purchaseEntries).price,
        ),
    };

    await _db.transaction(() async {
      for (final item in items) {
        final categoryName =
            item['categoryName'] as String? ?? 'Food & Groceries';
        final productName = item['productName'] as String? ?? 'Unknown';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
        final unitStr = item['unit'] as String?;
        final unit = unitTypeFromString(unitStr);

        final duplicateKey = _buildDuplicateKey(
          productName: productName,
          storeName: storeName,
          price: price,
        );
        if (duplicateKeys.contains(duplicateKey)) {
          skippedDuplicateCount++;
          continue;
        }

        // Resolve or create category
        final allCategories = await _db.select(_db.categories).get();
        int catId;
        try {
          catId = allCategories
              .firstWhere(
                  (c) => c.name.toLowerCase() == categoryName.toLowerCase())
              .id;
        } catch (_) {
          catId = await _db.into(_db.categories).insert(
                CategoriesCompanion.insert(
                  name: categoryName,
                  isCustom: const Value(true),
                ),
              );
        }

        // Resolve or create product
        final existingProduct = await (_db.select(_db.products)
              ..where((p) => p.name.equals(productName)))
            .getSingleOrNull();
        final productId = existingProduct?.id ??
            await _db.into(_db.products).insert(
                  ProductsCompanion.insert(
                      name: productName, categoryId: catId),
                );

        final priceSats = await calculatePriceSats(price, 'CHF', receiptDate);

        // Insert entry
        await _db.into(_db.purchaseEntries).insert(
              PurchaseEntriesCompanion.insert(
                productId: productId,
                storeName: storeName,
                purchaseDate: receiptDate,
                price: price,
                priceSats: Value<int?>(priceSats),
                quantity: Value(quantity),
                unit: Value(unit == UnitType.count ? null : unit.name),
              ),
            );
        savedCount++;
        duplicateKeys.add(duplicateKey);
      }
    });

    return ReceiptBulkSaveResult(
      savedCount: savedCount,
      skippedDuplicateCount: skippedDuplicateCount,
    );
  }

  // ─── Templates ───────────────────────────────────────────────────────────────

  Stream<List<TemplateWithDetails>> watchTemplatesWithDetails() {
    final query = _db.select(_db.entryTemplates).join([
      innerJoin(_db.products,
          _db.products.id.equalsExp(_db.entryTemplates.productId)),
      innerJoin(
          _db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TemplateWithDetails(
          template: row.readTable(_db.entryTemplates),
          product: row.readTable(_db.products),
          category: row.readTable(_db.categories),
        );
      }).toList();
    });
  }

  Future<int> addTemplate({
    required int productId,
    required String storeName,
    double quantity = 1.0,
    UnitType? unit,
    String? notes,
  }) {
    return _db.into(_db.entryTemplates).insert(
          EntryTemplatesCompanion.insert(
            productId: productId,
            storeName: storeName,
            quantity: Value(quantity),
            unit: Value(unit == UnitType.count ? null : unit?.name),
            notes: Value(notes),
          ),
        );
  }

  Future<int> deleteTemplate(int templateId) {
    return (_db.delete(_db.entryTemplates)
          ..where((t) => t.id.equals(templateId)))
        .go();
  }

  // ─── Price Alerts ────────────────────────────────────────────────────────────

  Future<List<PriceAlert>> getAllPriceAlerts() {
    return _db.select(_db.priceAlerts).get();
  }

  Future<PriceAlert?> getPriceAlert(int productId) async {
    return (_db.select(_db.priceAlerts)
          ..where((a) => a.productId.equals(productId)))
        .getSingleOrNull();
  }

  Future<void> setPriceAlert({
    required int productId,
    required double thresholdPercent,
    required bool isEnabled,
  }) {
    return _db.into(_db.priceAlerts).insertOnConflictUpdate(
          PriceAlertsCompanion.insert(
            productId: Value(productId),
            thresholdPercent: Value(thresholdPercent),
            isEnabled: Value(isEnabled),
          ),
        );
  }

  Future<int> deletePriceAlert(int productId) {
    return (_db.delete(_db.priceAlerts)
          ..where((a) => a.productId.equals(productId)))
        .go();
  }

  /// Returns all enabled price alerts with their products.
  Future<List<PriceAlert>> getEnabledPriceAlerts() async {
    return (_db.select(_db.priceAlerts)..where((a) => a.isEnabled.equals(true)))
        .get();
  }

  // ─── External Series Cache ──────────────────────────────────────────────────

  Future<List<ExternalSeriesCacheEntry>> getExternalSeriesCache({
    required String source,
    required String currency,
    required String metric,
    required DateTime startMonth,
  }) {
    return (_db.select(_db.externalSeriesCache)
          ..where((row) =>
              row.source.equals(source) &
              row.currency.equals(currency) &
              row.metric.equals(metric) &
              row.month.isBiggerOrEqualValue(startMonth))
          ..orderBy([(row) => OrderingTerm.asc(row.month)]))
        .get();
  }

  Future<void> replaceExternalSeriesCache({
    required String source,
    required String currency,
    required String metric,
    required List<(DateTime month, double value)> points,
    DateTime? fetchedAt,
  }) async {
    final timestamp = fetchedAt ?? DateTime.now();
    await _db.transaction(() async {
      await (_db.delete(_db.externalSeriesCache)
            ..where((row) =>
                row.source.equals(source) &
                row.currency.equals(currency) &
                row.metric.equals(metric)))
          .go();

      for (final point in points) {
        await _db.into(_db.externalSeriesCache).insert(
              ExternalSeriesCacheCompanion.insert(
                source: source,
                currency: currency,
                metric: metric,
                month: point.$1,
                value: point.$2,
                fetchedAt: timestamp,
              ),
            );
      }
    });
  }

  // ─── Duplicate Cleanup ──────────────────────────────────────────────────────

  /// Cleans up duplicate entries (same product + store + price within last N days).
  /// Returns the count of deleted entries.
  /// Keeps the oldest entry for each duplicate group.
  Future<int> cleanupDuplicateEntries({int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final entries = await (_db.select(_db.purchaseEntries).join([
      innerJoin(_db.products,
          _db.products.id.equalsExp(_db.purchaseEntries.productId)),
    ])
          ..where(
              _db.purchaseEntries.purchaseDate.isBiggerOrEqualValue(cutoffDate))
          ..orderBy([
            OrderingTerm.asc(_db.purchaseEntries.purchaseDate),
          ]))
        .get();

    if (entries.isEmpty) return 0;

    final groupedByKey = <String, List<(int entryId, DateTime purchaseDate)>>{};
    for (final row in entries) {
      final entry = row.readTable(_db.purchaseEntries);
      final product = row.readTable(_db.products);
      final key = _buildDuplicateKey(
        productName: product.name,
        storeName: entry.storeName,
        price: entry.price,
      );
      groupedByKey
          .putIfAbsent(key, () => [])
          .add((entry.id, entry.purchaseDate));
    }

    final idsToDelete = <int>[];
    for (final group in groupedByKey.values) {
      if (group.length > 1) {
        group.sort((a, b) => a.$2.compareTo(b.$2));
        for (var i = 1; i < group.length; i++) {
          idsToDelete.add(group[i].$1);
        }
      }
    }

    if (idsToDelete.isEmpty) return 0;

    await _db.transaction(() async {
      for (final id in idsToDelete) {
        await (_db.delete(_db.purchaseEntries)..where((e) => e.id.equals(id)))
            .go();
      }
    });

    return idsToDelete.length;
  }
}
