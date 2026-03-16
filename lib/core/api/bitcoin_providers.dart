import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:inflabasket/core/api/bitcoin_price_client.dart';

abstract class BitcoinPriceProvider {
  String get name;
  Future<double?> fetchPrice(String currency, {DateTime? date});
  Future<List<BtcPricePoint>> fetchPriceRange(
      String currency, DateTime start, DateTime end);
}

class BinanceProvider implements BitcoinPriceProvider {
  final Dio _dio;
  BinanceProvider({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.binance.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get name => 'Binance';

  String _getSymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return 'BTCUSDT';
      case 'EUR':
        return 'BTCEUR';
      case 'GBP':
        return 'BTCGBP';
      case 'CHF':
        return 'BTCCHF';
      default:
        return 'BTCUSDT';
    }
  }

  @override
  Future<double?> fetchPrice(String currency, {DateTime? date}) async {
    final symbol = _getSymbol(currency);

    try {
      if (date == null) {
        final response = await _dio.get(
          '/api/v3/ticker/price',
          queryParameters: {'symbol': symbol},
        );
        if (response.statusCode == 200) {
          final priceStr = response.data['price'] as String?;
          final price = double.tryParse(priceStr ?? '');
          return price;
        }
      } else {
        final startTime = _dateToMilliseconds(date);
        final response = await _dio.get(
          '/api/v3/klines',
          queryParameters: {
            'symbol': symbol,
            'interval': '1d',
            'startTime': startTime,
            'limit': 1,
          },
        );
        if (response.statusCode == 200 && (response.data as List).isNotEmpty) {
          final candle = response.data[0] as List;
          final close = double.tryParse(candle[4] as String) ?? 0.0;
          return close;
        }
      }
    } on DioException catch (e) {
      _logError('fetchPrice', e, 'currency: $currency, date: $date');
    }
    return null;
  }

  @override
  Future<List<BtcPricePoint>> fetchPriceRange(
      String currency, DateTime start, DateTime end) async {
    final symbol = _getSymbol(currency);
    final startTime = _dateToMilliseconds(start);
    final endTime = _dateToMilliseconds(end);

    try {
      final response = await _dio.get(
        '/api/v3/klines',
        queryParameters: {
          'symbol': symbol,
          'interval': '1d',
          'startTime': startTime,
          'endTime': endTime,
          'limit': 1000,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        final points = <BtcPricePoint>[];

        for (final candle in data) {
          if (candle is List && candle.length >= 5) {
            final ts = (candle[0] as int);
            final close = double.tryParse(candle[4] as String) ?? 0.0;
            final date = DateTime.fromMillisecondsSinceEpoch(ts);
            points.add(BtcPricePoint(date: date, price: close));
          }
        }
        return points;
      }
    } on DioException catch (e) {
      _logError('fetchPriceRange', e,
          'currency: $currency, start: $start, end: $end');
    }
    return [];
  }

  int _dateToMilliseconds(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0, 0)
        .toUtc()
        .millisecondsSinceEpoch;
  }

  void _logError(String method, DioException e, String context) {
    final statusCode = e.response?.statusCode;
    final message = e.message ?? 'unknown';
    debugPrint(
        '[BinanceProvider] $method error ($context): $statusCode - $message');
  }
}

class OkxProvider implements BitcoinPriceProvider {
  final Dio _dio;
  OkxProvider({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://www.okx.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get name => 'OKX';

  @override
  Future<double?> fetchPrice(String currency, {DateTime? date}) async {
    if (currency.toUpperCase() != 'USD') {
      return null;
    }

    try {
      if (date == null) {
        final response = await _dio.get(
          '/api/v5/market/ticker',
          queryParameters: {'instId': 'BTC-USDT'},
        );
        if (response.statusCode == 200) {
          final data = response.data as List;
          if (data.isNotEmpty && data[0] is List) {
            final ticks = data[0] as List;
            if (ticks.length >= 5) {
              final last = double.tryParse(ticks[1] as String) ?? 0.0;
              return last;
            }
          }
        }
      } else {
        final timestamp =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-00:00:00';
        final response = await _dio.get(
          '/api/v5/market/history-candles',
          queryParameters: {
            'instId': 'BTC-USDT',
            'bar': '1D',
            'after': timestamp,
            'limit': 1,
          },
        );
        if (response.statusCode == 200) {
          final data = response.data as List;
          if (data.isNotEmpty && data[0] is List) {
            final candles = data[0] as List;
            if (candles.isNotEmpty) {
              final close = double.tryParse(candles.last as String) ?? 0.0;
              return close;
            }
          }
        }
      }
    } on DioException catch (e) {
      _logError('fetchPrice', e, 'currency: $currency, date: $date');
    }
    return null;
  }

  @override
  Future<List<BtcPricePoint>> fetchPriceRange(
      String currency, DateTime start, DateTime end) async {
    if (currency.toUpperCase() != 'USD') {
      return [];
    }

    try {
      final startTs = _dateToTimestamp(start);
      final endTs = _dateToTimestamp(end);

      final response = await _dio.get(
        '/api/v5/market/history-candles',
        queryParameters: {
          'instId': 'BTC-USDT',
          'bar': '1D',
          'after': endTs,
          'before': startTs,
          'limit': 100,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        if (data.isNotEmpty && data[0] is List) {
          final candles = data[0] as List;
          final points = <BtcPricePoint>[];

          for (final c in candles) {
            if (c is List && c.length >= 5) {
              final tsStr = c[0] as String;
              final close = double.tryParse(c[4] as String) ?? 0.0;
              final ts = DateTime.parse(tsStr).millisecondsSinceEpoch;
              final date = DateTime.fromMillisecondsSinceEpoch(ts);
              points.add(BtcPricePoint(date: date, price: close));
            }
          }
          return points.reversed.toList();
        }
      }
    } on DioException catch (e) {
      _logError('fetchPriceRange', e,
          'currency: $currency, start: $start, end: $end');
    }
    return [];
  }

  String _dateToTimestamp(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-00:00:00';
  }

  void _logError(String method, DioException e, String context) {
    final statusCode = e.response?.statusCode;
    final message = e.message ?? 'unknown';
    debugPrint(
        '[OkxProvider] $method error ($context): $statusCode - $message');
  }
}

class CoinPaprikaProvider implements BitcoinPriceProvider {
  final Dio _dio;
  CoinPaprikaProvider({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.coinpaprika.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get name => 'CoinPaprika';

  @override
  Future<double?> fetchPrice(String currency, {DateTime? date}) async {
    final prices = await fetchPriceRange(
      currency,
      date ?? DateTime.now(),
      date ?? DateTime.now(),
    );
    return prices.isNotEmpty ? prices.first.price : null;
  }

  @override
  Future<List<BtcPricePoint>> fetchPriceRange(
      String currency, DateTime start, DateTime end) async {
    try {
      final startStr = _formatDate(start);
      final endStr = _formatDate(end.add(const Duration(days: 1)));

      final response = await _dio.get(
        '/v1/coins/btc-bitcoin/ohlcv/historical',
        queryParameters: {
          'start': startStr,
          'end': endStr,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        final points = <BtcPricePoint>[];

        for (final item in data) {
          if (item is Map) {
            final time = item['time'] as int?;
            final close = (item['close'] as num?)?.toDouble();
            if (time != null && close != null) {
              final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
              points.add(BtcPricePoint(date: date, price: close));
            }
          }
        }
        return points;
      }
    } on DioException catch (e) {
      _logError('fetchPriceRange', e,
          'currency: $currency, start: $start, end: $end');
    }
    return [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _logError(String method, DioException e, String context) {
    final statusCode = e.response?.statusCode;
    final message = e.message ?? 'unknown';
    debugPrint(
        '[CoinPaprikaProvider] $method error ($context): $statusCode - $message');
  }
}

class FiatExchangeProvider {
  final Dio _dio;
  final Map<String, Map<String, double>> _cache = {};

  FiatExchangeProvider({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.frankfurter.dev',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  bool isSupported(String currency) {
    final supported = ['CHF', 'EUR', 'USD', 'GBP'];
    return supported.contains(currency.toUpperCase());
  }

  Future<double?> getRate(String from, String to, DateTime date) async {
    if (from.toUpperCase() == to.toUpperCase()) {
      return 1.0;
    }

    final cacheKey = '${date.year}-${date.month}-${date.day}';
    if (_cache.containsKey(cacheKey)) {
      final rates = _cache[cacheKey]!;
      final pairKey = '${from.toUpperCase()}_${to.toUpperCase()}';
      return rates[pairKey];
    }

    try {
      final dateStr = _isToday(date)
          ? 'latest'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _dio.get(
        '/v1/$dateStr',
        queryParameters: {
          'from': from.toUpperCase(),
          'to': to.toUpperCase(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null) {
          final rate = (rates[to.toUpperCase()] as num?)?.toDouble();
          if (rate != null) {
            _cache[cacheKey] ??= {};
            _cache[cacheKey]!['${from.toUpperCase()}_${to.toUpperCase()}'] =
                rate;
            return rate;
          }
        }
      }
    } on DioException catch (e) {
      _logError('getRate', e, 'from: $from, to: $to, date: $date');
    }
    return null;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _logError(String method, DioException e, String context) {
    final statusCode = e.response?.statusCode;
    final message = e.message ?? 'unknown';
    debugPrint(
        '[FiatExchangeProvider] $method error ($context): $statusCode - $message');
  }
}

class FallbackBitcoinPriceClient {
  final BinanceProvider _binance = BinanceProvider();
  final OkxProvider _okx = OkxProvider();
  final CoinPaprikaProvider _coinPaprika = CoinPaprikaProvider();
  final FiatExchangeProvider _fiatExchange = FiatExchangeProvider();

  final List<BitcoinPriceProvider> _providers = [];

  FallbackBitcoinPriceClient() {
    _providers.addAll([_binance, _okx, _coinPaprika]);
  }

  Future<double?> fetchPrice(String currency, {DateTime? date}) async {
    final normalizedCurrency = currency.toUpperCase();

    for (final provider in _providers) {
      final price = await provider.fetchPrice(normalizedCurrency, date: date);
      if (price != null && price > 0) {
        _logSuccess(provider.name, 'fetchPrice', currency, date);
        return price;
      }
    }

    if (normalizedCurrency != 'USD') {
      final usdPrice = await fetchPrice('USD', date: date);
      if (usdPrice != null && usdPrice > 0) {
        final rate = await _fiatExchange.getRate(
            'USD', normalizedCurrency, date ?? DateTime.now());
        if (rate != null && rate > 0) {
          _logSuccess(
              'FiatExchange', 'fetchPrice (USD fallback)', currency, date);
          return usdPrice * rate;
        }
      }
    }

    debugPrint(
        '[FallbackBitcoinPriceClient] All providers failed for $currency');
    return null;
  }

  Future<List<BtcPricePoint>> fetchPriceRange(
      String currency, DateTime start, DateTime end) async {
    final normalizedCurrency = currency.toUpperCase();

    for (final provider in _providers) {
      final prices =
          await provider.fetchPriceRange(normalizedCurrency, start, end);
      if (prices.isNotEmpty) {
        _logSuccess(provider.name, 'fetchPriceRange', currency, null);
        return prices;
      }
    }

    if (normalizedCurrency != 'USD') {
      final usdPrices = await fetchPriceRange('USD', start, end);
      if (usdPrices.isNotEmpty) {
        final rate = await _fiatExchange.getRate(
            'USD', normalizedCurrency, DateTime.now());
        if (rate != null && rate > 0) {
          _logSuccess(
              'FiatExchange', 'fetchPriceRange (USD fallback)', currency, null);
          return usdPrices
              .map((p) => BtcPricePoint(date: p.date, price: p.price * rate))
              .toList();
        }
      }
    }

    debugPrint(
        '[FallbackBitcoinPriceClient] All providers failed for range $currency');
    return [];
  }

  void _logSuccess(
      String provider, String method, String currency, DateTime? date) {
    final dateStr =
        date != null ? '${date.year}-${date.month}-${date.day}' : 'live';
    debugPrint(
        '[FallbackBitcoinPriceClient] $provider succeeded: $method($currency, $dateStr)');
  }
}
