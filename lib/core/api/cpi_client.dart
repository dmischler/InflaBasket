import 'dart:convert';

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
/// **Swiss BFS:** Uses the SDMX-JSON REST API provided by the Swiss Federal
/// Statistical Office. Dataset: `prc_hicp_mv12r` (monthly HICP, 12-month
/// moving average, total). Country filter: CH.
///
/// **Eurostat:** Uses the Eurostat SDMX-JSON REST API.
/// Dataset: `prc_hicp_mv12r` (monthly HICP, 12-month moving average, total).
/// Country filter: EU27_2020 (EU aggregate).
///
/// Both endpoints return an index series that can be plotted directly
/// alongside the user's basket index on the same chart.
class CpiClient {
  final Dio _dio;

  CpiClient(this._dio);

  // ─── Swiss BFS ─────────────────────────────────────────────────────────────
  // SDMX REST endpoint for Swiss HICP (Harmonised Index of Consumer Prices).
  // The BFS mirrors Eurostat's data for Switzerland (CH). We request the last
  // 24 monthly observations so the chart always has enough history.
  static const _bfsUrl =
      'https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_PRICES@DF_PRICES_ALL,1.0/'
      'CHE.M.HICP.PA._T.IX.N'
      '?startPeriod=2020-01&format=jsondata&dimensionAtObservation=AllDimensions';

  // ─── Eurostat ───────────────────────────────────────────────────────────────
  // Eurostat SDMX-JSON for HICP monthly data, EU27 aggregate, all-items (CP00).
  static const _eurostatUrl =
      'https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/'
      'prc_hicp_mmor?geo=EU27_2020&coicop=CP00&unit=RCH_MOM&format=JSON';

  /// Fetches CPI data for [source]. Returns an empty list on any error so the
  /// chart simply hides the overlay rather than crashing.
  Future<List<CpiDataPoint>> fetchCpi(CpiSource source) async {
    try {
      switch (source) {
        case CpiSource.swissBfs:
          return await _fetchBfs();
        case CpiSource.eurostat:
          return await _fetchEurostat();
      }
    } catch (e, st) {
      debugPrint('CpiClient error ($source): $e\n$st');
      return [];
    }
  }

  Future<List<CpiDataPoint>> _fetchBfs() async {
    final response = await _dio.get<String>(_bfsUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ));
    if (response.data == null) return [];
    final json = jsonDecode(response.data!) as Map<String, dynamic>;
    return _parseOecdSdmx(json);
  }

  Future<List<CpiDataPoint>> _fetchEurostat() async {
    final response = await _dio.get<String>(_eurostatUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ));
    if (response.data == null) return [];
    final json = jsonDecode(response.data!) as Map<String, dynamic>;
    return _parseEurostatSdmx(json);
  }

  /// Parses OECD SDMX-JSON format into [CpiDataPoint] list.
  List<CpiDataPoint> _parseOecdSdmx(Map<String, dynamic> json) {
    final result = <CpiDataPoint>[];
    try {
      final dataSets = json['dataSets'] as List<dynamic>;
      if (dataSets.isEmpty) return [];
      final observations =
          (dataSets[0] as Map<String, dynamic>)['observations']
              as Map<String, dynamic>;

      final structure = json['structure'] as Map<String, dynamic>;
      final dimensions =
          (structure['dimensions'] as Map<String, dynamic>)['observation']
              as List<dynamic>;

      // Find the TIME_PERIOD dimension to map indices → YYYY-MM strings
      final timeDim = dimensions.firstWhere(
        (d) => (d as Map<String, dynamic>)['id'] == 'TIME_PERIOD',
        orElse: () => null,
      ) as Map<String, dynamic>?;
      if (timeDim == null) return [];

      final timeValues =
          (timeDim['values'] as List<dynamic>).map((v) => v['id'] as String).toList();

      for (final entry in observations.entries) {
        final indices = entry.key.split(':');
        // TIME_PERIOD is the last dimension in AllDimensions layout
        final timeIdx = int.tryParse(indices.last);
        if (timeIdx == null || timeIdx >= timeValues.length) continue;

        final timeStr = timeValues[timeIdx]; // e.g. "2024-03"
        final month = _parseYearMonth(timeStr);
        if (month == null) continue;

        final values = entry.value as List<dynamic>;
        final value = (values.isNotEmpty && values[0] != null)
            ? (values[0] as num).toDouble()
            : null;
        if (value == null) continue;

        result.add(CpiDataPoint(month: month, index: value));
      }
    } catch (e) {
      debugPrint('CpiClient._parseOecdSdmx error: $e');
    }
    result.sort((a, b) => a.month.compareTo(b.month));
    return result;
  }

  /// Parses Eurostat SDMX-JSON format into [CpiDataPoint] list.
  List<CpiDataPoint> _parseEurostatSdmx(Map<String, dynamic> json) {
    final result = <CpiDataPoint>[];
    try {
      final dimension = json['dimension'] as Map<String, dynamic>;
      final timeDim = dimension['time'] as Map<String, dynamic>;
      final timeCategory =
          (timeDim['category'] as Map<String, dynamic>)['label']
              as Map<String, dynamic>;

      // timeCategory maps index-string → "YYYY-MM"
      final timeMap = <int, String>{};
      timeCategory.forEach((key, value) {
        final idx = int.tryParse(key);
        if (idx != null) timeMap[idx] = value as String;
      });

      final value = json['value'] as Map<String, dynamic>;
      for (final entry in value.entries) {
        final idx = int.tryParse(entry.key);
        if (idx == null) continue;
        final timeStr = timeMap[idx];
        if (timeStr == null) continue;
        final month = _parseYearMonth(timeStr);
        if (month == null) continue;
        final v = (entry.value as num?)?.toDouble();
        if (v == null) continue;
        result.add(CpiDataPoint(month: month, index: v));
      }
    } catch (e) {
      debugPrint('CpiClient._parseEurostatSdmx error: $e');
    }
    result.sort((a, b) => a.month.compareTo(b.month));
    return result;
  }

  /// Parses "YYYY-MM" or "YYYY-M" into a [DateTime] at the 1st of that month.
  DateTime? _parseYearMonth(String s) {
    final parts = s.split('-');
    if (parts.length < 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    return DateTime(year, month);
  }
}
