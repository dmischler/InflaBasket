import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:inflabasket/core/api/cpi_client.dart';

/// Fetches Swiss inflation data from the SNB Data Portal API.
///
/// **SNB Data Portal:** Free, public API returning clean JSON.
/// No API key required.
///
/// Base URL: https://data.snb.ch/api
///
/// Key cubes:
/// - snbiprogq: Inflation forecasts (includes observed data + forecasts)
/// - plkoprex: Core inflation and supplementary classifications
class SnbClient {
  final Dio _dio;

  SnbClient(this._dio);

  static const _baseUrl = 'https://data.snb.ch/api/cube';

  /// Fetches CPI data from SNB.
  /// Uses the snbiprogq cube which contains both observed data and forecasts.
  /// We only return "Observed inflation" data, ignoring forecasts.
  ///
  /// Returns quarterly data, then interpolated to monthly for consistency.
  ///
  /// Debug: prints fetched data to console.
  Future<List<CpiDataPoint>> fetchCpi({
    required DateTime startMonth,
    int observationCount = 24,
  }) async {
    try {
      // snbiprogq returns quarterly data
      // Calculate fromDate based on observation count (quarters)
      final fromDate = _calculateFromDate(startMonth, observationCount);
      final toDate = _formatQuarter(DateTime.now());

      final response = await _dio.get<String>(
        '$_baseUrl/snbiprogq/data/json/en',
        queryParameters: {
          'fromDate': fromDate,
          'toDate': toDate,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.data == null) return [];
      final json = jsonDecode(response.data!) as Map<String, dynamic>;

      // Debug: Print summary of available series
      final timeseries = json['timeseries'] as List<dynamic>?;
      if (timeseries != null) {
        for (final series in timeseries.take(5)) {
          final header = (series as Map<String, dynamic>)['header'] as List?;
          if (header != null) {
            for (final h in header) {
              final hMap = h as Map<String, dynamic>;
              if (hMap['dim'] == 'Overview') {
                debugPrint(
                    'SNB CPI: Found series with Overview = "${hMap['dimItem']}"');
              }
            }
          }
        }
      }

      return _parseSnbCpiSeries(json);
    } on DioException catch (e) {
      _logDioError('snbiprogq', e);
      return [];
    } catch (e, st) {
      debugPrint('SnbClient error (CPI): $e\n$st');
      return [];
    }
  }

  /// Fetches Core Inflation 1 data from SNB.
  /// Uses the plkoprex cube, K1 series.
  /// Core inflation excludes energy and fresh food.
  ///
  /// Returns monthly data (base: December 2025 = 100).
  Future<List<CpiDataPoint>> fetchCoreInflation1({
    required DateTime startMonth,
    int observationCount = 24,
  }) async {
    try {
      final fromDate = _formatYearMonth(startMonth);
      final toDate = _formatYearMonth(DateTime.now());

      final response = await _dio.get<String>(
        '$_baseUrl/plkoprex/data/json/en',
        queryParameters: {
          'fromDate': fromDate,
          'toDate': toDate,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.data == null) return [];
      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      return _parseSnbCoreInflationSeries(json);
    } on DioException catch (e) {
      _logDioError('plkoprex', e);
      return [];
    } catch (e, st) {
      debugPrint('SnbClient error (Core): $e\n$st');
      return [];
    }
  }

  /// Parse snbiprogq response - extract only "Observed inflation", not forecasts.
  List<CpiDataPoint> _parseSnbCpiSeries(Map<String, dynamic> json) {
    final result = <CpiDataPoint>[];

    try {
      final timeseries = json['timeseries'] as List<dynamic>?;
      if (timeseries == null || timeseries.isEmpty) return const [];

      // Find the "Observed inflation" series
      // Header is an array of {dim, dimItem} objects - find where dim == "Overview"
      final observedSeries = timeseries.cast<Map<String, dynamic>>().firstWhere(
        (series) {
          final header = series['header'] as List<dynamic>?;
          if (header == null || header.isEmpty) return false;

          // Find the "Overview" dimension entry
          String? dimItem;
          for (final h in header) {
            final hMap = h as Map<String, dynamic>;
            if (hMap['dim'] == 'Overview') {
              dimItem = hMap['dimItem'] as String?;
              break;
            }
          }
          return dimItem?.toLowerCase().contains('observed') ?? false;
        },
        orElse: () => const <String, dynamic>{},
      );

      if (observedSeries.isEmpty) return const [];

      final metadata = observedSeries['metadata'] as Map<String, dynamic>?;
      final frequency = metadata?['frequency'] as String?;
      final values = observedSeries['values'] as List<dynamic>? ?? const [];

      for (final valueEntry in values.cast<Map<String, dynamic>>()) {
        final date = valueEntry['date'] as String?;
        final value = valueEntry['value'] as num?;

        if (date == null || value == null) continue;

        final parsedDate = _parseSnbDate(date, frequency);
        if (parsedDate != null) {
          result.add(CpiDataPoint(
            month: parsedDate,
            index: value.toDouble(),
          ));
        }
      }

      // Sort by date
      result.sort((a, b) => a.month.compareTo(b.month));

      // Convert quarterly to monthly via interpolation
      return _expandQuarterlyToMonthly(result);
    } catch (e) {
      debugPrint('parseSnbCpiSeries error: $e');
    }

    return result;
  }

  /// Parse plkoprex response - extract Core inflation 1.
  List<CpiDataPoint> _parseSnbCoreInflationSeries(Map<String, dynamic> json) {
    final result = <CpiDataPoint>[];

    try {
      final timeseries = json['timeseries'] as List<dynamic>?;
      if (timeseries == null || timeseries.isEmpty) return const [];

      // Find the "Core inflation 1" series (K1)
      // Header is an array of {dim, dimItem} objects - find where dim == "Overview"
      final coreSeries = timeseries.cast<Map<String, dynamic>>().firstWhere(
        (series) {
          final header = series['header'] as List<dynamic>?;
          if (header == null || header.isEmpty) return false;

          // Find the "Overview" dimension entry
          String? dimItem;
          for (final h in header) {
            final hMap = h as Map<String, dynamic>;
            if (hMap['dim'] == 'Overview') {
              dimItem = hMap['dimItem'] as String?;
              break;
            }
          }
          return dimItem?.toLowerCase().contains('core inflation 1') ?? false;
        },
        orElse: () => const <String, dynamic>{},
      );

      if (coreSeries.isEmpty) return const [];

      final metadata = coreSeries['metadata'] as Map<String, dynamic>?;
      final frequency = metadata?['frequency'] as String?;
      final values = coreSeries['values'] as List<dynamic>? ?? const [];

      for (final valueEntry in values.cast<Map<String, dynamic>>()) {
        final date = valueEntry['date'] as String?;
        final value = valueEntry['value'] as num?;

        if (date == null || value == null) continue;

        final parsedDate = _parseSnbDate(date, frequency);
        if (parsedDate != null) {
          result.add(CpiDataPoint(
            month: parsedDate,
            index: value.toDouble(),
          ));
        }
      }

      // Sort by date
      result.sort((a, b) => a.month.compareTo(b.month));
    } catch (e) {
      debugPrint('parseSnbCoreInflationSeries error: $e');
    }

    return result;
  }

  /// Parse SNB date strings.
  /// - Quarterly: "2024-Q1"
  /// - Monthly: "2024-01"
  DateTime? _parseSnbDate(String date, String? frequency) {
    try {
      if (date.contains('-Q')) {
        // Quarterly format
        final parts = date.split('-Q');
        if (parts.length != 2) return null;
        final year = int.tryParse(parts[0]);
        final quarter = int.tryParse(parts[1]);
        if (year == null || quarter == null) return null;
        // Map Q1-Q4 to month
        final month = (quarter - 1) * 3 + 1;
        return DateTime(year, month);
      } else if (date.contains('-')) {
        // Monthly format
        final parts = date.split('-');
        if (parts.length != 2) return null;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year == null || month == null) return null;
        return DateTime(year, month);
      }
    } catch (e) {
      debugPrint('Error parsing SNB date: $date');
    }
    return null;
  }

  /// Expands quarterly data to monthly for chart consistency.
  /// Uses linear interpolation between quarterly points.
  List<CpiDataPoint> _expandQuarterlyToMonthly(List<CpiDataPoint> quarterly) {
    if (quarterly.length < 2) return quarterly;

    final monthly = <CpiDataPoint>[];

    for (int i = 0; i < quarterly.length - 1; i++) {
      final current = quarterly[i];
      final next = quarterly[i + 1];

      // Current quarter
      monthly.add(current);

      // Interpolate two intermediate months
      final valueDiff = next.index - current.index;
      monthly.add(CpiDataPoint(
        month: DateTime(current.month.year, current.month.month + 1),
        index: current.index + valueDiff * 0.33,
      ));
      monthly.add(CpiDataPoint(
        month: DateTime(current.month.year, current.month.month + 2),
        index: current.index + valueDiff * 0.67,
      ));
    }

    // Add the last point
    monthly.add(quarterly.last);

    return monthly;
  }

  String _formatQuarter(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    return '${date.year}-Q$quarter';
  }

  String _formatYearMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _calculateFromDate(DateTime startMonth, int observationCount) {
    // For quarterly data, request enough quarters to cover observationCount
    final quartersNeeded = (observationCount ~/ 3) + 1;
    final fromDate = DateTime(
      startMonth.year,
      startMonth.month - quartersNeeded * 3,
    );
    return _formatQuarter(fromDate);
  }

  void _logDioError(String cube, DioException error) {
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
      DioExceptionType.unknown when underlying is Exception =>
        underlying.runtimeType.toString(),
      DioExceptionType.unknown => 'unknown',
    };
    final message = error.message ?? underlying?.toString() ?? 'request failed';
    debugPrint('SnbClient network error ($cube/$kind): $message');
  }
}
