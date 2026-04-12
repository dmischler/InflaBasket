import 'dart:convert';

class ReceiptParsingUtils {
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

  static List<Map<String, dynamic>> filterValidItems(List<dynamic> items) {
    final seen = <String>{};
    final validItems = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final name = (item['productName'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      if (_excludePatterns.any((p) => p.hasMatch(name))) continue;

      final price = (item['price'] as num?)?.toDouble();
      final total = (item['total'] as num?)?.toDouble();

      if (price == null && total == null) continue;
      if (!((price != null && price > 0) || (total != null && total > 0))) {
        continue;
      }

      final normalized = name.toLowerCase().trim();
      if (seen.contains(normalized)) continue;
      seen.add(normalized);

      validItems.add(item.cast<String, dynamic>());
    }

    return validItems;
  }

  static Map<String, dynamic>? tryRecoverTruncatedJson(String input) {
    int braceCount = 0;
    int bracketCount = 0;
    int lastBalancedPos = -1;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '{') braceCount++;
      if (char == '}') braceCount--;
      if (char == '[') bracketCount++;
      if (char == ']') bracketCount--;

      if (braceCount == 0 && bracketCount == 0) {
        lastBalancedPos = i;
      }
    }

    if (lastBalancedPos > 0) {
      final truncated = input.substring(0, lastBalancedPos + 1);
      try {
        final parsed = jsonDecode(truncated) as Map<String, dynamic>;
        return parsed;
      } catch (_) {}
    }

    final itemsMatch = RegExp(r'"items"\s*:\s*\[[\s\S]*').firstMatch(input);
    if (itemsMatch != null) {
      int itemBraceCount = 0;
      int itemBracketCount = 0;
      int lastItemBalanced = -1;

      for (int i = 0; i < input.length; i++) {
        final char = input[i];
        if (char == '{') itemBraceCount++;
        if (char == '}') itemBraceCount--;
        if (char == '[') itemBracketCount++;
        if (char == ']') itemBracketCount--;

        if (itemBraceCount == 0 && itemBracketCount == 0 && char == ']') {
          lastItemBalanced = i;
        }
      }

      if (lastItemBalanced > itemsMatch.start) {
        final itemsJson =
            input.substring(itemsMatch.start, lastItemBalanced + 1);
        try {
          final items =
              jsonDecode('{"items": $itemsJson}') as Map<String, dynamic>;
          return {
            'storeName': '',
            'date': '',
            'items': items['items'],
          };
        } catch (_) {}
      }
    }

    return null;
  }

  static String cleanJsonResponse(String content) {
    String cleanContent = content
        .replaceAll(RegExp(r'```(?:json)?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```'), '')
        .trim();

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanContent);
    if (jsonMatch != null) {
      cleanContent = jsonMatch.group(0)!;
    }

    return cleanContent;
  }

  static String buildReceiptPrompt({
    required List<String> defaultCategoryKeys,
    required List<String> customCategoryNames,
  }) {
    final availableCategories = <String>{
      ...defaultCategoryKeys,
      ...customCategoryNames.where((name) => name.trim().isNotEmpty),
    }.toList(growable: false);

    return '''
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

4. CRITICAL PRICE RULES FOR WEIGHT/QUANTITY ITEMS:
   - "price" MUST ALWAYS be the ACTUAL AMOUNT PAID as shown on the receipt — NEVER normalize to per-unit.
   - For items with weight (e.g., "Bananas 1.2kg €2.39"):
     * price = 2.39 (the total you pay)
     * quantity = 1.2 (the weight purchased)
     * total = 2.39 (same as price)
   - For multi-packs (e.g., "Yogurt 4× €0.50 = €2.00"):
     * price = 2.00 (line total)
     * quantity = 4
     * total = 2.00
   - For per-unit pricing (e.g., "Apples €1.99/kg 500g"):
     * price = 0.995 (calculate: 1.99 × 0.5)
     * quantity = 0.5
     * total = 0.995
   - For single items without explicit weight (e.g., "Milk €1.49"):
     * price = 1.49
     * quantity = 1
     * total = 1.49

5. Infer unit intelligently — use ONLY these exact strings:
   count | gram | kilogram | ounce | pound | milliliter | liter | fluidOunce | pack | piece | bottle | can
   IMPORTANT volume conversions:
   - "50cl", "50 cl", "50 cL" → unit: "milliliter", quantity: 500
   - "33cl", "33 cl" → unit: "milliliter", quantity: 330
   - "1L", "1 L", "1l" → unit: "liter", quantity: 1
   - "1.5L", "1.5 L" → unit: "milliliter", quantity: 1500
   - "750ml", "750 ml", "0.75L" → unit: "milliliter", quantity: 750
   - "250ml", "250 ml", "0.25L" → unit: "milliliter", quantity: 250

6. suggestedCategory MUST be one of these exact values (case-sensitive):
   ${availableCategories.join(', ')}
7. confidence = how certain you are this is a real product line (0.0–1.0)
8. storeName: Capitalize the first letter (e.g., 'Coop' not 'coop', 'Migros' not 'migros')
9. storeWebsite: Extract the store's website URL if visible on the receipt header/footer (e.g., 'www.migros.ch', 'migros.ch'). Remove 'https://' prefix if present. Return empty string if not found.

Return ONLY this JSON structure:

{
  "storeName": "string or ''",
  "storeWebsite": "string or ''",
  "date": "YYYY-MM-DD or ''",
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
''';
  }
}
