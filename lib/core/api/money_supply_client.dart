import 'dart:convert' show LineSplitter, jsonDecode;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class MoneySupplyDataPoint {
  final DateTime month;
  final double value;

  const MoneySupplyDataPoint({required this.month, required this.value});
}

enum MoneySupplySource {
  swissNationalBank,
  europeanCentralBank,
  federalReserve,
  bankOfEngland,
}

MoneySupplySource? moneySupplySourceForCurrency(String currency) {
  switch (currency.toUpperCase()) {
    case 'CHF':
      return MoneySupplySource.swissNationalBank;
    case 'EUR':
      return MoneySupplySource.europeanCentralBank;
    case 'USD':
      return MoneySupplySource.federalReserve;
    case 'GBP':
      return MoneySupplySource.bankOfEngland;
    default:
      return null;
  }
}

class MoneySupplyClient {
  MoneySupplyClient(this._dio);

  final Dio _dio;

  static const _ecbM2Key = 'M.U2.Y.V.M20.X.1.U2.2300.Z01.E';
  static const _fredSeriesId = 'M2SL';
  static const _boeSeriesCode = 'LPMVWYW';

  Future<List<MoneySupplyDataPoint>> fetchMoneySupply(
    MoneySupplySource source, {
    required DateTime startMonth,
    required int observationCount,
  }) async {
    try {
      switch (source) {
        case MoneySupplySource.swissNationalBank:
          return _fetchSnb(startMonth);
        case MoneySupplySource.europeanCentralBank:
          return _fetchEcb(observationCount);
        case MoneySupplySource.federalReserve:
          return _fetchFred(startMonth);
        case MoneySupplySource.bankOfEngland:
          return _fetchBoe(startMonth);
      }
    } on DioException catch (error) {
      _logDioError(source, error);
      return [];
    } catch (error, stackTrace) {
      debugPrint('MoneySupplyClient error ($source): $error\n$stackTrace');
      return [];
    }
  }

  Future<List<MoneySupplyDataPoint>> _fetchEcb(int observationCount) async {
    final url =
        'https://data-api.ecb.europa.eu/service/data/BSI/$_ecbM2Key?format=jsondata&lastNObservations=$observationCount';
    final response = await _dio.get<String>(
      url,
      options: _jsonOptions(),
    );
    if (response.data == null) return [];

    final json = jsonDecode(response.data!) as Map<String, dynamic>;
    return _parseSdmxSeries(json);
  }

  Future<List<MoneySupplyDataPoint>> _fetchFred(DateTime startMonth) async {
    final url =
        'https://fred.stlouisfed.org/graph/fredgraph.csv?id=$_fredSeriesId&cosd=${_formatIsoDate(startMonth)}';
    final response = await _dio.get<String>(
      url,
      options: Options(
        sendTimeout: const Duration(seconds: 15),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.plain,
      ),
    );
    final csv = response.data;
    if (csv == null || csv.trim().isEmpty) return [];

    final rows = const LineSplitter().convert(csv);
    final result = <MoneySupplyDataPoint>[];
    for (final row in rows.skip(1)) {
      final columns = row.split(',');
      if (columns.length < 2) continue;
      final month = _parseIsoMonth(columns[0]);
      final value = _tryParseDouble(columns[1]);
      if (month == null || value == null) continue;
      result.add(MoneySupplyDataPoint(month: month, value: value));
    }
    return result;
  }

  Future<List<MoneySupplyDataPoint>> _fetchBoe(DateTime startMonth) async {
    final dateFrom = DateFormat('dd/MMM/yyyy', 'en_US').format(startMonth);
    final url =
        'https://www.bankofengland.co.uk/boeapps/database/_iadb-fromshowcolumns.asp?csv.x=yes&Datefrom=$dateFrom&Dateto=now&SeriesCodes=$_boeSeriesCode&CSVF=CN&UsingCodes=Y';
    final response = await _dio.get<String>(
      url,
      options: Options(
        sendTimeout: const Duration(seconds: 15),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.plain,
        headers: const {'User-Agent': 'Mozilla/5.0 InflaBasket/1.0'},
      ),
    );
    final csv = response.data;
    if (csv == null || csv.trim().isEmpty) return [];

    final rows = const LineSplitter().convert(csv);
    final result = <MoneySupplyDataPoint>[];
    for (final row in rows.skip(1)) {
      final columns = row.split(',');
      if (columns.length < 3) continue;
      final month = _parseBoeDate(columns[0]);
      final value = _tryParseDouble(columns[2]);
      if (month == null || value == null) continue;
      result.add(MoneySupplyDataPoint(month: month, value: value));
    }
    return result;
  }

  Future<List<MoneySupplyDataPoint>> _fetchSnb(DateTime startMonth) async {
    final propertiesResponse = await _dio.get<Map<String, dynamic>>(
      'https://data.snb.ch/json/application/properties',
      options: _jsonOptions(),
    );
    final properties = propertiesResponse.data;
    if (properties == null) return [];

    final queryParameters = <String, dynamic>{
      'lang': 'en',
      'pageViewTime': properties['pageViewTime'],
    };
    for (final key in ['applicationId', 'environmentId', 'userName']) {
      final value = properties[key];
      if (value != null) {
        queryParameters[key] = value;
      }
    }

    final response = await _dio.post<Map<String, dynamic>>(
      'https://data.snb.ch/json/chart/getAirchartConfigAndData',
      queryParameters: queryParameters,
      data: {'chartId': 'snbmonagglech', 'maxZoomOut': false},
      options: _jsonOptions(),
    );
    final json = response.data;
    if (json == null) return [];

    final rows =
        ((json['data'] as Map<String, dynamic>)['data'] as List<dynamic>?) ??
            const <dynamic>[];
    final result = <MoneySupplyDataPoint>[];
    for (final rawRow in rows) {
      final row = rawRow as List<dynamic>;
      if (row.length < 3 || row[1]?.toString() != 'M2') continue;
      final month = _parseYearMonth(row[0]?.toString());
      final value = _tryParseDouble(row[2]);
      if (month == null || value == null || month.isBefore(startMonth)) {
        continue;
      }
      result.add(MoneySupplyDataPoint(month: month, value: value));
    }
    return result;
  }

  List<MoneySupplyDataPoint> _parseSdmxSeries(Map<String, dynamic> json) {
    final result = <MoneySupplyDataPoint>[];
    try {
      final structure = json['structure'] as Map<String, dynamic>;
      final observationDimensions = (structure['dimensions']
          as Map<String, dynamic>)['observation'] as List<dynamic>;
      final timeValues = (observationDimensions.first
          as Map<String, dynamic>)['values'] as List<dynamic>;

      final seriesMap = ((json['dataSets'] as List<dynamic>).first
          as Map<String, dynamic>)['series'] as Map<String, dynamic>;
      if (seriesMap.isEmpty) return [];

      final observations = (seriesMap.values.first
          as Map<String, dynamic>)['observations'] as Map<String, dynamic>;

      for (final entry in observations.entries) {
        final index = int.tryParse(entry.key);
        if (index == null || index >= timeValues.length) continue;

        final observation = entry.value as List<dynamic>;
        final value =
            _tryParseDouble(observation.isEmpty ? null : observation.first);
        final time = timeValues[index] as Map<String, dynamic>;
        final month = _parseYearMonth(
          (time['id'] ?? time['name'])?.toString(),
        );
        if (month == null || value == null) continue;
        result.add(MoneySupplyDataPoint(month: month, value: value));
      }
    } catch (error) {
      debugPrint('MoneySupplyClient._parseSdmxSeries error: $error');
    }

    result.sort((a, b) => a.month.compareTo(b.month));
    return result;
  }

  Options _jsonOptions() {
    return Options(
      sendTimeout: const Duration(seconds: 15),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    );
  }

  DateTime? _parseIsoMonth(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month);
  }

  DateTime? _parseBoeDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final parsed = DateFormat('dd MMM yyyy', 'en_US').parseStrict(value);
      return DateTime(parsed.year, parsed.month);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseYearMonth(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length < 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    return DateTime(year, month);
  }

  String _formatIsoDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double? _tryParseDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final text = raw.toString().trim();
    if (text.isEmpty || text == '.') return null;
    return double.tryParse(text);
  }

  void _logDioError(MoneySupplySource source, DioException error) {
    final underlying = error.error;
    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'timeout',
      DioExceptionType.badCertificate => 'certificate',
      DioExceptionType.connectionError => 'connection',
      DioExceptionType.badResponse =>
        'http-${error.response?.statusCode ?? 'unknown'}',
      DioExceptionType.cancel => 'cancelled',
      DioExceptionType.unknown when underlying is HandshakeException =>
        'certificate',
      DioExceptionType.unknown when underlying is SocketException =>
        'connection',
      DioExceptionType.unknown => 'unknown',
    };
    final message = error.message ?? underlying?.toString() ?? 'request failed';
    debugPrint('MoneySupplyClient network error ($source/$kind): $message');
  }
}
