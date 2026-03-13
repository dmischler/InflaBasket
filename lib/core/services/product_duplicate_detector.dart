import 'package:drift/drift.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:inflabasket/core/database/database.dart';

class ProductDuplicateResult {
  final Product existingProduct;
  final double similarityScore;
  final int categoryId;

  const ProductDuplicateResult({
    required this.existingProduct,
    required this.similarityScore,
    required this.categoryId,
  });
}

class ProductDuplicateDetectorService {
  final AppDatabase _db;

  static const double _similarityThreshold = 0.85;
  static const double _nameWeight = 0.70;
  static const double _brandWeight = 0.20;
  static const double _categoryWeight = 0.10;

  ProductDuplicateDetectorService(this._db);

  Future<List<ProductDuplicateResult>> findSimilarProducts({
    required String name,
    String? brand,
    int? categoryId,
  }) async {
    final allProducts = await _db.select(_db.products).get();
    if (allProducts.isEmpty) return [];

    final normalizedName = normalizeProductName(name);
    final normalizedBrand = brand?.toLowerCase().trim();

    final results = <ProductDuplicateResult>[];

    for (final product in allProducts) {
      final existingNormalizedName = normalizeProductName(product.name);
      if (existingNormalizedName == normalizedName) continue;

      final score = calculateWeightedSimilarity(
        newName: normalizedName,
        newBrand: normalizedBrand,
        newCategoryId: categoryId,
        existingProduct: product,
      );

      if (score >= _similarityThreshold) {
        results.add(ProductDuplicateResult(
          existingProduct: product,
          similarityScore: score,
          categoryId: product.categoryId,
        ));
      }
    }

    results.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return results;
  }

  String normalizeProductName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(
            RegExp(
                r'\d+(?:\.\d+)?\s*(g|kg|ml|l|cl|oz|lb|stück|pc|pcs|pack|-piece)'),
            '')
        .replaceAll(
            RegExp(r'\b(bio|öko|eco|organic)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^\w\säöüéèà]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double calculateWeightedSimilarity({
    required String newName,
    String? newBrand,
    int? newCategoryId,
    required Product existingProduct,
  }) {
    final nameScore = tokenSetRatio(
          newName,
          normalizeProductName(existingProduct.name),
        ) /
        100.0;

    double brandScore = 0.0;
    if (newBrand != null &&
        newBrand.isNotEmpty &&
        existingProduct.brand != null) {
      brandScore = tokenSetRatio(
            newBrand,
            existingProduct.brand!.toLowerCase().trim(),
          ) /
          100.0;
    }

    double categoryScore = 0.0;
    if (newCategoryId != null && newCategoryId == existingProduct.categoryId) {
      categoryScore = 1.0;
    }

    return (nameScore * _nameWeight) +
        (brandScore * _brandWeight) +
        (categoryScore * _categoryWeight);
  }

  Future<void> updateProductBrand(int productId, String brand) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(brand: Value(brand)));
  }
}
