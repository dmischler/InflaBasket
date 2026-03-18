import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

enum DuplicateMatchType {
  exact,
  similar,
}

class EntryDuplicateMatch {
  final PurchaseEntryWithProduct existingEntry;
  final double similarityScore;
  final DuplicateMatchType matchType;

  const EntryDuplicateMatch({
    required this.existingEntry,
    required this.similarityScore,
    required this.matchType,
  });
}

class EntryDuplicateDetectorService {
  static const double _similarityThreshold = 0.85;
  static const int _defaultDaysLookback = 30;

  String _normalizeName(String name) {
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

  int _calculateSimilarity(String newName, String existingName) {
    final normalizedNew = _normalizeName(newName);
    final normalizedExisting = _normalizeName(existingName);
    return tokenSetRatio(normalizedNew, normalizedExisting);
  }

  String _normalizeStore(String storeName) {
    return storeName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _hasSimilarNormalizedPrice(
    PurchaseEntryWithProduct existing,
    double newPrice,
    double newQuantity,
    UnitType newUnit,
  ) {
    final existingUnit = unitTypeFromString(existing.entry.unit);
    if (!existingUnit.compatibleWith(newUnit)) return false;

    final existingNorm = existingUnit.normalizedPrice(
      existing.price,
      existing.entry.quantity,
    );
    final newNorm = newUnit.normalizedPrice(newPrice, newQuantity);

    if (existingNorm == 0) return newNorm == 0;

    final diff = (existingNorm - newNorm).abs() / existingNorm;
    return diff <= 0.01;
  }

  Future<EntryDuplicateMatch?> findDuplicate({
    required String productName,
    required double price,
    required String storeName,
    required EntryRepository repository,
    String? barcode,
    int? existingProductId,
    int days = _defaultDaysLookback,
    double quantity = 1.0,
    UnitType? unit,
  }) async {
    final recentEntries = await repository.getRecentEntriesWithProduct(
      days: days,
    );

    if (recentEntries.isEmpty) return null;

    final normalizedNewName = _normalizeName(productName);
    final normalizedStore = _normalizeStore(storeName);
    final normalizedBarcode = barcode?.trim();
    final candidates = recentEntries.where((entry) {
      final sameStore = _normalizeStore(entry.storeName) == normalizedStore;
      final samePrice = _hasSimilarNormalizedPrice(
          entry, price, quantity, unit ?? UnitType.count);
      return sameStore && samePrice;
    }).toList();

    if (candidates.isEmpty) return null;

    if (normalizedBarcode != null && normalizedBarcode.isNotEmpty) {
      for (final entry in candidates) {
        final existingBarcode = entry.product.barcode?.trim();
        if (existingBarcode == normalizedBarcode) {
          return EntryDuplicateMatch(
            existingEntry: entry,
            similarityScore: 1.0,
            matchType: DuplicateMatchType.exact,
          );
        }
      }
    }

    if (existingProductId != null) {
      for (final entry in candidates) {
        if (entry.product.id == existingProductId) {
          return EntryDuplicateMatch(
            existingEntry: entry,
            similarityScore: 1.0,
            matchType: DuplicateMatchType.exact,
          );
        }
      }
    }

    EntryDuplicateMatch? bestMatch;
    int bestScore = 0;

    for (final entry in candidates) {
      final normalizedExistingName = _normalizeName(entry.productName);
      if (normalizedNewName == normalizedExistingName) {
        return EntryDuplicateMatch(
          existingEntry: entry,
          similarityScore: 1.0,
          matchType: DuplicateMatchType.exact,
        );
      }

      final score = _calculateSimilarity(productName, entry.productName);

      if (score >= (_similarityThreshold * 100).toInt() && score > bestScore) {
        bestScore = score;
        bestMatch = EntryDuplicateMatch(
          existingEntry: entry,
          similarityScore: score / 100.0,
          matchType: DuplicateMatchType.similar,
        );
      }
    }

    return bestMatch;
  }
}
