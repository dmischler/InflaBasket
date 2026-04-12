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

  /// EAN-13/UPC barcode for this product (optional).
  /// Used to match future barcode scans to existing products.
  TextColumn get barcode => text().nullable()();

  /// Brand name for this product (optional).
  /// Used for fuzzy matching when scanning new products.
  TextColumn get brand => text().nullable()();

  /// Store name for this product (optional).
  /// In v12+, store is attached to product (not per-entry).
  /// Kept nullable for migration; will become non-nullable in v13.
  /// Note: PurchaseEntries.storeName is kept for historical entries.
  TextColumn get storeName => text().nullable()();
}

@DataClassName('PurchaseEntry')
class PurchaseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get storeName => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get price => real()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();

  /// Stores the [UnitType.name] string. Null means 'count'.
  TextColumn get unit => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Price converted to satoshis at time of entry save.
  /// Null if BTC price was unavailable. Always stored as integer.
  IntColumn get priceSats => integer().nullable()();
}

/// Per-product price-change alert configuration.
/// When a new entry is saved and the price rise exceeds [thresholdPercent],
/// a local notification is triggered.
@DataClassName('PriceAlert')
class PriceAlerts extends Table {
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get thresholdPercent => real().withDefault(const Constant(10.0))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {productId};
}

@DataClassName('PriceHistory')
class PriceHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get price => real()();
  TextColumn get monthYear => text().withLength(min: 7, max: 7)();
  DateTimeColumn get createdAt => dateTime()();
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

@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('ApiKey')
class ApiKeys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => text().withLength(min: 1, max: 20)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get key => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  Categories,
  Products,
  PurchaseEntries,
  PriceAlerts,
  ExternalSeriesCache,
  PriceHistories,
  Settings,
  ApiKeys,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 15;

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
            await m.createTable(priceAlerts);
          }
          if (from < 4) {
            await m.createTable(externalSeriesCache);
          }
          if (from < 5) {
            await m.createTable(categories);

            final defaultCategoryNames = [
              'Food & Groceries',
              'Restaurants & Dining Out',
              'Beverages',
              'Transportation',
              'Fuel & Energy',
              'Housing & Rent',
              'Utilities',
              'Healthcare & Medical',
              'Personal Care & Hygiene',
              'Household Supplies',
              'Clothing & Apparel',
              'Electronics & Tech',
            ];

            for (final name in defaultCategoryNames) {
              final exists = await (select(categories)
                    ..where((t) => t.name.equals(name)))
                  .getSingleOrNull();
              if (exists == null) {
                await into(categories).insert(CategoriesCompanion.insert(
                  name: name,
                  isCustom: const Value(false),
                ));
              }
            }
          }
          if (from < 6) {
            // v6: Location field removed from schema.
            // Existing users' location data remains in SQLite but is unused.
            // SQLite doesn't support DROP COLUMN, so we skip the migration.
          }
          if (from < 7) {
            // v7: Add priceSats column for Bitcoin mode
            await m.addColumn(purchaseEntries, purchaseEntries.priceSats);
          }
          if (from < 9) {
            // v9: Add barcode column to products table
            await m.addColumn(products, products.barcode);
          }
          if (from < 10) {
            // v10: Add brand column to products table for fuzzy matching
            await m.addColumn(products, products.brand);
          }
          if (from < 11) {
            // v11: Add price_histories table for tracking price history
            await m.createTable(priceHistories);
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_price_histories_product_month '
              'ON price_histories(product_id, month_year)',
            );
          }
          if (from < 12) {
            // v12: Add storeName column to products table + backfill from latest purchase entry.
            //
            // WHY THIS FIX?
            // - onCreate (fresh installs) already creates the full products table with "store_name"
            //   via the current schema definition (products.storeName is now part of the table).
            // - onUpgrade (upgrades from <12) must still add the column for existing DBs.
            // - SQLite does NOT support "ALTER TABLE ADD COLUMN IF NOT EXISTS", so m.addColumn()
            //   fails with "duplicate column name" if the column is already present.
            // - Solution: explicit existence check via PRAGMA (standard, robust pattern used in
            //   Drift community and fixes interrupted migrations / edge cases where onUpgrade
            //   runs unexpectedly).
            // - Backfill SQL already corrected to use snake_case (store_name) — kept unchanged.
            // - The whole block is now idempotent and safe to re-run.

            // Step 1: Check if column already exists (fresh install or re-run)
            final columnExistsResult = await customSelect(
              "SELECT 1 FROM pragma_table_info('products') WHERE name = 'store_name' LIMIT 1",
            ).get();
            final storeNameAlreadyExists = columnExistsResult.isNotEmpty;

            if (!storeNameAlreadyExists) {
              await m.addColumn(products, products.storeName);
            }

            // Step 2: Backfill storeName from the most recent purchase entry (idempotent)
            await customStatement('''
              UPDATE products
              SET store_name = (
                SELECT pe.store_name
                FROM purchase_entries pe
                WHERE pe.product_id = products.id
                ORDER BY pe.purchase_date DESC, pe.id DESC
                LIMIT 1
              )
              WHERE EXISTS (
                SELECT 1 FROM purchase_entries pe
                WHERE pe.product_id = products.id
              )
              AND store_name IS NULL;
            ''');
          }
          if (from < 13) {
            await customStatement('DROP TABLE IF EXISTS category_weights');
            await customStatement('DROP TABLE IF EXISTS entry_templates');
          }
          if (from < 14) {
            await m.createTable(settings);
          }
          if (from < 15) {
            await customStatement('''
              CREATE TABLE IF NOT EXISTS api_keys (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                provider TEXT NOT NULL,
                name TEXT NOT NULL,
                key TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
              )
            ''');
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_api_keys_active_provider ON api_keys(is_active) WHERE is_active = 1',
            );
            final oldGeminiKey = await customSelect(
              "SELECT value FROM settings WHERE key = 'gemini_api_key'",
            ).getSingleOrNull();
            final oldOpenaiKey = await customSelect(
              "SELECT value FROM settings WHERE key = 'openai_api_key'",
            ).getSingleOrNull();
            final oldProvider = await customSelect(
              "SELECT value FROM settings WHERE key = 'ai_provider'",
            ).getSingleOrNull();
            if (oldGeminiKey != null) {
              final keyVal = oldGeminiKey.read<String>('value');
              if (keyVal.isNotEmpty) {
                final isActive = oldProvider != null &&
                        oldProvider.read<String>('value') != 'openai'
                    ? 1
                    : 0;
                await customStatement(
                  "INSERT INTO api_keys (provider, name, key, is_active) VALUES ('gemini', 'Gemini', ?, $isActive)",
                  [keyVal],
                );
              }
            }
            if (oldOpenaiKey != null) {
              final keyVal = oldOpenaiKey.read<String>('value');
              if (keyVal.isNotEmpty) {
                final isActive = oldProvider != null &&
                        oldProvider.read<String>('value') == 'openai'
                    ? 1
                    : 0;
                await customStatement(
                  "INSERT INTO api_keys (provider, name, key, is_active) VALUES ('openai', 'OpenAI', ?, $isActive)",
                  [keyVal],
                );
              }
            }
          }
        },
      );

  Future<void> resetDatabase({bool keepApiKeys = true}) async {
    await transaction(() async {
      await delete(purchaseEntries).go();
      await delete(products).go();
      await delete(priceAlerts).go();
      await delete(externalSeriesCache).go();
      await delete(priceHistories).go();
      await delete(categories).go();
      if (keepApiKeys) {
        final savedApiKeys = await select(apiKeys).get();
        await delete(settings).go();
        await delete(apiKeys).go();
        await batch((b) {
          b.insertAll(settings, [
            SettingsCompanion.insert(key: 'currency', value: 'CHF'),
            SettingsCompanion.insert(key: 'is_metric', value: 'true'),
            SettingsCompanion.insert(key: 'locale', value: 'en'),
            SettingsCompanion.insert(key: 'is_bitcoin_mode', value: 'false'),
            SettingsCompanion.insert(key: 'is_dark_mode', value: 'true'),
            SettingsCompanion.insert(
                key: 'price_update_reminder_enabled', value: 'false'),
            SettingsCompanion.insert(
                key: 'price_update_reminder_months', value: '6'),
            SettingsCompanion.insert(
                key: 'ai_consent_accepted', value: 'false'),
            SettingsCompanion.insert(
                key: 'has_completed_onboarding', value: 'false'),
            SettingsCompanion.insert(key: 'ai_provider', value: 'gemini'),
            SettingsCompanion.insert(key: 'gemini_api_key', value: ''),
            SettingsCompanion.insert(key: 'openai_api_key', value: ''),
            SettingsCompanion.insert(key: 'auto_backup_enabled', value: 'true'),
            SettingsCompanion.insert(
                key: 'auto_backup_external_path', value: ''),
            SettingsCompanion.insert(key: 'auto_backup_last_at', value: ''),
          ]);
          b.insertAll(apiKeys, savedApiKeys);
        });
      } else {
        await delete(settings).go();
        await delete(apiKeys).go();
      }
    });
    await _seedDefaultCategories();
    await seedDefaultSettings();
  }

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

  Future<void> seedDefaultSettings() async {
    final defaultSettings = <SettingsCompanion>[
      SettingsCompanion.insert(key: 'currency', value: 'CHF'),
      SettingsCompanion.insert(key: 'is_metric', value: 'true'),
      SettingsCompanion.insert(key: 'locale', value: 'en'),
      SettingsCompanion.insert(key: 'is_bitcoin_mode', value: 'false'),
      SettingsCompanion.insert(key: 'is_dark_mode', value: 'true'),
      SettingsCompanion.insert(
          key: 'price_update_reminder_enabled', value: 'false'),
      SettingsCompanion.insert(key: 'price_update_reminder_months', value: '6'),
      SettingsCompanion.insert(key: 'ai_consent_accepted', value: 'false'),
      SettingsCompanion.insert(key: 'has_completed_onboarding', value: 'false'),
      SettingsCompanion.insert(key: 'ai_provider', value: 'gemini'),
      SettingsCompanion.insert(key: 'gemini_api_key', value: ''),
      SettingsCompanion.insert(key: 'openai_api_key', value: ''),
      SettingsCompanion.insert(key: 'auto_backup_enabled', value: 'true'),
      SettingsCompanion.insert(key: 'auto_backup_external_path', value: ''),
      SettingsCompanion.insert(key: 'auto_backup_last_at', value: ''),
    ];

    await batch((batch) {
      batch.insertAll(
        settings,
        defaultSettings,
        mode: InsertMode.insertOrIgnore,
      );
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
