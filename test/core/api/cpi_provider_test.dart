import 'package:flutter_test/flutter_test.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';

void main() {
  group('comparisonWindowForHistory', () {
    test('defaults to 24 months for insufficient history', () {
      final window = comparisonWindowForHistory(const []);

      expect(window.observationCount, 24);
    });

    test('uses exact month span for valid history', () {
      final history = [
        MonthlyIndex(month: DateTime(2024, 1), index: 100),
        MonthlyIndex(month: DateTime(2024, 3), index: 102),
      ];

      final window = comparisonWindowForHistory(history);

      expect(window.startMonth, DateTime(2024, 1));
      expect(window.observationCount, 3);
    });
  });

  group('rebaseComparisonSeries', () {
    test('rebases first point to 100 and preserves ordering', () {
      final result = rebaseComparisonSeries([
        (DateTime(2024, 2), 120.0),
        (DateTime(2024, 1), 100.0),
      ]);

      expect(result, hasLength(2));
      expect(result.first.month, DateTime(2024, 1));
      expect(result.first.index, 100.0);
      expect(result.last.index, 120.0);
    });
  });

  group('isExternalSeriesCacheFresh', () {
    test('uses longer ttl for historical data', () {
      final now = DateTime.now();
      final rows = [
        ExternalSeriesCacheEntry(
          source: 'eurostat',
          currency: 'EUR',
          metric: 'cpi',
          month: DateTime(now.year, now.month - 2),
          value: 101,
          fetchedAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      expect(isExternalSeriesCacheFresh(rows), isTrue);
    });

    test('expires current-month data after one day', () {
      final now = DateTime.now();
      final rows = [
        ExternalSeriesCacheEntry(
          source: 'eurostat',
          currency: 'EUR',
          metric: 'cpi',
          month: DateTime(now.year, now.month),
          value: 101,
          fetchedAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      expect(isExternalSeriesCacheFresh(rows), isFalse);
    });
  });

  group('external cache entry model', () {
    test('creates generated companion values', () {
      final entry = ExternalSeriesCacheEntry(
        source: 'fred',
        currency: 'USD',
        metric: 'money_supply_m2',
        month: DateTime(2024, 1),
        value: 10,
        fetchedAt: DateTime(2024, 2, 1),
      );

      final companion = entry.toCompanion(false);

      expect(companion.source.value, 'fred');
      expect(companion.currency.value, 'USD');
      expect(companion.metric.value, 'money_supply_m2');
      expect(companion.value.value, 10);
    });
  });
}
