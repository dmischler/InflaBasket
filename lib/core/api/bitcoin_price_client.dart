import 'package:drift/drift.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/api/bitcoin_providers.dart';

class BtcPriceClient {
  final FallbackBitcoinPriceClient _fallbackClient;
  final AppDatabase _db;

  static const List<String> _supportedFiats = ['chf', 'eur', 'usd', 'gbp'];

  BtcPriceClient(
      {FallbackBitcoinPriceClient? fallbackClient, required AppDatabase db})
      : _fallbackClient = fallbackClient ?? FallbackBitcoinPriceClient(),
        _db = db;

  bool isSupportedFiat(String currency) {
    return _supportedFiats.contains(currency.toLowerCase());
  }

  String _metricKey(String currency) {
    return 'btc_${currency.toLowerCase()}';
  }

  Future<double?> fetchBtcPrice(String currency, DateTime date) async {
    if (!isSupportedFiat(currency)) {
      return null;
    }

    final cached = await _getCachedPrice(currency, date);
    if (cached != null) {
      return cached;
    }

    final price = await _fallbackClient.fetchPrice(currency, date: date);
    if (price != null && price > 0) {
      await _cachePrice(currency, date, price);
      return price;
    }

    return null;
  }

  Future<List<BtcPricePoint>> fetchBtcPriceRange(
    String currency,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!isSupportedFiat(currency)) {
      return [];
    }

    final prices =
        await _fallbackClient.fetchPriceRange(currency, startDate, endDate);
    if (prices.isNotEmpty) {
      await _cachePrices(currency, prices);
    }

    return prices;
  }

  Future<double?> _getCachedPrice(String currency, DateTime date) async {
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0);

    final query = _db.select(_db.externalSeriesCache)
      ..where((t) =>
          t.source.equals('btc_price') &
          t.currency.equals(currency.toLowerCase()) &
          t.metric.equals(_metricKey(currency)) &
          t.month.isBiggerOrEqualValue(monthStart) &
          t.month.isSmallerOrEqualValue(monthEnd));

    final results = await query.get();
    if (results.isEmpty) return null;

    final cached = results.firstWhere(
      (row) => _isValidForDate(row, date),
      orElse: () => results.first,
    );

    if (_isCacheValid(cached.fetchedAt, date)) {
      return cached.value;
    }

    return null;
  }

  bool _isValidForDate(ExternalSeriesCacheEntry entry, DateTime date) {
    final entryMonth = DateTime(entry.month.year, entry.month.month);
    final targetMonth = DateTime(date.year, date.month);
    return entryMonth.isAtSameMomentAs(targetMonth);
  }

  bool _isCacheValid(DateTime fetchedAt, DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      final age = now.difference(fetchedAt);
      return age.inMinutes < 2;
    }

    return true;
  }

  Future<void> _cachePrice(String currency, DateTime date, double price) async {
    final monthDate = DateTime(date.year, date.month, 1);

    await _db.into(_db.externalSeriesCache).insertOnConflictUpdate(
          ExternalSeriesCacheCompanion.insert(
            source: 'btc_price',
            currency: currency.toLowerCase(),
            metric: _metricKey(currency),
            month: monthDate,
            value: price,
            fetchedAt: DateTime.now(),
          ),
        );
  }

  Future<void> _cachePrices(String currency, List<BtcPricePoint> points) async {
    final uniqueByMonth = <String, BtcPricePoint>{};

    for (final point in points) {
      final key = '${point.date.year}-${point.date.month}';
      if (!uniqueByMonth.containsKey(key)) {
        uniqueByMonth[key] = point;
      }
    }

    final batch = <ExternalSeriesCacheCompanion>[];
    for (final point in uniqueByMonth.values) {
      final monthDate = DateTime(point.date.year, point.date.month, 1);
      batch.add(
        ExternalSeriesCacheCompanion.insert(
          source: 'btc_price',
          currency: currency.toLowerCase(),
          metric: _metricKey(currency),
          month: monthDate,
          value: point.price,
          fetchedAt: DateTime.now(),
        ),
      );
    }

    await _db.batch((b) {
      b.insertAllOnConflictUpdate(_db.externalSeriesCache, batch);
    });
  }

  Future<Map<String, double>> getCachedPriceMap(String currency) async {
    final query = _db.select(_db.externalSeriesCache)
      ..where((t) =>
          t.source.equals('btc_price') &
          t.currency.equals(currency.toLowerCase()) &
          t.metric.equals(_metricKey(currency)));

    final results = await query.get();

    final map = <String, double>{};
    for (final row in results) {
      final key = '${row.month.year}-${row.month.month}';
      map[key] = row.value;
    }
    return map;
  }
}

class BtcPricePoint {
  final DateTime date;
  final double price;

  BtcPricePoint({required this.date, required this.price});
}
