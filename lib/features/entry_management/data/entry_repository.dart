import 'package:drift/drift.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';
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

class TemplateWithDetails {
  final EntryTemplate template;
  final Product product;
  final Category category;

  TemplateWithDetails(
      {required this.template, required this.product, required this.category});
}

class EntryRepository {
  final AppDatabase _db;
  EntryRepository(this._db);

  static const metricCpi = 'cpi';
  static const metricMoneySupplyM2 = 'money_supply_m2';
  static const metricSnbCoreInflation1 = 'snb_core_inflation_1';

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

  /// Returns all product names in a given category (for duplicate detection).
  Future<List<String>> getProductNamesForCategory(int categoryId) async {
    final res = await (_db.select(_db.products)
          ..where((p) => p.categoryId.equals(categoryId)))
        .get();
    return res.map((p) => p.name).toList();
  }

  Future<int> addProduct(String name, int categoryId) {
    return _db.into(_db.products).insert(
          ProductsCompanion.insert(name: name, categoryId: categoryId),
        );
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

  Future<int> addPurchaseEntry({
    required int productId,
    required String storeName,
    required DateTime purchaseDate,
    required double price,
    required double quantity,
    UnitType? unit,
    String? location,
    String? notes,
  }) {
    return _db.into(_db.purchaseEntries).insert(
          PurchaseEntriesCompanion.insert(
            productId: productId,
            storeName: storeName,
            purchaseDate: purchaseDate,
            price: price,
            quantity: Value(quantity),
            unit: Value(unit == UnitType.count ? null : unit?.name),
            location: Value(location),
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
      ..limit(10);
    final res = await queryExp.get();
    return res.map((row) => row.read(_db.purchaseEntries.storeName)!).toList();
  }

  Future<List<String>> searchLocations(String query) async {
    final queryExp = _db.selectOnly(_db.purchaseEntries, distinct: true)
      ..addColumns([_db.purchaseEntries.location])
      ..where(_db.purchaseEntries.location.like('%$query%'))
      ..limit(10);
    final res = await queryExp.get();
    return res
        .map((row) => row.read(_db.purchaseEntries.location))
        .where((loc) => loc != null && loc.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<bool> updatePurchaseEntry(PurchaseEntry entry) {
    return _db.update(_db.purchaseEntries).replace(entry);
  }

  Future<int> deletePurchaseEntry(int entryId) {
    return (_db.delete(_db.purchaseEntries)..where((e) => e.id.equals(entryId)))
        .go();
  }

  /// Saves a list of receipt items atomically. If any item fails, the entire
  /// batch is rolled back. Each [items] entry must have keys:
  /// `productName`, `categoryName`, `price`, `quantity`, `unit` (optional).
  Future<void> bulkAddFromReceipt({
    required String storeName,
    required DateTime receiptDate,
    required List<Map<String, dynamic>> items,
  }) async {
    await _db.transaction(() async {
      for (final item in items) {
        final categoryName =
            item['categoryName'] as String? ?? 'Food & Groceries';
        final productName = item['productName'] as String? ?? 'Unknown';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
        final unitStr = item['unit'] as String?;
        final unit = unitTypeFromString(unitStr);

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

        // Insert entry
        await _db.into(_db.purchaseEntries).insert(
              PurchaseEntriesCompanion.insert(
                productId: productId,
                storeName: storeName,
                purchaseDate: receiptDate,
                price: price,
                quantity: Value(quantity),
                unit: Value(unit == UnitType.count ? null : unit.name),
              ),
            );
      }
    });
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
    String? location,
    double quantity = 1.0,
    UnitType? unit,
    String? notes,
  }) {
    return _db.into(_db.entryTemplates).insert(
          EntryTemplatesCompanion.insert(
            productId: productId,
            storeName: storeName,
            location: Value(location),
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
}
