import 'package:flutter/material.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/l10n/app_localizations_de.dart';
import 'package:inflabasket/l10n/app_localizations_en.dart';
import 'package:inflabasket/l10n/app_localizations_fr.dart';
import 'package:inflabasket/l10n/app_localizations_it.dart';

class CategoryLocalization {
  const CategoryLocalization._();

  static const String fallbackCategory = 'Food & Groceries';

  static const List<String> defaultCategoryKeys = <String>[
    'Food & Groceries',
    'Restaurants & Dining Out',
    'Beverages',
    'Transportation',
    'Fuel & Energy',
    'Housing & Rent',
    'Utilities',
    'Healthcare & Medical',
    'Personal Care & Hygiene',
    'Household Supplies',
    'Clothing & Apparel',
    'Electronics & Tech',
  ];

  static const List<String> supportedLanguageCodes = <String>[
    'en',
    'de',
    'fr',
    'it',
  ];

  static const Map<String, String> _aliases = <String, String>{
    'groceries': 'Food & Groceries',
    'food and groceries': 'Food & Groceries',
    'food & groceries': 'Food & Groceries',
    'dairy': 'Food & Groceries',
    'milk': 'Food & Groceries',
    'cheese': 'Food & Groceries',
    'meat': 'Food & Groceries',
    'fish': 'Food & Groceries',
    'produce': 'Food & Groceries',
    'transportation': 'Transportation',
    'fuel transportation': 'Transportation',
    'fuel/transportation': 'Transportation',
    'fuel': 'Fuel & Energy',
    'energy': 'Fuel & Energy',
    'housing': 'Housing & Rent',
    'rent': 'Housing & Rent',
    'utilities': 'Utilities',
    'healthcare': 'Healthcare & Medical',
    'medical': 'Healthcare & Medical',
    'health': 'Healthcare & Medical',
    'personal care': 'Personal Care & Hygiene',
    'hygiene': 'Personal Care & Hygiene',
    'household': 'Household Supplies',
    'cleaning': 'Household Supplies',
    'clothing': 'Clothing & Apparel',
    'apparel': 'Clothing & Apparel',
    'electronics': 'Electronics & Tech',
    'restaurants': 'Restaurants & Dining Out',
    'dining': 'Restaurants & Dining Out',
    'dining out': 'Restaurants & Dining Out',
    'restaurants & dining out': 'Restaurants & Dining Out',
  };

  static bool isDefaultCategory(String categoryName) {
    return defaultCategoryKeys.contains(categoryName);
  }

  static String normalizeLanguageCode(String? languageCode) {
    if (supportedLanguageCodes.contains(languageCode)) {
      return languageCode!;
    }
    return 'en';
  }

  static String displayName(
    String categoryName, {
    required String languageCode,
  }) {
    if (!isDefaultCategory(categoryName)) {
      return categoryName;
    }

    return _displayNameForLocalizations(
      _localizationsForLanguageCode(languageCode),
      categoryName,
    );
  }

  static String displayNameForContext(
    BuildContext context,
    String categoryName,
  ) {
    return displayName(
      categoryName,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  static String resolveCanonicalName(
    String suggested,
    Iterable<String> availableCategoryNames,
  ) {
    final names = availableCategoryNames.toList(growable: false);
    final trimmed = suggested.trim();
    if (trimmed.isEmpty) {
      return _fallbackFrom(names);
    }

    final alias = _aliases[trimmed.toLowerCase()];
    if (alias != null) {
      final matchedAlias = _matchAvailable(alias, names);
      if (matchedAlias != null) {
        return matchedAlias;
      }
    }

    final exact = _matchAvailable(trimmed, names);
    if (exact != null) {
      return exact;
    }

    final lowered = trimmed.toLowerCase();
    for (final name in names) {
      final candidate = name.toLowerCase();
      if (candidate.contains(lowered) || lowered.contains(candidate)) {
        return name;
      }
    }

    for (final languageCode in supportedLanguageCodes) {
      final localizations = _localizationsForLanguageCode(languageCode);
      for (final categoryKey in defaultCategoryKeys) {
        final candidate =
            _displayNameForLocalizations(localizations, categoryKey)
                .toLowerCase();
        if (candidate == lowered ||
            candidate.contains(lowered) ||
            lowered.contains(candidate)) {
          final match = _matchAvailable(categoryKey, names);
          if (match != null) {
            return match;
          }
        }
      }
    }

    return _fallbackFrom(names);
  }

  static String _fallbackFrom(List<String> names) {
    if (names.contains(fallbackCategory)) {
      return fallbackCategory;
    }
    if (names.isNotEmpty) {
      return names.first;
    }
    return fallbackCategory;
  }

  static String? _matchAvailable(String candidate, List<String> names) {
    for (final name in names) {
      if (name.toLowerCase() == candidate.toLowerCase()) {
        return name;
      }
    }
    return null;
  }

  static AppLocalizations _localizationsForLanguageCode(String languageCode) {
    switch (normalizeLanguageCode(languageCode)) {
      case 'de':
        return AppLocalizationsDe();
      case 'fr':
        return AppLocalizationsFr();
      case 'it':
        return AppLocalizationsIt();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  static String _displayNameForLocalizations(
    AppLocalizations localizations,
    String categoryName,
  ) {
    switch (categoryName) {
      case 'Food & Groceries':
        return localizations.categoryFoodGroceries;
      case 'Restaurants & Dining Out':
        return localizations.categoryRestaurantsDiningOut;
      case 'Beverages':
        return localizations.categoryBeverages;
      case 'Transportation':
        return localizations.categoryTransportation;
      case 'Fuel & Energy':
        return localizations.categoryFuelEnergy;
      case 'Housing & Rent':
        return localizations.categoryHousingRent;
      case 'Utilities':
        return localizations.categoryUtilities;
      case 'Healthcare & Medical':
        return localizations.categoryHealthcareMedical;
      case 'Personal Care & Hygiene':
        return localizations.categoryPersonalCareHygiene;
      case 'Household Supplies':
        return localizations.categoryHouseholdSupplies;
      case 'Clothing & Apparel':
        return localizations.categoryClothingApparel;
      case 'Electronics & Tech':
        return localizations.categoryElectronicsTech;
      default:
        return categoryName;
    }
  }
}
