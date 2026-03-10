import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'dart:convert';

part 'vision_client.g.dart';

@riverpod
VisionClient visionClient(VisionClientRef ref) {
  return VisionClient();
}

class VisionClient {
  VisionClient();

  Future<Map<String, dynamic>> parseReceipt(
    File imageFile, {
    List<String> defaultCategoryKeys = CategoryLocalization.defaultCategoryKeys,
    List<String> customCategoryNames = const <String>[],
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final availableCategories = <String>{
        ...defaultCategoryKeys,
        ...customCategoryNames.where((name) => name.trim().isNotEmpty),
      }.toList(growable: false);

      final model = GenerativeModel(
        model:
            'gemini-2.5-flash', // or 'gemini-1.5-flash-8b' / latest stable flash variant
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.0,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'storeName': Schema.string(
                  description: 'Store name or empty string if unknown'),
              'date': Schema.string(
                  description:
                      'Date in YYYY-MM-DD format or empty string if unknown'),
              'items': Schema.array(
                items: Schema.object(
                  properties: {
                    'productName': Schema.string(),
                    'price': Schema.number(),
                    'quantity': Schema.number(),
                    'unit': Schema.string(
                      // ← changed: just string, no enumString(values: …)
                      description:
                          'Unit of measurement. Must be one of: count, gram, kilogram, ounce, pound, milliliter, liter, fluidOunce, pack, piece, bottle, can. Use exactly one of these values.',
                    ),
                    'total': Schema.number(),
                    'suggestedCategory': Schema.string(),
                    'confidence': Schema.number(),
                  },
                  requiredProperties: [
                    'productName',
                    'price',
                    'quantity',
                    'unit',
                    'total',
                    'suggestedCategory',
                    'confidence',
                  ],
                ),
              ),
            },
            requiredProperties: ['storeName', 'date', 'items'],
          ),
        ),
      );

      final prompt = '''
You are a precise receipt OCR and structured data extraction specialist.
Your only output must be valid JSON — no explanations, no markdown, no extra text.

Rules you MUST follow:

1. ONLY include actual purchased PRODUCT lines that contain both a description/name and a price.
2. NEVER include:
   - Taxes (VAT, TVA, MwSt, GST, HST, tax, steuer, etc.)
   - Totals (subtotal, total, grand total, sum, amount due, zu zahlen, etc.)
   - Discounts / coupons / reductions / rabatt / sconto
   - Payment method lines, change, tendered, rendu, resto
   - Store info (address, phone, website, opening hours, return policy)
   - Headers, footers, thank you notes, barcodes, cashier name
3. Each product line appears exactly once.
4. If quantity > 1 is shown (×2, 3 pcs, 4×, 500g×3), use unit price in "price" and line total in "total".
5. Infer quantity from text (default = 1 if not specified).
6. Infer unit intelligently — use ONLY these exact strings:
   count | gram | kilogram | ounce | pound | milliliter | liter | fluidOunce | pack | piece | bottle | can
   IMPORTANT volume conversions:
   - "50cl", "50 cl", "50 cL" → unit: "milliliter", quantity: 500
   - "33cl", "33 cl" → unit: "milliliter", quantity: 330
   - "1L", "1 L", "1l" → unit: "liter", quantity: 1
   - "1.5L", "1.5 L" → unit: "milliliter", quantity: 1500
   - "750ml", "750 ml", "0.75L" → unit: "milliliter", quantity: 750
   - "250ml", "250 ml", "0.25L" → unit: "milliliter", quantity: 250
7. suggestedCategory MUST be one of these exact values (case-sensitive):
   ${availableCategories.join(', ')}
8. confidence = how certain you are this is a real product line (0.0–1.0)

Return ONLY this JSON structure:

{
  "storeName": "string or \"\"",
  "date": "YYYY-MM-DD or \"\"",
  "items": [
    {
      "productName": "cleaned product name",
      "price": number,
      "quantity": number,
      "unit": "one of allowed units",
      "total": number,
      "suggestedCategory": "exact category from list",
      "confidence": number
    }
  ]
}

Example correct output:
{
  "storeName": "REWE",
  "date": "2026-03-09",
  "items": [
    {
      "productName": "Bio Vollmilch 1,5%",
      "price": 1.49,
      "quantity": 1,
      "unit": "liter",
      "total": 1.49,
      "suggestedCategory": "dairy",
      "confidence": 0.98
    },
    {
      "productName": "Bananas",
      "price": 1.99,
      "quantity": 1.2,
      "unit": "kilogram",
      "total": 2.39,
      "suggestedCategory": "fruits",
      "confidence": 0.95
    }
  ]
}
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);

      final content = response.text;

      if (content == null || content.isEmpty) {
        throw Exception('Gemini returned empty response');
      }

      debugPrint('══ RAW GEMINI RESPONSE ════════════════════════════════');
      debugPrint(content);
      debugPrint('═══════════════════════════════════════════════════════');

      // Clean up common markdown/leftover artifacts
      String cleanContent = content
          .replaceAll(RegExp(r'```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```'), '')
          .trim();

      // Extract JSON object if model added surrounding text
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanContent);
      if (jsonMatch != null) {
        cleanContent = jsonMatch.group(0)!;
      }

      final parsed = jsonDecode(cleanContent) as Map<String, dynamic>;

      final items = _filterValidItems(
        (parsed['items'] as List<dynamic>?) ?? [],
      );

      return {
        'storeName': parsed['storeName'] as String? ?? '',
        'date': parsed['date'] as String? ?? '',
        'items': items,
      };
    } catch (e, stack) {
      debugPrint('Vision parseReceipt failed: $e');
      debugPrint('Stack: $stack');
      throw Exception(
          'Failed to parse receipt. Please try again or enter items manually.');
    }
  }

  static final _excludePatterns = [
    RegExp(r'^tax$', caseSensitive: false),
    RegExp(r'^tva$', caseSensitive: false),
    RegExp(r'^vat$', caseSensitive: false),
    RegExp(r'^gst$', caseSensitive: false),
    RegExp(r'^hst$', caseSensitive: false),
    RegExp(r'^mwst$', caseSensitive: false),
    RegExp(r'^subtotal$', caseSensitive: false),
    RegExp(r'^subtotal\s', caseSensitive: false),
    RegExp(r'^sub-total$', caseSensitive: false),
    RegExp(r'^total$', caseSensitive: false),
    RegExp(r'^total\s', caseSensitive: false),
    RegExp(r'^grand\s*total$', caseSensitive: false),
    RegExp(r'^sum$', caseSensitive: false),
    RegExp(r'^amount\s*due$', caseSensitive: false),
    RegExp(r'^amount$', caseSensitive: false),
    RegExp(r'^discount$', caseSensitive: false),
    RegExp(r'^rabatt$', caseSensitive: false),
    RegExp(r'^réduction$', caseSensitive: false),
    RegExp(r'^sconto$', caseSensitive: false),
    RegExp(r'^coupon$', caseSensitive: false),
    RegExp(r'^cashback$', caseSensitive: false),
    RegExp(r'^tendered$', caseSensitive: false),
    RegExp(r'^change\s', caseSensitive: false),
    RegExp(r'^rendu$', caseSensitive: false),
    RegExp(r'^rest$', caseSensitive: false),
  ];

  List<Map<String, dynamic>> _filterValidItems(List<dynamic> items) {
    debugPrint('Raw items received from model: ${items.length}');

    final seen = <String>{};
    final validItems = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        debugPrint('Skipped non-map item: $item');
        continue;
      }

      final name = (item['productName'] as String?)?.trim() ?? '';

      if (name.isEmpty) {
        debugPrint('Skipped item with empty name');
        continue;
      }

      if (_excludePatterns.any((p) => p.hasMatch(name))) {
        debugPrint('Excluded by pattern: "$name"');
        continue;
      }

      final price = (item['price'] as num?)?.toDouble();
      final total = (item['total'] as num?)?.toDouble();

      if (price == null && total == null) {
        debugPrint('Skipped — no price/total: "$name"');
        continue;
      }

      final hasPositivePrice =
          (price != null && price > 0) || (total != null && total > 0);

      if (!hasPositivePrice) {
        debugPrint(
            'Skipped — invalid price: "$name" (price=$price, total=$total)');
        continue;
      }

      final normalized = name.toLowerCase().trim();
      if (seen.contains(normalized)) {
        debugPrint('Duplicate skipped: "$name"');
        continue;
      }
      seen.add(normalized);

      validItems.add(item.cast<String, dynamic>());
    }

    debugPrint('Valid items after filtering: ${validItems.length}');
    return validItems;
  }
}
