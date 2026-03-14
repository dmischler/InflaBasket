import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'price_history_service.g.dart';

class ProductNeedingUpdate {
  final int productId;
  final String productName;
  final String? brand;
  final String? categoryName;
  final String? storeName;
  final double lastPrice;
  final String lastMonthYear;

  const ProductNeedingUpdate({
    required this.productId,
    required this.productName,
    this.brand,
    this.categoryName,
    this.storeName,
    required this.lastPrice,
    required this.lastMonthYear,
  });
}

@riverpod
PriceHistoryService priceHistoryService(PriceHistoryServiceRef ref) {
  return PriceHistoryService(ref.watch(appDatabaseProvider));
}

class PriceHistoryService {
  final AppDatabase _db;
  PriceHistoryService(this._db);

  static String formatMonthYear(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static DateTime? parseMonthYear(String monthYear) {
    try {
      return DateFormat('yyyy-MM').parse(monthYear);
    } catch (_) {
      return null;
    }
  }

  static String formatGermanMonth(String monthYear) {
    final date = parseMonthYear(monthYear);
    if (date == null) return monthYear;

    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<int> addPrice({
    required int productId,
    required double price,
    DateTime? date,
  }) {
    final monthYear = formatMonthYear(date ?? DateTime.now());
    return _db.into(_db.priceHistories).insert(
          PriceHistoriesCompanion.insert(
            productId: productId,
            price: price,
            monthYear: monthYear,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<List<PriceHistory>> getPriceHistoryForProduct(int productId) {
    return (_db.select(_db.priceHistories)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.monthYear)]))
        .get();
  }

  Stream<List<PriceHistory>> watchPriceHistoryForProduct(int productId) {
    return (_db.select(_db.priceHistories)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.monthYear)]))
        .watch();
  }

  Future<PriceHistory?> getPriceForMonth(int productId, String monthYear) {
    return (_db.select(_db.priceHistories)
          ..where((t) =>
              t.productId.equals(productId) & t.monthYear.equals(monthYear)))
        .getSingleOrNull();
  }

  Future<int> deletePriceHistory(int id) {
    return (_db.delete(_db.priceHistories)..where((t) => t.id.equals(id))).go();
  }

  String _getCutoffMonthYear(int months) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month - months;

    while (month <= 0) {
      month += 12;
      year -= 1;
    }

    return DateFormat('yyyy-MM').format(DateTime(year, month));
  }

  Future<Map<String, Map<String, List<ProductNeedingUpdate>>>>
      getProductsNeedingUpdate(int months) async {
    final cutoffMonthYear = _getCutoffMonthYear(months);

    final results = await _db.customSelect('''
      SELECT 
        p.id as product_id,
        p.name as product_name,
        p.brand,
        c.name as category_name,
        (SELECT pe.store_name FROM purchase_entries pe 
         WHERE pe.product_id = p.id 
         ORDER BY pe.purchase_date DESC LIMIT 1) as store_name,
        ph.price as last_price,
        ph.month_year as last_month_year
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
      INNER JOIN (
        SELECT product_id, MAX(month_year) as max_month_year
        FROM price_histories
        GROUP BY product_id
      ) latest ON p.id = latest.product_id
      INNER JOIN price_histories ph ON 
        ph.product_id = p.id AND ph.month_year = latest.max_month_year
      WHERE ph.month_year < ?
      ORDER BY store_name, category_name, product_name
    ''', variables: [Variable.withString(cutoffMonthYear)]).get();

    final Map<String, Map<String, List<ProductNeedingUpdate>>> grouped = {};

    for (final row in results) {
      final storeName = row.read<String?>('store_name') ?? 'Andere';
      final categoryName =
          row.read<String?>('category_name') ?? 'Unkategorisiert';
      final product = ProductNeedingUpdate(
        productId: row.read<int>('product_id'),
        productName: row.read<String>('product_name'),
        brand: row.read<String?>('brand'),
        categoryName: categoryName,
        storeName: storeName,
        lastPrice: row.read<double>('last_price'),
        lastMonthYear: row.read<String>('last_month_year'),
      );

      grouped.putIfAbsent(storeName, () => {});
      grouped[storeName]!.putIfAbsent(categoryName, () => []);
      grouped[storeName]![categoryName]!.add(product);
    }

    return grouped;
  }

  Future<Map<String, Map<String, List<ProductNeedingUpdate>>>>
      getProductsWithoutPrice() async {
    final results = await _db.customSelect('''
      SELECT p.id, p.name, p.brand, c.name as category_name,
             (SELECT pe.store_name FROM purchase_entries pe 
              WHERE pe.product_id = p.id 
              ORDER BY pe.purchase_date DESC LIMIT 1) as store_name
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
      WHERE p.id NOT IN (SELECT DISTINCT product_id FROM price_histories)
      ORDER BY store_name, category_name, p.name
    ''').get();

    final Map<String, Map<String, List<ProductNeedingUpdate>>> grouped = {};

    for (final row in results) {
      final storeName = row.read<String?>('store_name') ?? 'Andere';
      final categoryName =
          row.read<String?>('category_name') ?? 'Unkategorisiert';
      final product = ProductNeedingUpdate(
        productId: row.read<int>('id'),
        productName: row.read<String>('name'),
        brand: row.read<String?>('brand'),
        categoryName: categoryName,
        storeName: storeName,
        lastPrice: 0,
        lastMonthYear: '',
      );

      grouped.putIfAbsent(storeName, () => {});
      grouped[storeName]!.putIfAbsent(categoryName, () => []);
      grouped[storeName]![categoryName]!.add(product);
    }

    return grouped;
  }
}
