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
}
