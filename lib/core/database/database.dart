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

@DriftDatabase(tables: [Categories, Products, PurchaseEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
        },
      );

  Future<void> _seedDefaultCategories() async {
    final defaults = <CategoriesCompanion>[
      CategoriesCompanion.insert(
          name: 'Food & Groceries', isCustom: const Value(false)),
      CategoriesCompanion.insert(name: 'Dairy', isCustom: const Value(false)),
      CategoriesCompanion.insert(name: 'Meat', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Beverages', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Household', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Personal Care', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Electronics', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Fuel/Transportation', isCustom: const Value(false)),
      CategoriesCompanion.insert(
          name: 'Dining Out', isCustom: const Value(false)),
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
