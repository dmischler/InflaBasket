import 'package:flutter_test/flutter_test.dart';
import 'package:inflabasket/core/api/money_supply_client.dart';

void main() {
  group('parseSdmxMoneySupplySeries', () {
    test('parses ECB-style SDMX payload', () {
      final json = <String, dynamic>{
        'dataSets': [
          {
            'series': {
              '0:0:0': {
                'observations': {
                  '0': [200.0],
                  '1': [210.0],
                },
              },
            },
          },
        ],
        'structure': {
          'dimensions': {
            'observation': [
              {
                'values': [
                  {'id': '2024-01'},
                  {'id': '2024-02'},
                ],
              },
            ],
          },
        },
      };

      final result = parseSdmxMoneySupplySeries(json);

      expect(result, hasLength(2));
      expect(result.first.month, DateTime(2024, 1));
      expect(result.last.value, 210.0);
    });
  });

  group('parseFredMoneySupplyCsv', () {
    test('parses monthly FRED CSV', () {
      const csv =
          'observation_date,M2SL\n2024-01-01,20815.3\n2024-02-01,20901.1\n';

      final result = parseFredMoneySupplyCsv(csv);

      expect(result, hasLength(2));
      expect(result.first.month, DateTime(2024, 1));
      expect(result.first.value, 20815.3);
    });
  });

  group('parseBoeMoneySupplyCsv', () {
    test('parses Bank of England CSV rows', () {
      const csv =
          'DATE,SERIES,VALUE\n31 Jan 2024,LPMVWYW,100.5\n29 Feb 2024,LPMVWYW,101.1\n';

      final result = parseBoeMoneySupplyCsv(csv);

      expect(result, hasLength(2));
      expect(result.first.month, DateTime(2024, 1));
      expect(result.last.value, 101.1);
    });
  });

  group('extractSnbM2Series', () {
    test('filters only M2 rows and applies start month', () {
      final json = <String, dynamic>{
        'data': {
          'data': [
            ['2024-01', 'M1', '10.0'],
            ['2024-01', 'M2', '20.0'],
            ['2024-02', 'M2', '21.5'],
          ],
        },
      };

      final result = extractSnbM2Series(
        json,
        startMonth: DateTime(2024, 2),
      );

      expect(result, hasLength(1));
      expect(result.first.month, DateTime(2024, 2));
      expect(result.first.value, 21.5);
    });
  });

  group('parseMoneySupplyDouble', () {
    test('handles strings, nums, and blanks', () {
      expect(parseMoneySupplyDouble(2), 2.0);
      expect(parseMoneySupplyDouble('3.5'), 3.5);
      expect(parseMoneySupplyDouble('.'), isNull);
      expect(parseMoneySupplyDouble(''), isNull);
    });
  });
}
