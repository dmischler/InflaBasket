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
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseSchema: Schema.object(
            properties: {
              'storeName': Schema.string(),
              'date': Schema.string(),
              'items': Schema.array(
                items: Schema.object(
                  properties: {
                    'productName': Schema.string(),
                    'price': Schema.number(),
                    'quantity': Schema.number(),
                    'unit': Schema.string(),
                    'total': Schema.number(),
                    'suggestedCategory': Schema.string(),
                    'confidence': Schema.number(),
                  },
                ),
              ),
            },
            requiredProperties: ['storeName', 'date', 'items'],
          ),
          responseMimeType: 'application/json',
        ),
      );

      final prompt =
          '''You are an expert receipt parser. Analyze the provided receipt image.
Extract the store name, date, and all individual line items.
For each item, provide a "suggestedCategory" strictly chosen from this list: [${availableCategories.join(', ')}].
Always return one of those exact category strings with identical spelling, capitalization, and punctuation.
The default categories are English canonical keys. Custom user categories may also appear in the list; keep them exactly as provided.
Also extract the package size and unit for each item. Infer the unit from the product name or any weight/volume printed on the receipt (e.g. "Milk 1L" → unit: "liter", quantity: 1; "Chicken 500g" → unit: "gram", quantity: 500; "Eggs 6 pcs" → unit: "count", quantity: 6).
Return a valid JSON object matching this schema:
{
  "storeName": "string",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "productName": "string",
      "price": number,
      "quantity": number,
      "unit": "count|gram|kilogram|ounce|pound|milliliter|liter|fluidOunce",
      "total": number,
      "suggestedCategory": "string",
      "confidence": number (0.0 to 1.0)
    }
  ]
}''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);

      final content = response.text;

      if (content == null || content.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      final cleanContent =
          content.replaceAll('```json', '').replaceAll('```', '').trim();

      return jsonDecode(cleanContent);
    } catch (e) {
      debugPrint('Vision API Error: $e');
      throw Exception(
          'Failed to parse receipt. Please try again or enter manually.');
    }
  }
}
