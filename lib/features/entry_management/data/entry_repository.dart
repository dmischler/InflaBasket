import 'package:drift/drift.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entry_repository.g.dart';

@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
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

class EntryRepository {
  final AppDatabase _db;
  EntryRepository(this._db);

  // Categories
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

  // Products
  Future<Product?> getProductByName(String name) async {
    return (_db.select(_db.products)..where((p) => p.name.equals(name)))
        .getSingleOrNull();
  }

  Future<int> addProduct(String name, int categoryId) {
    return _db.into(_db.products).insert(
          ProductsCompanion.insert(name: name, categoryId: categoryId),
        );
  }

  // Entries
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
            location: Value(location),
            notes: Value(notes),
          ),
        );
  }

  // Autocomplete helpers
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
  /// `productName`, `categoryName`, `price`, `quantity`.
  Future<void> bulkAddFromReceipt({
    required String storeName,
    required DateTime receiptDate,
    required List<Map<String, dynamic>> items,
  }) async {
    await _db.transaction(() async {
      for (final item in items) {
        final categoryName = item['categoryName'] as String? ?? 'Groceries';
        final productName = item['productName'] as String? ?? 'Unknown';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;

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
              ),
            );
      }
    });
  }
}
