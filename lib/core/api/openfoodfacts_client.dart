import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openfoodfacts_client.g.dart';

@riverpod
OpenFoodFactsClient openFoodFactsClient(OpenFoodFactsClientRef ref) {
  return OpenFoodFactsClient();
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

List<StoreInfo> _parseStores(String? storesRaw, List<String>? storesTags) {
  final stores = <StoreInfo>[];
  final seenNames = <String>{};

  // Parse storesTags (List)
  if (storesTags != null) {
    for (final tag in storesTags) {
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

  // Parse storesRaw - can be String (comma-separated)
  if (storesRaw != null && storesRaw.isNotEmpty) {
    for (final name in storesRaw.split(',')) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty && !seenNames.contains(trimmed)) {
        seenNames.add(trimmed);
        stores.add(StoreInfo(name: trimmed));
      }
    }
  }

  return stores;
}

class OpenFoodFactsClient {
  OpenFoodFactsClient();

  /// Looks up a product by [barcode] (EAN-13, UPC-A, …).
  /// Returns [ProductInfo] on success, or null if nothing was found.
  ///
  /// [locale] - preferred language for product names ('de' or 'en')
  Future<ProductInfo?> lookupBarcode(String barcode,
      {String locale = 'en'}) async {
    try {
      final config = ProductQueryConfiguration(
        barcode.trim(),
        fields: [
          ProductField.BARCODE,
          ProductField.NAME_ALL_LANGUAGES,
          ProductField.BRANDS,
          ProductField.IMAGE_FRONT_URL,
          ProductField.STORES,
          ProductField.STORES_TAGS,
          ProductField.CATEGORIES_TAGS,
        ],
        version: ProductQueryVersion.v3,
      );

      final ProductResultV3 result =
          await OpenFoodAPIClient.getProductV3(config);

      if (result.status != ProductResultV3.statusSuccess ||
          result.product == null) {
        return null;
      }

      final product = result.product!;

      // Extract all name variants
      final nameEn =
          product.productNameInLanguages?[OpenFoodFactsLanguage.ENGLISH];
      final nameDe =
          product.productNameInLanguages?[OpenFoodFactsLanguage.GERMAN];
      final nameFr =
          product.productNameInLanguages?[OpenFoodFactsLanguage.FRENCH];

      // Fallback to productName if mapped languages are null
      final defaultName = product.productName;

      // Use first available name as default (until user selects)
      String? resolvedName = nameEn?.trim() ??
          nameDe?.trim() ??
          nameFr?.trim() ??
          defaultName?.trim();

      if (resolvedName == null || resolvedName.isEmpty) {
        return null;
      }

      final brand = product.brands;
      final imageUrl = product.imageFrontUrl;

      final storesRaw = product.stores;
      final storesTags = product.storesTags;
      final storesList = _parseStores(storesRaw, storesTags);

      String? categoryTag;
      final catTags = product.categoriesTags;
      if (catTags != null && catTags.isNotEmpty) {
        final raw = catTags.first;
        categoryTag = raw.contains(':') ? raw.split(':').last : raw;
      }

      final suggestedCategory = _mapOffCategory(categoryTag);

      final productInfo = ProductInfo(
        name: resolvedName.trim(),
        nameEn: nameEn?.trim(),
        nameDe: nameDe?.trim(),
        nameFr: nameFr?.trim(),
        brand: brand?.trim().isNotEmpty == true ? brand!.trim() : null,
        suggestedCategory: suggestedCategory,
        imageUrl: imageUrl,
        stores: storesList,
        barcode: barcode,
        locale: locale,
      );

      return productInfo;
    } catch (_) {
      return null;
    }
  }
}
