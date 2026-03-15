import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

class EntryDuplicateMatch {
  final PurchaseEntryWithProduct existingEntry;
  final double similarityScore;

  const EntryDuplicateMatch({
    required this.existingEntry,
    required this.similarityScore,
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

  Future<EntryDuplicateMatch?> findDuplicate({
    required String productName,
    required double price,
    required EntryRepository repository,
    int days = _defaultDaysLookback,
  }) async {
    final recentEntries = await repository.getRecentEntriesWithProduct(
      days: days,
      price: price,
    );

    if (recentEntries.isEmpty) return null;

    final normalizedNewName = _normalizeName(productName);
    EntryDuplicateMatch? bestMatch;
    int bestScore = 0;

    for (final entry in recentEntries) {
      final normalizedExistingName = _normalizeName(entry.productName);
      if (normalizedNewName == normalizedExistingName) continue;

      final score = _calculateSimilarity(productName, entry.productName);

      if (score >= (_similarityThreshold * 100).toInt() && score > bestScore) {
        bestScore = score;
        bestMatch = EntryDuplicateMatch(
          existingEntry: entry,
          similarityScore: score / 100.0,
        );
      }
    }

    return bestMatch;
  }
}
