import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'price_history_service.g.dart';

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
}
