import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';

part 'vision_client.g.dart';

@riverpod
VisionClient visionClient(VisionClientRef ref) {
  return VisionClient(Dio());
}

class VisionClient {
  final Dio _dio;

  VisionClient(this._dio);

  Future<Map<String, dynamic>> parseReceipt(File imageFile) async {
    // In a real app, this would be your backend server or directly to OpenAI/Grok if safe.
    // WARNING: Storing API keys in the app is not recommended for production.
    const apiKey = 'YOUR_API_KEY'; // Replace or inject
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "gpt-4o",
          "messages": [
            {
              "role": "system",
              "content":
                  '''You are an expert receipt parser. Analyze the provided receipt image.
Extract the store name, date, and all individual line items.
For each item, provide a "suggestedCategory" strictly chosen from this list: [Groceries, Dairy, Meat, Beverages, Household, Personal Care, Electronics, Transportation, Dining Out]. If none fit perfectly, deduce the closest match.
Return ONLY a valid JSON object matching this schema, without markdown formatting:
{
  "storeName": "string",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "productName": "string",
      "price": number,
      "quantity": number,
      "total": number,
      "suggestedCategory": "string",
      "confidence": number
    }
  ]
}'''
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
                }
              ]
            }
          ],
          "max_tokens": 1000
        },
      );

      final responseBody = response.data;
      final content =
          responseBody['choices'][0]['message']['content'] as String;

      // Clean up potential markdown formatting from GPT
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
