import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A single CPI (Consumer Price Index) data point: a month and its index value.
/// The base year index = 100 per the source definition.
class CpiDataPoint {
  final DateTime month;

  /// Index value where the base period = 100.
  final double index;

  const CpiDataPoint({required this.month, required this.index});
}

/// Identifies which national CPI source to use.
enum CpiSource {
  /// Swiss Federal Statistical Office (BFS) – used when currency is CHF.
  swissBfs,

  /// Eurostat HICP – used when currency is EUR.
  eurostat,
}

class ComparisonDataPoint {
  final DateTime month;
  final double index;

  const ComparisonDataPoint({required this.month, required this.index});
}

@visibleForTesting
List<CpiDataPoint> parseCpiSdmxSeries(Map<String, dynamic> json) {
  final result = <CpiDataPoint>[];
  try {
    final structure = json['structure'] as Map<String, dynamic>;
    final observationDimensions = (structure['dimensions']
        as Map<String, dynamic>)['observation'] as List<dynamic>;
    final timeValues = (observationDimensions.first
        as Map<String, dynamic>)['values'] as List<dynamic>;

    final seriesMap = ((json['dataSets'] as List<dynamic>).first
        as Map<String, dynamic>)['series'] as Map<String, dynamic>;
    if (seriesMap.isEmpty) return const [];

    final observations = (seriesMap.values.first
        as Map<String, dynamic>)['observations'] as Map<String, dynamic>;

    for (final entry in observations.entries) {
      final index = int.tryParse(entry.key);
      if (index == null || index >= timeValues.length) continue;
      final observation = entry.value as List<dynamic>;
      final time = timeValues[index] as Map<String, dynamic>;
      final month =
          parseYearMonthId(((time['id'] ?? time['name'])?.toString()) ?? '');
      final value =
          parseDoubleValue(observation.isEmpty ? null : observation.first);
      if (month == null || value == null) continue;
      result.add(CpiDataPoint(month: month, index: value));
    }
  } catch (e) {
    debugPrint('parseCpiSdmxSeries error: $e');
  }
  result.sort((a, b) => a.month.compareTo(b.month));
  return result;
}

DateTime? parseYearMonthId(String s) {
  final parts = s.split('-');
  if (parts.length < 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return null;
  return DateTime(year, month);
}

double? parseDoubleValue(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

/// Returns the appropriate [CpiSource] for a given currency code, or null
/// if no CPI comparison is available for that currency.
CpiSource? cpiSourceForCurrency(String currency) {
  switch (currency.toUpperCase()) {
    case 'CHF':
      return CpiSource.swissBfs;
    case 'EUR':
      return CpiSource.eurostat;
    default:
      return null; // USD, GBP – no supported CPI source
  }
}

/// Fetches and caches national CPI data from the appropriate source.
///
/// **Swiss CPI:** Uses Eurostat's monthly HICP index endpoint scoped to
/// Switzerland (`geo=CH`, `unit=I15`, all-items `CP00`).
///
/// **Eurostat:** Uses the same monthly HICP index endpoint scoped to the EU27
/// aggregate (`geo=EU27_2020`, `unit=I15`, all-items `CP00`).
///
/// Both endpoints return an index series that can be plotted directly
/// alongside the user's basket index on the same chart.
class CpiClient {
  final Dio _dio;

  CpiClient(this._dio);

  static const _defaultObservationCount = 24;

  // ─── Switzerland ───────────────────────────────────────────────────────────
  // Eurostat HICP monthly index for Switzerland, all-items, base 2015 = 100.
  static const _bfsUrl =
      'https://ec.europa.eu/eurostat/api/dissemination/sdmx/3.0/data/'
      'dataflow/ESTAT/prc_hicp_midx/1.0/M.I15.CP00.CH';

  // ─── Eurostat ───────────────────────────────────────────────────────────────
  // Eurostat HICP monthly index for the EU27 aggregate, all-items, base 2015 = 100.
  static const _eurostatUrl =
      'https://ec.europa.eu/eurostat/api/dissemination/sdmx/3.0/data/'
      'dataflow/ESTAT/prc_hicp_midx/1.0/M.I15.CP00.EU27_2020';

  /// Fetches CPI data for [source]. Returns an empty list on any error so the
  /// chart simply hides the overlay rather than crashing.
  Future<List<CpiDataPoint>> fetchCpi(
    CpiSource source, {
    int observationCount = _defaultObservationCount,
  }) async {
    try {
      switch (source) {
        case CpiSource.swissBfs:
          return await _fetchBfs(observationCount);
        case CpiSource.eurostat:
          return await _fetchEurostat(observationCount);
      }
    } on DioException catch (e) {
      _logDioError(source, e);
      return [];
    } catch (e, st) {
      debugPrint('CpiClient error ($source): $e\n$st');
      return [];
    }
  }

  Future<List<CpiDataPoint>> _fetchBfs(int observationCount) async {
    final response = await _dio.get<String>(
        '$_bfsUrl?format=json&lastNObservations=$observationCount',
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ));
    if (response.data == null) return [];
    final json = jsonDecode(response.data!) as Map<String, dynamic>;
    return _parseSdmxSeries(json);
  }

  Future<List<CpiDataPoint>> _fetchEurostat(int observationCount) async {
    final response = await _dio.get<String>(
        '$_eurostatUrl?format=json&lastNObservations=$observationCount',
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ));
    if (response.data == null) return [];
    final json = jsonDecode(response.data!) as Map<String, dynamic>;
    return _parseSdmxSeries(json);
  }

  List<CpiDataPoint> _parseSdmxSeries(Map<String, dynamic> json) {
    return parseCpiSdmxSeries(json);
  }

  void _logDioError(CpiSource source, DioException error) {
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
    debugPrint('CpiClient network error ($source/$kind): $message');
  }
}
