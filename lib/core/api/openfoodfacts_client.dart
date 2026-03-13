import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openfoodfacts_client.g.dart';

@riverpod
OpenFoodFactsClient openFoodFactsClient(OpenFoodFactsClientRef ref) {
  return OpenFoodFactsClient(Dio());
}

/// Store information extracted from Open Food Facts
class StoreInfo {
  final String name;
  final String? tag;

  const StoreInfo({required this.name, this.tag});
}

/// Language variant for product names
class ProductNameVariant {
  final String locale;
  final String label;
  final String? name;

  const ProductNameVariant({
    required this.locale,
    required this.label,
    this.name,
  });

  bool get isAvailable => name != null && name!.trim().isNotEmpty;
}

/// Lightweight model returned by the Open Food Facts lookup.
class ProductInfo {
  final String name;
  final String? nameEn;
  final String? nameDe;
  final String? nameFr;
  final String? brand;
  final String? suggestedCategory;
  final String? imageUrl;
  final List<StoreInfo> stores;
  final String? barcode;
  final String locale;

  const ProductInfo({
    required this.name,
    this.nameEn,
    this.nameDe,
    this.nameFr,
    this.brand,
    this.suggestedCategory,
    this.imageUrl,
    this.stores = const [],
    this.barcode,
    this.locale = 'en',
  });

  /// Returns all available name variants for user selection
  List<ProductNameVariant> get nameVariants {
    return [
      ProductNameVariant(locale: 'en', label: 'English', name: nameEn),
      ProductNameVariant(locale: 'de', label: 'Deutsch', name: nameDe),
      ProductNameVariant(locale: 'fr', label: 'Français', name: nameFr),
    ].where((v) => v.isAvailable).toList();
  }

  ProductInfo copyWith({
    String? name,
    String? nameEn,
    String? nameDe,
    String? nameFr,
    String? brand,
    String? suggestedCategory,
    String? imageUrl,
    List<StoreInfo>? stores,
    String? barcode,
    String? locale,
  }) {
    return ProductInfo(
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      nameDe: nameDe ?? this.nameDe,
      nameFr: nameFr ?? this.nameFr,
      brand: brand ?? this.brand,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      stores: stores ?? this.stores,
      barcode: barcode ?? this.barcode,
      locale: locale ?? this.locale,
    );
  }
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
  return 'Food & Groceries';
}

/// Maps Open Food Facts store tags to localized display names
const Map<String, String> _storeNameMapping = {
  'migros': 'Migros',
  'coop': 'Coop',
  'denner': 'Denner',
  'lidl': 'Lidl',
  'aldi': 'Aldi',
  'aldi_suisse': 'Aldi',
  'migros_drogerie': 'Migros Drogerie',
  'migros_restaurant': 'Migros Restaurant',
  'coop_naturaplan': 'Coop Naturaplan',
  'coop_pronatura': 'Coop Pronatura',
  'volg': 'Volg',
  'landi': 'Landi',
  ' Spar': 'Spar',
  'manor': 'Manor',
  'globus': 'Globus',
  'Interdiscount': 'Interdiscount',
  'microspot': 'Microspot',
};

List<StoreInfo> _parseStores(dynamic storesRaw, List<dynamic>? storesTags) {
  final stores = <StoreInfo>[];
  final seenNames = <String>{};

  // Parse stores_tags (List)
  if (storesTags is List) {
    for (final tag in storesTags) {
      if (tag is String) {
        final cleanTag = tag.contains(':')
            ? tag.split(':').last.toLowerCase()
            : tag.toLowerCase();
        final displayName = _storeNameMapping[cleanTag] ??
            (cleanTag.isNotEmpty
                ? cleanTag[0].toUpperCase() + cleanTag.substring(1)
                : null);
        if (displayName != null && !seenNames.contains(displayName)) {
          seenNames.add(displayName);
          stores.add(StoreInfo(name: displayName, tag: cleanTag));
        }
      }
    }
  }

  // Parse stores field - can be String (comma-separated) or Map
  if (storesRaw is String && storesRaw.isNotEmpty) {
    for (final name in storesRaw.split(',')) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty && !seenNames.contains(trimmed)) {
        seenNames.add(trimmed);
        stores.add(StoreInfo(name: trimmed));
      }
    }
  } else if (storesRaw is Map) {
    final storeList = storesRaw['stores'] as List?;
    if (storeList != null) {
      for (final store in storeList) {
        final name = store is String ? store : store['name']?.toString();
        if (name != null && !seenNames.contains(name)) {
          final cleanName = name.trim();
          if (cleanName.isNotEmpty) {
            seenNames.add(cleanName);
            stores.add(StoreInfo(name: cleanName));
          }
        }
      }
    }
  }

  return stores;
}

class OpenFoodFactsClient {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  final Dio _dio;

  OpenFoodFactsClient(this._dio);

  /// Looks up a product by [barcode] (EAN-13, UPC-A, …).
  /// Returns [ProductInfo] on success, or null if nothing was found.
  ///
  /// [locale] - preferred language for product names ('de' or 'en')
  Future<ProductInfo?> lookupBarcode(String barcode,
      {String locale = 'en'}) async {
    try {
      print('🔍 [OpenFoodFacts] Looking up barcode: $barcode');

      final response = await _dio.get(
        '$_baseUrl/$barcode.json',
        queryParameters: {
          'fields':
              'product_name,product_name_de,product_name_fr,brands,stores,stores_tags,image_front_url,pnns_groups_1,categories_tags',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        print('❌ [OpenFoodFacts] No data returned');
        return null;
      }

      print('📦 [OpenFoodFacts] Raw response: $data');

      final status = data['status'];
      if (status == 0) {
        print('❌ [OpenFoodFacts] Product not found (status=0)');
        return null;
      }

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) {
        print('❌ [OpenFoodFacts] No product in response');
        return null;
      }

      print('📦 [OpenFoodFacts] Product data: $product');

      // Extract all name variants
      final nameEn = product['product_name'] as String?;
      final nameDe = product['product_name_de'] as String?;
      final nameFr = product['product_name_fr'] as String?;

      // Use first available name as default (until user selects)
      String? resolvedName = nameEn?.trim() ?? nameDe?.trim() ?? nameFr?.trim();
      if (resolvedName == null || resolvedName.isEmpty) return null;

      final brand = product['brands'] as String?;
      final imageUrl = product['image_front_url'] as String?;

      final storesRaw = product['stores'];
      final storesTags = product['stores_tags'] as List<dynamic>?;
      final stores = _parseStores(storesRaw, storesTags);

      final pnns = product['pnns_groups_1'] as String?;
      String? categoryTag;
      final catTags = product['categories_tags'];
      if (catTags is List && catTags.isNotEmpty) {
        final raw = catTags.first as String;
        categoryTag = raw.contains(':') ? raw.split(':').last : raw;
      }

      final suggestedCategory =
          _mapOffCategory(pnns) ?? _mapOffCategory(categoryTag);

      final result = ProductInfo(
        name: resolvedName.trim(),
        nameEn: nameEn?.trim(),
        nameDe: nameDe?.trim(),
        nameFr: nameFr?.trim(),
        brand: brand?.trim().isNotEmpty == true ? brand!.trim() : null,
        suggestedCategory: suggestedCategory,
        imageUrl: imageUrl,
        stores: stores,
        barcode: barcode,
        locale: locale,
      );

      print('✅ [OpenFoodFacts] Found product: ${result.name}');
      print(
          '   Name variants: EN=${result.nameEn}, DE=${result.nameDe}, FR=${result.nameFr}');
      print('   Brand: ${result.brand}');
      print('   Category: ${result.suggestedCategory}');
      print('   Image: ${result.imageUrl}');
      print('   Stores: ${result.stores.map((s) => s.name).toList()}');

      return result;
    } catch (e) {
      print('❌ [OpenFoodFacts] Error: $e');
      return null;
    }
  }
}
