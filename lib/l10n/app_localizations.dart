import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it')
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'InflaBasket'**
  String get appTitle;

  /// Bottom nav: Overview tab
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// Bottom nav: History tab
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Bottom nav: Categories tab
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// Bottom nav: Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// FAB / AppBar button to add a new purchase entry
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// AppBar title when editing an existing entry
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// Generic save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Generic no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Generic close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Generic edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Generic loading label
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorGeneric;

  /// Form validation: required field
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// Form validation: invalid number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get fieldInvalidNumber;

  /// Form validation: must be positive
  ///
  /// In en, this message translates to:
  /// **'Must be greater than zero'**
  String get fieldPositiveNumber;

  /// Label for product name field
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// Hint text for product name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Whole Milk'**
  String get productHint;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for store name field
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// Hint text for store name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Migros'**
  String get storeHint;

  /// Label for location field
  ///
  /// In en, this message translates to:
  /// **'Location (City / Branch)'**
  String get location;

  /// Hint text for location field
  ///
  /// In en, this message translates to:
  /// **'e.g. Zurich, Bahnhofstrasse'**
  String get locationHint;

  /// Label for price field
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Label for quantity field
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Label for unit dropdown
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Label for date picker
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Hint for notes field
  ///
  /// In en, this message translates to:
  /// **'Optional notes…'**
  String get notesHint;

  /// Button to open AI receipt scanner
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt (Premium)'**
  String get scanReceipt;

  /// Button to scan a product barcode
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// Message when barcode lookup returns no result
  ///
  /// In en, this message translates to:
  /// **'Product not found for this barcode.'**
  String get barcodeNotFound;

  /// Error message for barcode scan failure
  ///
  /// In en, this message translates to:
  /// **'Could not scan barcode. Please try again.'**
  String get barcodeError;

  /// Snackbar message when entry is saved
  ///
  /// In en, this message translates to:
  /// **'Entry saved successfully.'**
  String get entrySaved;

  /// Snackbar message when entry is deleted
  ///
  /// In en, this message translates to:
  /// **'Entry deleted.'**
  String get entryDeleted;

  /// Snackbar error when save fails
  ///
  /// In en, this message translates to:
  /// **'Error saving entry: {error}'**
  String entrySaveError(String error);

  /// Confirmation dialog title for deleting an entry
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryConfirm;

  /// Confirmation dialog body for deleting an entry
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteEntryMessage;

  /// Empty state message in history tab
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get noEntriesYet;

  /// Empty state when filters produce no results
  ///
  /// In en, this message translates to:
  /// **'No entries match the current filters.'**
  String get noEntriesFiltered;

  /// Bottom sheet title for filter options
  ///
  /// In en, this message translates to:
  /// **'Filter History'**
  String get filterTitle;

  /// Section header for date range filter
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get filterDateRange;

  /// Date range filter option
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get filterLast30Days;

  /// Date range filter option
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get filterLast6Months;

  /// Date range filter option
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get filterAllTime;

  /// Section header for category filter
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// Option for no category filter
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get filterAllCategories;

  /// Button to apply filters
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyFilters;

  /// Button to clear filters
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilters;

  /// Title card on overview tab
  ///
  /// In en, this message translates to:
  /// **'Your Inflation'**
  String get overviewTitle;

  /// Chart section header
  ///
  /// In en, this message translates to:
  /// **'Basket Index'**
  String get overviewBasketIndex;

  /// Section header for biggest price increases
  ///
  /// In en, this message translates to:
  /// **'Top Inflators'**
  String get overviewTopInflators;

  /// Section header for biggest price decreases
  ///
  /// In en, this message translates to:
  /// **'Top Deflators'**
  String get overviewTopDeflators;

  /// Empty state on overview tab
  ///
  /// In en, this message translates to:
  /// **'Log at least two purchases of the same product to see inflation.'**
  String get overviewNoData;

  /// Toggle label for CPI comparison overlay
  ///
  /// In en, this message translates to:
  /// **'vs National Average'**
  String get showNationalAverage;

  /// Label for macro comparison overlay controls
  ///
  /// In en, this message translates to:
  /// **'Compare with'**
  String get showComparisonOverlay;

  /// Message when no CPI source exists for currency
  ///
  /// In en, this message translates to:
  /// **'National CPI data not available for the selected currency.'**
  String get cpiUnavailable;

  /// Error loading CPI data
  ///
  /// In en, this message translates to:
  /// **'Could not load national CPI data.'**
  String get cpiLoadError;

  /// Error loading comparison overlay data
  ///
  /// In en, this message translates to:
  /// **'Could not load comparison data.'**
  String get comparisonLoadError;

  /// Legend label for user basket line
  ///
  /// In en, this message translates to:
  /// **'Your Inflation'**
  String get yourInflation;

  /// Legend label for CPI line
  ///
  /// In en, this message translates to:
  /// **'National CPI'**
  String get nationalCpi;

  /// Legend label for M2 money supply overlay
  ///
  /// In en, this message translates to:
  /// **'M2 Money Supply'**
  String get moneySupplyM2;

  /// Section title for categories tab
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoriesTitle;

  /// Empty state on categories tab
  ///
  /// In en, this message translates to:
  /// **'No category data available yet.'**
  String get categoryNoCategoryData;

  /// Settings screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// Status for active premium subscription
  ///
  /// In en, this message translates to:
  /// **'Premium Active'**
  String get settingsPremiumActive;

  /// Status for free tier
  ///
  /// In en, this message translates to:
  /// **'Free Tier'**
  String get settingsFreeTier;

  /// Subtitle for premium status
  ///
  /// In en, this message translates to:
  /// **'Enjoy AI receipt scanning and auto-categorization.'**
  String get settingsPremiumSubtitle;

  /// Subtitle for free tier status
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock AI receipt scanning.'**
  String get settingsFreeSubtitle;

  /// Button to restore purchases
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestore;

  /// Button to upgrade to premium
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsUpgrade;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// Currency setting label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// Toggle label for metric/imperial
  ///
  /// In en, this message translates to:
  /// **'Use Metric System'**
  String get settingsMetricSystem;

  /// Subtitle for metric toggle
  ///
  /// In en, this message translates to:
  /// **'For quantities and unit prices'**
  String get settingsMetricSubtitle;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsDataManagement;

  /// List tile label
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get settingsManageCategories;

  /// Subtitle for manage categories tile
  ///
  /// In en, this message translates to:
  /// **'Add or remove custom categories'**
  String get settingsManageCategoriesSubtitle;

  /// List tile label for CSV export
  ///
  /// In en, this message translates to:
  /// **'Export Data (CSV)'**
  String get settingsExportData;

  /// Subtitle for export tile
  ///
  /// In en, this message translates to:
  /// **'Download your purchase history'**
  String get settingsExportSubtitle;

  /// List tile label for custom basket weights
  ///
  /// In en, this message translates to:
  /// **'Category Weights'**
  String get settingsCategoryWeights;

  /// Subtitle for category weights tile
  ///
  /// In en, this message translates to:
  /// **'Customize how categories are weighted in your basket'**
  String get settingsCategoryWeightsSubtitle;

  /// List tile label for purchase templates
  ///
  /// In en, this message translates to:
  /// **'Recurring Purchases'**
  String get settingsTemplates;

  /// Subtitle for templates tile
  ///
  /// In en, this message translates to:
  /// **'Quick-add templates for regular purchases'**
  String get settingsTemplatesSubtitle;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Version list tile label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Privacy policy list tile label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// Terms of service list tile label
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// Placeholder for unavailable features
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsComingSoon;

  /// Screen title for category management
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get categoryManagementTitle;

  /// Badge for custom categories
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get categoryManagementCustomBadge;

  /// Badge for default categories
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get categoryManagementDefaultBadge;

  /// Dialog title for adding a category
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategoryTitle;

  /// Hint text for new category name field
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get addCategoryHint;

  /// Confirmation dialog title for deleting a category
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteCategoryConfirm(String name);

  /// Error when deleting category with products
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: this category has existing products.'**
  String get deleteCategoryHasProducts;

  /// Screen title for weight editor
  ///
  /// In en, this message translates to:
  /// **'Category Weights'**
  String get weightEditorTitle;

  /// Explanation text on weight editor screen
  ///
  /// In en, this message translates to:
  /// **'Adjust how much each category contributes to your basket inflation. Weights must sum to 100%.'**
  String get weightEditorSubtitle;

  /// Shows current sum of all weights
  ///
  /// In en, this message translates to:
  /// **'Total: {percent}%'**
  String weightEditorTotal(int percent);

  /// Button to reset all weights to equal distribution
  ///
  /// In en, this message translates to:
  /// **'Reset to Equal'**
  String get weightEditorResetEqual;

  /// Error when trying to save weights that don't sum to 100
  ///
  /// In en, this message translates to:
  /// **'Weights must sum to 100% before saving.'**
  String get weightEditorSaveError;

  /// Screen title for templates
  ///
  /// In en, this message translates to:
  /// **'Recurring Purchases'**
  String get templatesTitle;

  /// Empty state for templates screen
  ///
  /// In en, this message translates to:
  /// **'No templates yet. Add a template to quickly re-enter regular purchases.'**
  String get templatesEmpty;

  /// FAB label on templates screen
  ///
  /// In en, this message translates to:
  /// **'Add Template'**
  String get templateAdd;

  /// Confirmation title when deleting a template
  ///
  /// In en, this message translates to:
  /// **'Delete template?'**
  String get templateDelete;

  /// Button to apply a template as a new entry
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get templateUseButton;

  /// Snackbar when template is saved
  ///
  /// In en, this message translates to:
  /// **'Template saved.'**
  String get templateSaved;

  /// Snackbar when template is deleted
  ///
  /// In en, this message translates to:
  /// **'Template deleted.'**
  String get templateDeleted;

  /// Dialog title for duplicate product detection
  ///
  /// In en, this message translates to:
  /// **'Similar Product Found'**
  String get duplicateDetectionTitle;

  /// Dialog body for duplicate detection
  ///
  /// In en, this message translates to:
  /// **'\"{newName}\" looks similar to an existing product: \"{existing}\". Link to the existing product or create a new one?'**
  String duplicateDetectionMessage(String newName, String existing);

  /// Button to link to existing product
  ///
  /// In en, this message translates to:
  /// **'Link to Existing'**
  String get duplicateDetectionLinkExisting;

  /// Button to create a new product
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get duplicateDetectionCreateNew;

  /// Feature name
  ///
  /// In en, this message translates to:
  /// **'Price Alerts'**
  String get priceAlerts;

  /// Notification title for price alert
  ///
  /// In en, this message translates to:
  /// **'Price Alert: {product}'**
  String priceAlertTitle(String product);

  /// Notification body for price alert
  ///
  /// In en, this message translates to:
  /// **'{product} is {percent}% more expensive than your last purchase ({oldPrice} → {newPrice}).'**
  String priceAlertBody(
      String product, String percent, String oldPrice, String newPrice);

  /// Label showing the alert threshold
  ///
  /// In en, this message translates to:
  /// **'Alert threshold: {percent}%'**
  String priceAlertThreshold(int percent);

  /// AppBar title for scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scannerTitle;

  /// Button to use camera for scanning
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get scannerSelectCamera;

  /// Button to select from gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get scannerSelectGallery;

  /// Loading label while AI processes
  ///
  /// In en, this message translates to:
  /// **'Processing receipt…'**
  String get scannerProcessing;

  /// Error when AI scanning fails
  ///
  /// In en, this message translates to:
  /// **'Could not parse receipt. Please try again.'**
  String get scannerError;

  /// Dialog/screen title for receipt review
  ///
  /// In en, this message translates to:
  /// **'Review Items'**
  String get scannerReviewTitle;

  /// Button to save selected items from receipt
  ///
  /// In en, this message translates to:
  /// **'Save {count} Items'**
  String scannerSaveItems(int count);

  /// Toggle to select all receipt items
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get scannerSelectAll;

  /// Toggle to deselect all receipt items
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get scannerDeselectAll;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
