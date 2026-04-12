import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';

import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/features/ai_scanner/data/ai_client.dart';
import 'package:inflabasket/features/ai_scanner/data/receipt_parsing_utils.dart';

const _defaultModel = 'gpt-4o';
const _fallbackModel = 'gpt-4o-mini';

class OpenAiClient implements AiClient {
  final String apiKey;

  OpenAiClient(this.apiKey) {
    OpenAI.apiKey = apiKey;
  }

  Future<Map<String, dynamic>> _generateWithFallback({
    required String prompt,
    required String base64Image,
    bool isFallback = false,
  }) async {
    final model = isFallback ? _fallbackModel : _defaultModel;

    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: model,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                prompt,
              ),
              OpenAIChatCompletionChoiceMessageContentItemModel.imageBase64(
                base64Image,
              ),
            ],
          ),
        ],
        responseFormat: {
          "type": "json_object",
        },
      );

      final content = chatCompletion.choices.first.message.content;
      if (content == null || content.isEmpty) {
        throw Exception('OpenAI returned empty response');
      }

      final text = content.first.text;
      if (text == null || text.isEmpty) {
        throw Exception('OpenAI returned empty text response');
      }

      return {'rawText': text, 'usedFallback': isFallback};
    } catch (e) {
      final statusCode =
          (e is Exception) ? _extractStatusCode(e.toString()) : null;
      if (!isFallback && (statusCode == 429 || statusCode == 503)) {
        debugPrint('OpenAI $model failed, retrying with $_fallbackModel');
        return _generateWithFallback(
          prompt: prompt,
          base64Image: base64Image,
          isFallback: true,
        );
      }
      rethrow;
    }
  }

  int? _extractStatusCode(String message) {
    final match = RegExp(r'(\d{3})').firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  @override
  Future<Map<String, dynamic>> parseReceipt(
    File imageFile, {
    List<String> defaultCategoryKeys = CategoryLocalization.defaultCategoryKeys,
    List<String> customCategoryNames = const <String>[],
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final prompt = ReceiptParsingUtils.buildReceiptPrompt(
        defaultCategoryKeys: defaultCategoryKeys,
        customCategoryNames: customCategoryNames,
      );

      final result = await _generateWithFallback(
        prompt: prompt,
        base64Image: base64Image,
      );

      final content = result['rawText'] as String;

      debugPrint('══ RAW OPENAI RESPONSE ════════════════════════════════');
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
      debugPrint('OpenAI parseReceipt failed: $e');
      debugPrint('Stack: $stack');
      throw Exception(
          'Failed to parse receipt. Please try again or enter items manually.');
    }
  }
}
