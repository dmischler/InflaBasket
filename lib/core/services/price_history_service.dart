import 'dart:math' as math;

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
  return PriceHistoryService(
    ref.watch(appDatabaseProvider),
    ref.watch(entryRepositoryProvider),
  );
}

class PriceHistoryService {
  final AppDatabase _db;
  final EntryRepository _entryRepo;
  PriceHistoryService(this._db, this._entryRepo);

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
    String storeName = '',
    String currency = 'CHF',
  }) async {
    final monthYear = formatMonthYear(date ?? DateTime.now());
    final purchaseDate = date ?? DateTime.now();

    final priceHistoryId = await _db.into(_db.priceHistories).insert(
          PriceHistoriesCompanion.insert(
            productId: productId,
            price: price,
            monthYear: monthYear,
            createdAt: DateTime.now(),
          ),
        );

    await _entryRepo.addPurchaseEntry(
      productId: productId,
      storeName: storeName,
      purchaseDate: purchaseDate,
      price: price,
      quantity: 1.0,
      currency: currency,
    );

    return priceHistoryId;
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

  DateTime _getCutoffDate(int months) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month - months;

    while (month <= 0) {
      month += 12;
      year -= 1;
    }

    return DateTime(year, month, 1);
  }

  DateTime _getNextReminderDueDate(DateTime purchaseDate, int months) {
    final targetMonthIndex = purchaseDate.month + months;
    final yearOffset = (targetMonthIndex - 1) ~/ 12;
    final normalizedMonth = ((targetMonthIndex - 1) % 12) + 1;
    final targetYear = purchaseDate.year + yearOffset;

    final nextMonthFirstDay = DateTime(targetYear, normalizedMonth + 1, 1);
    final lastDayOfTargetMonth =
        nextMonthFirstDay.subtract(const Duration(days: 1)).day;
    final clampedDay = math.min(purchaseDate.day, lastDayOfTargetMonth);

    final thresholdMonthDate = DateTime(
      targetYear,
      normalizedMonth,
      clampedDay,
    );

    return DateTime(
      thresholdMonthDate.year,
      thresholdMonthDate.month + 1,
      1,
      9,
    );
  }

  Future<Map<String, Map<String, List<ProductNeedingUpdate>>>>
      getProductsNeedingUpdate(int months) async {
    final cutoffDate = _getCutoffDate(months);

    final results = await _db.customSelect('''
      SELECT 
        p.id as product_id,
        p.name as product_name,
        p.brand,
        c.name as category_name,
        pe.store_name,
        pe.price as last_price,
        strftime('%Y-%m', pe.purchase_date) as last_month_year
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
      INNER JOIN (
        SELECT product_id, MAX(purchase_date) as max_purchase_date
        FROM purchase_entries
        GROUP BY product_id
      ) latest ON p.id = latest.product_id
      INNER JOIN purchase_entries pe ON 
        pe.product_id = p.id AND pe.purchase_date = latest.max_purchase_date
      WHERE pe.purchase_date < ?
      ORDER BY pe.store_name, c.name, p.name
    ''', variables: [Variable<DateTime>(cutoffDate)]).get();

    final Map<String, Map<String, List<ProductNeedingUpdate>>> grouped = {};

    for (final row in results) {
      final storeName = row.read<String?>('store_name') ?? 'Andere';
      final categoryName =
          row.read<String?>('category_name') ?? 'Unkategorisiert';
      final product = ProductNeedingUpdate(
        productId: row.read<int>('product_id'),
        productName: row.read<String?>('product_name') ?? 'Unbekannt',
        brand: row.read<String?>('brand'),
        categoryName: categoryName,
        storeName: storeName,
        lastPrice: row.read<double?>('last_price') ?? 0.0,
        lastMonthYear: row.read<String?>('last_month_year') ?? '',
      );

      grouped.putIfAbsent(storeName, () => {});
      grouped[storeName]!.putIfAbsent(categoryName, () => []);
      grouped[storeName]![categoryName]!.add(product);
    }

    return grouped;
  }

  Future<int> getStaleProductCount(int months) async {
    final cutoffDate = _getCutoffDate(months);

    final result = await _db.customSelect(
      '''
      SELECT COUNT(DISTINCT p.id) as count
      FROM products p
      INNER JOIN (
        SELECT product_id, MAX(purchase_date) as max_purchase_date
        FROM purchase_entries
        GROUP BY product_id
      ) latest ON p.id = latest.product_id
      INNER JOIN purchase_entries pe ON 
        pe.product_id = p.id AND pe.purchase_date = latest.max_purchase_date
      WHERE pe.purchase_date < ?
      ''',
      variables: [Variable<DateTime>(cutoffDate)],
    ).getSingle();

    return result.read<int>('count');
  }

  Future<DateTime?> getNextProductDueDate(int months) async {
    final now = DateTime.now();
    final results = await _db.customSelect(
      '''
      SELECT pe.purchase_date as latest_purchase_date
      FROM products p
      INNER JOIN (
        SELECT product_id, MAX(purchase_date) as max_purchase_date
        FROM purchase_entries
        GROUP BY product_id
      ) latest ON p.id = latest.product_id
      INNER JOIN purchase_entries pe ON
        pe.product_id = p.id AND pe.purchase_date = latest.max_purchase_date
      ''',
    ).get();

    DateTime? earliestDueDate;
    for (final row in results) {
      final latestPurchaseDate = row.read<DateTime?>('latest_purchase_date');
      if (latestPurchaseDate == null) {
        continue;
      }

      final dueDate = _getNextReminderDueDate(latestPurchaseDate, months);
      if (!dueDate.isAfter(now)) {
        continue;
      }

      if (earliestDueDate == null || dueDate.isBefore(earliestDueDate)) {
        earliestDueDate = dueDate;
      }
    }

    return earliestDueDate;
  }
}
