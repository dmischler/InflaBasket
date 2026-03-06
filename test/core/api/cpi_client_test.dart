import 'package:flutter_test/flutter_test.dart';
import 'package:inflabasket/core/api/cpi_client.dart';

void main() {
  group('parseCpiSdmxSeries', () {
    test('parses and sorts SDMX observations', () {
      final json = <String, dynamic>{
        'dataSets': [
          {
            'series': {
              '0:0:0:0': {
                'observations': {
                  '1': [103.4],
                  '0': [101.2],
                },
              },
            },
          },
        ],
        'structure': {
          'dimensions': {
            'observation': [
              {
                'id': 'TIME_PERIOD',
                'values': [
                  {'id': '2024-01'},
                  {'id': '2024-02'},
                ],
              },
            ],
          },
        },
      };

      final result = parseCpiSdmxSeries(json);

      expect(result, hasLength(2));
      expect(result[0].month, DateTime(2024, 1));
      expect(result[0].index, 101.2);
      expect(result[1].month, DateTime(2024, 2));
      expect(result[1].index, 103.4);
    });

    test('returns empty list for malformed payload', () {
      expect(parseCpiSdmxSeries({'oops': true}), isEmpty);
    });
  });

  group('parseYearMonthId', () {
    test('parses valid ids', () {
      expect(parseYearMonthId('2025-03'), DateTime(2025, 3));
    });

    test('returns null for invalid ids', () {
      expect(parseYearMonthId('2025'), isNull);
      expect(parseYearMonthId('bad-value'), isNull);
    });
  });

  group('parseDoubleValue', () {
    test('handles num and string inputs', () {
      expect(parseDoubleValue(4), 4.0);
      expect(parseDoubleValue('4.5'), 4.5);
    });

    test('returns null for invalid inputs', () {
      expect(parseDoubleValue(null), isNull);
      expect(parseDoubleValue('abc'), isNull);
    });
  });
}
