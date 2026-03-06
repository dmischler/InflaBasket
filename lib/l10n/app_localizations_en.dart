// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'InflaBasket';

  @override
  String get navOverview => 'Overview';

  @override
  String get navHistory => 'History';

  @override
  String get navCategories => 'Categories';

  @override
  String get navSettings => 'Settings';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get reset => 'Reset';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get fieldInvalidNumber => 'Please enter a valid number';

  @override
  String get fieldPositiveNumber => 'Must be greater than zero';

  @override
  String get product => 'Product';

  @override
  String get productHint => 'e.g. Whole Milk';

  @override
  String get category => 'Category';

  @override
  String get store => 'Store';

  @override
  String get storeHint => 'e.g. Migros';

  @override
  String get location => 'Location (City / Branch)';

  @override
  String get locationHint => 'e.g. Zurich, Bahnhofstrasse';

  @override
  String get price => 'Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get date => 'Date';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Optional notes…';

  @override
  String get scanReceipt => 'Scan Receipt (Premium)';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get barcodeNotFound => 'Product not found for this barcode.';

  @override
  String get barcodeError => 'Could not scan barcode. Please try again.';

  @override
  String get entrySaved => 'Entry saved successfully.';

  @override
  String get entryDeleted => 'Entry deleted.';

  @override
  String entrySaveError(String error) {
    return 'Error saving entry: $error';
  }

  @override
  String get deleteEntryConfirm => 'Delete this entry?';

  @override
  String get deleteEntryMessage => 'This action cannot be undone.';

  @override
  String get noEntriesYet => 'No entries yet.';

  @override
  String get noEntriesFiltered => 'No entries match the current filters.';

  @override
  String get filterTitle => 'Filter History';

  @override
  String get filterDateRange => 'Date Range';

  @override
  String get filterLast30Days => 'Last 30 Days';

  @override
  String get filterLast6Months => 'Last 6 Months';

  @override
  String get filterAllTime => 'All Time';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterAllCategories => 'All Categories';

  @override
  String get applyFilters => 'Apply';

  @override
  String get clearFilters => 'Clear';

  @override
  String get overviewTitle => 'Your Inflation';

  @override
  String get overviewBasketIndex => 'Basket Index';

  @override
  String get overviewTopInflators => 'Top Inflators';

  @override
  String get overviewTopDeflators => 'Top Deflators';

  @override
  String get overviewNoData =>
      'Log at least two purchases of the same product to see inflation.';

  @override
  String get showNationalAverage => 'vs National Average';

  @override
  String get showComparisonOverlay => 'Compare with';

  @override
  String get cpiUnavailable =>
      'National CPI data not available for the selected currency.';

  @override
  String get cpiLoadError => 'Could not load national CPI data.';

  @override
  String get comparisonLoadError => 'Could not load comparison data.';

  @override
  String get yourInflation => 'Your Inflation';

  @override
  String get nationalCpi => 'National CPI';

  @override
  String get moneySupplyM2 => 'M2 Money Supply';

  @override
  String get categoriesTitle => 'Category Breakdown';

  @override
  String get categoryNoCategoryData => 'No category data available yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsPremiumActive => 'Premium Active';

  @override
  String get settingsFreeTier => 'Free Tier';

  @override
  String get settingsPremiumSubtitle =>
      'Enjoy AI receipt scanning and auto-categorization.';

  @override
  String get settingsFreeSubtitle => 'Upgrade to unlock AI receipt scanning.';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsMetricSystem => 'Use Metric System';

  @override
  String get settingsMetricSubtitle => 'For quantities and unit prices';

  @override
  String get settingsDataManagement => 'Data Management';

  @override
  String get settingsManageCategories => 'Manage Categories';

  @override
  String get settingsManageCategoriesSubtitle =>
      'Add or remove custom categories';

  @override
  String get settingsExportData => 'Export Data (CSV)';

  @override
  String get settingsExportSubtitle => 'Download your purchase history';

  @override
  String get settingsCategoryWeights => 'Category Weights';

  @override
  String get settingsCategoryWeightsSubtitle =>
      'Customize how categories are weighted in your basket';

  @override
  String get settingsTemplates => 'Recurring Purchases';

  @override
  String get settingsTemplatesSubtitle =>
      'Quick-add templates for regular purchases';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsComingSoon => 'Coming soon';

  @override
  String get categoryManagementTitle => 'Manage Categories';

  @override
  String get categoryManagementCustomBadge => 'Custom';

  @override
  String get categoryManagementDefaultBadge => 'Default';

  @override
  String get addCategoryTitle => 'Add Category';

  @override
  String get addCategoryHint => 'Category name';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteCategoryHasProducts =>
      'Cannot delete: this category has existing products.';

  @override
  String get weightEditorTitle => 'Category Weights';

  @override
  String get weightEditorSubtitle =>
      'Adjust how much each category contributes to your basket inflation. Weights must sum to 100%.';

  @override
  String weightEditorTotal(int percent) {
    return 'Total: $percent%';
  }

  @override
  String get weightEditorResetEqual => 'Reset to Equal';

  @override
  String get weightEditorSaveError => 'Weights must sum to 100% before saving.';

  @override
  String get templatesTitle => 'Recurring Purchases';

  @override
  String get templatesEmpty =>
      'No templates yet. Add a template to quickly re-enter regular purchases.';

  @override
  String get templateAdd => 'Add Template';

  @override
  String get templateDelete => 'Delete template?';

  @override
  String get templateUseButton => 'Use';

  @override
  String get templateSaved => 'Template saved.';

  @override
  String get templateDeleted => 'Template deleted.';

  @override
  String get duplicateDetectionTitle => 'Similar Product Found';

  @override
  String duplicateDetectionMessage(String newName, String existing) {
    return '\"$newName\" looks similar to an existing product: \"$existing\". Link to the existing product or create a new one?';
  }

  @override
  String get duplicateDetectionLinkExisting => 'Link to Existing';

  @override
  String get duplicateDetectionCreateNew => 'Create New';

  @override
  String get priceAlerts => 'Price Alerts';

  @override
  String priceAlertTitle(String product) {
    return 'Price Alert: $product';
  }

  @override
  String priceAlertBody(
      String product, String percent, String oldPrice, String newPrice) {
    return '$product is $percent% more expensive than your last purchase ($oldPrice → $newPrice).';
  }

  @override
  String priceAlertThreshold(int percent) {
    return 'Alert threshold: $percent%';
  }

  @override
  String get scannerTitle => 'Scan Receipt';

  @override
  String get scannerSelectCamera => 'Camera';

  @override
  String get scannerSelectGallery => 'Gallery';

  @override
  String get scannerProcessing => 'Processing receipt…';

  @override
  String get scannerError => 'Could not parse receipt. Please try again.';

  @override
  String get scannerReviewTitle => 'Review Items';

  @override
  String scannerSaveItems(int count) {
    return 'Save $count Items';
  }

  @override
  String get scannerSelectAll => 'Select All';

  @override
  String get scannerDeselectAll => 'Deselect All';
}
