import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/features/ai_scanner/data/ai_client.dart';
import 'package:inflabasket/features/ai_scanner/data/receipt_parsing_utils.dart';

const _defaultModel = 'gemini-2.5-flash';
const _fallbackModel = 'gemini-3-flash-preview';

class GeminiClient implements AiClient {
  final String apiKey;

  GeminiClient(this.apiKey);

  GenerativeModel _createModel(String modelName) {
    return GenerativeModel(
      model: modelName,
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
            'storeWebsite': Schema.string(
                description:
                    'Store website URL if visible on receipt (e.g., www.migros.ch), or empty string if not found'),
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
  }

  Future<GenerateContentResponse> _generateWithFallback({
    required GenerativeModel model,
    required String prompt,
    required Uint8List bytes,
    bool isFallback = false,
  }) async {
    try {
      return await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);
    } on GenerativeAIException catch (e) {
      final message = e.toString();
      if (!isFallback &&
          (message.contains('503') || message.contains('UNAVAILABLE'))) {
        debugPrint('Vision parseReceipt failed: $e');
        debugPrint('Retrying with fallback model: $_fallbackModel');
        final fallbackModel = _createModel(_fallbackModel);
        return _generateWithFallback(
          model: fallbackModel,
          prompt: prompt,
          bytes: bytes,
          isFallback: true,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> parseReceipt(
    File imageFile, {
    List<String> defaultCategoryKeys = CategoryLocalization.defaultCategoryKeys,
    List<String> customCategoryNames = const <String>[],
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final prompt = ReceiptParsingUtils.buildReceiptPrompt(
        defaultCategoryKeys: defaultCategoryKeys,
        customCategoryNames: customCategoryNames,
      );
      final model = _createModel(_defaultModel);

      final response = await _generateWithFallback(
        model: model,
        prompt: prompt,
        bytes: bytes,
      );

      final content = response.text;

      if (content == null || content.isEmpty) {
        throw Exception('Gemini returned empty response');
      }

      debugPrint('══ RAW GEMINI RESPONSE ════════════════════════════════');
      debugPrint(content);
      debugPrint('═════════════════════════════════════════════════════════');

      final cleanContent = ReceiptParsingUtils.cleanJsonResponse(content);

      Map<String, dynamic>? parsed;
      try {
        parsed = jsonDecode(cleanContent) as Map<String, dynamic>;
      } on FormatException catch (e) {
        debugPrint('JSON parse failed, attempting recovery: $e');
        parsed = ReceiptParsingUtils.tryRecoverTruncatedJson(cleanContent);
        if (parsed == null) {
          rethrow;
        }
      }

      final items = ReceiptParsingUtils.filterValidItems(
        (parsed['items'] as List<dynamic>?) ?? [],
      );

      final rawStoreName = parsed['storeName'] as String? ?? '';
      final storeName = rawStoreName.isNotEmpty
          ? rawStoreName[0].toUpperCase() + rawStoreName.substring(1)
          : '';

      final rawStoreWebsite = parsed['storeWebsite'] as String? ?? '';
      final storeWebsite = rawStoreWebsite.trim();

      return {
        'storeName': storeName,
        'storeWebsite': storeWebsite,
        'date': parsed['date'] as String? ?? '',
        'items': items,
      };
    } catch (e, stack) {
      debugPrint('Gemini parseReceipt failed: $e');
      debugPrint('Stack: $stack');
      throw Exception(
          'Failed to parse receipt. Please try again or enter items manually.');
    }
  }
}
