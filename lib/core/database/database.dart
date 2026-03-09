import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconString => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
}

@DataClassName('PurchaseEntry')
class PurchaseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get storeName => text()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get price => real()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();

  /// Stores the [UnitType.name] string. Null means 'count'.
  TextColumn get unit => text().nullable()();
  TextColumn get notes => text().nullable()();
}

/// Stores user-defined basket weights per category.
/// Weight is a fraction 0.0–1.0; all weights should sum to 1.0.
/// If no weights are stored, the basket uses equal (spend-weighted) averaging.
@DataClassName('CategoryWeight')
class CategoryWeights extends Table {
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get weight => real()();

  @override
  Set<Column> get primaryKey => {categoryId};
}

/// A saved template for a recurring purchase.
/// Stores all fields needed to pre-fill [AddEntryScreen] — only the price
/// and date are supplied fresh at use-time.
@DataClassName('EntryTemplate')
class EntryTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get storeName => text()();
  TextColumn get location => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get notes => text().nullable()();
}

/// Per-product price-change alert configuration.
/// When a new entry is saved and the price rise exceeds [thresholdPercent],
/// a local notification is triggered (Premium only).
@DataClassName('PriceAlert')
class PriceAlerts extends Table {
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get thresholdPercent => real().withDefault(const Constant(10.0))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {productId};
}

@DataClassName('ExternalSeriesCacheEntry')
class ExternalSeriesCache extends Table {
  TextColumn get source => text()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get metric => text()();
  DateTimeColumn get month => dateTime()();
  RealColumn get value => real()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {source, currency, metric, month};
}

@DriftDatabase(tables: [
  Categories,
  Products,
  PurchaseEntries,
  CategoryWeights,
  EntryTemplates,
  PriceAlerts,
  ExternalSeriesCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(purchaseEntries, purchaseEntries.unit);
          }
          if (from < 3) {
            await m.createTable(categoryWeights);
            await m.createTable(entryTemplates);
            await m.createTable(priceAlerts);
          }
          if (from < 4) {
            await m.createTable(externalSeriesCache);
          }
          if (from < 5) {
            final existing = await (select(categories)..limit(1)).get();
            if (existing.isEmpty) {
              await _seedDefaultCategories();
            }
          }
        },
      );

  Future<void> _seedDefaultCategories() async {
    final defaults = <CategoriesCompanion>[
      CategoriesCompanion.insert(
          name: 'Food & Groceries', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Restaurants & Dining Out', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Beverages', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Transportation', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Fuel & Energy', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Housing & Rent', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Utilities', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Healthcare & Medical', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Personal Care & Hygiene', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Household Supplies', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Clothing & Apparel', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Electronics & Tech', isCustom: const Value(false)),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaults);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
