import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openfoodfacts_client.g.dart';

@riverpod
OpenFoodFactsClient openFoodFactsClient(OpenFoodFactsClientRef ref) {
  return OpenFoodFactsClient(Dio());
}

/// Lightweight model returned by the Open Food Facts lookup.
class ProductInfo {
  final String name;
  final String? brand;
  final String? suggestedCategory;

  const ProductInfo({
    required this.name,
    this.brand,
    this.suggestedCategory,
  });
}

/// Maps an Open Food Facts PNNS group / category tag to one of the
/// InflaBasket default category names.
String? _mapOffCategory(String? pnnsGroup) {
  if (pnnsGroup == null) return null;
  final g = pnnsGroup.toLowerCase();
  if (g.contains('dairy') || g.contains('milk') || g.contains('cheese')) {
    return 'Food & Groceries';
  }
  if (g.contains('meat') ||
      g.contains('fish') ||
      g.contains('seafood') ||
      g.contains('poultry')) {
    return 'Food & Groceries';
  }
  if (g.contains('beverage') ||
      g.contains('drink') ||
      g.contains('water') ||
      g.contains('juice') ||
      g.contains('soda') ||
      g.contains('coffee') ||
      g.contains('tea')) {
    return 'Beverages';
  }
  if (g.contains('personal') ||
      g.contains('hygiene') ||
      g.contains('beauty') ||
      g.contains('cosmetic')) {
    return 'Personal Care & Hygiene';
  }
  if (g.contains('household') || g.contains('cleaning')) {
    return 'Household Supplies';
  }
  if (g.contains('cereal') ||
      g.contains('bread') ||
      g.contains('pasta') ||
      g.contains('rice') ||
      g.contains('grain') ||
      g.contains('fruit') ||
      g.contains('vegetable') ||
      g.contains('snack') ||
      g.contains('condiment') ||
      g.contains('sauce')) {
    return 'Food & Groceries';
  }
  return 'Food & Groceries'; // sensible fallback
}

class OpenFoodFactsClient {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  final Dio _dio;

  OpenFoodFactsClient(this._dio);

  /// Looks up a product by [barcode] (EAN-13, UPC-A, …).
  /// Returns [ProductInfo] on success, or null if nothing was found.
  Future<ProductInfo?> lookupBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/$barcode.json',
        queryParameters: {
          'fields': 'product_name,brands,pnns_groups_1,categories_tags',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;

      final status = data['status'];
      if (status == 0) return null; // product not found

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final rawName = product['product_name'] as String?;
      if (rawName == null || rawName.trim().isEmpty) return null;

      final brand = product['brands'] as String?;

      // Try pnns_groups_1 first, fall back to first categories_tag
      final pnns = product['pnns_groups_1'] as String?;
      String? categoryTag;
      final catTags = product['categories_tags'];
      if (catTags is List && catTags.isNotEmpty) {
        // tags look like "en:dairy" – strip the language prefix
        final raw = catTags.first as String;
        categoryTag = raw.contains(':') ? raw.split(':').last : raw;
      }

      final suggestedCategory =
          _mapOffCategory(pnns) ?? _mapOffCategory(categoryTag);

      return ProductInfo(
        name: rawName.trim(),
        brand: brand?.trim().isNotEmpty == true ? brand!.trim() : null,
        suggestedCategory: suggestedCategory,
      );
    } catch (e) {
      debugPrint('OpenFoodFacts lookup error: $e');
      return null;
    }
  }
}
