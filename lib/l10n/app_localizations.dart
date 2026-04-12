import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
    Locale('en')
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

  /// Hint shown next to history entries
  ///
  /// In en, this message translates to:
  /// **'Swipe to edit'**
  String get swipeToEdit;

  /// Hint shown next to history entries
  ///
  /// In en, this message translates to:
  /// **'Swipe to delete'**
  String get swipeToDelete;

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

  /// Accessibility label for chart skeleton loaders
  ///
  /// In en, this message translates to:
  /// **'Loading chart'**
  String get loadingChart;

  /// Title shown when chart loading takes longer than expected
  ///
  /// In en, this message translates to:
  /// **'Still loading...'**
  String get loadingStillTitle;

  /// Message shown when chart loading takes longer than expected
  ///
  /// In en, this message translates to:
  /// **'This might take a moment due to a slow connection.'**
  String get loadingStillMessage;

  /// Accessibility label for empty state animations
  ///
  /// In en, this message translates to:
  /// **'Empty state illustration'**
  String get emptyStateAnimationDescription;

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
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// Snackbar message when no API key is configured for receipt scanning
  ///
  /// In en, this message translates to:
  /// **'Configure your AI API key in Settings to enable receipt scanning'**
  String get settingsConfigureApiKey;

  /// Settings section header for AI provider configuration
  ///
  /// In en, this message translates to:
  /// **'AI Configuration'**
  String get settingsAiConfiguration;

  /// Navigation label for API keys submenu
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get settingsApiKeys;

  /// Title for API keys management screen
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get apiKeysTitle;

  /// Button to add a new API key
  ///
  /// In en, this message translates to:
  /// **'Add API Key'**
  String get apiKeyAdd;

  /// Dialog title for adding an API key
  ///
  /// In en, this message translates to:
  /// **'Add API Key'**
  String get apiKeyAddTitle;

  /// Empty state title when no API keys exist
  ///
  /// In en, this message translates to:
  /// **'No API keys configured'**
  String get apiKeyNoKeysYet;

  /// Empty state description when no API keys exist
  ///
  /// In en, this message translates to:
  /// **'Add an API key to enable receipt scanning.'**
  String get apiKeyNoKeysYetDesc;

  /// Label for provider dropdown in add key dialog
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get apiKeyProvider;

  /// Label for API key name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get apiKeyNameLabel;

  /// Hint text for API key name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Personal, Work'**
  String get apiKeyNameHint;

  /// Action to view full API key
  ///
  /// In en, this message translates to:
  /// **'View Key'**
  String get apiKeyView;

  /// Action to copy API key to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy Key'**
  String get apiKeyCopy;

  /// Snackbar after copying API key
  ///
  /// In en, this message translates to:
  /// **'API key copied to clipboard'**
  String get apiKeyCopied;

  /// Action to delete an API key
  ///
  /// In en, this message translates to:
  /// **'Delete Key'**
  String get apiKeyDelete;

  /// Dialog title for confirming API key deletion
  ///
  /// In en, this message translates to:
  /// **'Delete API Key?'**
  String get apiKeyDeleteConfirmTitle;

  /// Dialog body for confirming API key deletion
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this API key. You can always add it again later.'**
  String get apiKeyDeleteConfirmMessage;

  /// Action to set an API key as the active one
  ///
  /// In en, this message translates to:
  /// **'Set as Active'**
  String get apiKeySetActive;

  /// Label for AI provider dropdown
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get settingsAiProvider;

  /// Label for API key input field
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get settingsApiKey;

  /// Hint text for Gemini API key input
  ///
  /// In en, this message translates to:
  /// **'Enter your Gemini API key'**
  String get settingsApiKeyHintGemini;

  /// Hint text for OpenAI API key input
  ///
  /// In en, this message translates to:
  /// **'Enter your OpenAI API key'**
  String get settingsApiKeyHintOpenai;

  /// Status when API key is set
  ///
  /// In en, this message translates to:
  /// **'API key configured'**
  String get settingsApiKeyConfigured;

  /// Status when API key is not set
  ///
  /// In en, this message translates to:
  /// **'No API key configured'**
  String get settingsApiKeyNotConfigured;

  /// Privacy note about API key storage
  ///
  /// In en, this message translates to:
  /// **'Your API key is stored locally on this device and is never sent to our servers. Database imports include API keys — share backup files with care.'**
  String get settingsApiKeyPrivacyNote;

  /// Warning shown before database export about API keys
  ///
  /// In en, this message translates to:
  /// **'This backup will include your API keys and settings. Only share with trusted parties.'**
  String get settingsExportApiKeyWarning;

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
  /// **'Ø Yearly inflation'**
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

  /// Title for chart overlay type bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Chart Overlay'**
  String get chartOverlayType;

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
  /// **'Money Supply (M2)'**
  String get moneySupplyM2;

  /// Legend label for SNB Core Inflation 1 overlay
  ///
  /// In en, this message translates to:
  /// **'Core Inflation'**
  String get coreInflationSnb;

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

  /// Settings section header for UI settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Currency setting label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Toggle label for metric/imperial
  ///
  /// In en, this message translates to:
  /// **'Use Metric System'**
  String get settingsMetricSystem;

  /// Toggle label for dark/light mode
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// Description for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get settingsDarkModeDesc;

  /// Toggle label for price update reminder
  ///
  /// In en, this message translates to:
  /// **'Price Updates'**
  String get settingsPriceUpdateReminder;

  /// Description for price update reminder toggle
  ///
  /// In en, this message translates to:
  /// **'Get reminded to update prices'**
  String get settingsPriceUpdateReminderDesc;

  /// Label for the reminder toggle
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get settingsReminder;

  /// Label for reminder duration
  ///
  /// In en, this message translates to:
  /// **'Reminder after'**
  String get settingsReminderAfter;

  /// Button to navigate to price updates screen
  ///
  /// In en, this message translates to:
  /// **'Show Price Update List'**
  String get settingsShowPriceUpdateList;

  /// Helper text when toggle is disabled
  ///
  /// In en, this message translates to:
  /// **'Enable to track price updates'**
  String get settingsPriceUpdateReminderDisabled;

  /// Title for price updates screen
  ///
  /// In en, this message translates to:
  /// **'Update Prices'**
  String get priceUpdatesTitle;

  /// Label for products without price
  ///
  /// In en, this message translates to:
  /// **'No price yet'**
  String get priceUpdatesNoPriceYet;

  /// Snackbar message after saving price
  ///
  /// In en, this message translates to:
  /// **'Price saved'**
  String get priceUpdatesSaved;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'All prices are up to date – great!'**
  String get priceUpdatesAllCurrent;

  /// Empty state description
  ///
  /// In en, this message translates to:
  /// **'All your product prices are current.'**
  String get priceUpdatesAllCurrentDesc;

  /// Settings section header for data management options
  ///
  /// In en, this message translates to:
  /// **'Data Options'**
  String get settingsDataOptions;

  /// List tile label
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get settingsManageCategories;

  /// List tile label for CSV export
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settingsExportData;

  /// List tile label for factory reset
  ///
  /// In en, this message translates to:
  /// **'Factory Reset'**
  String get settingsFactoryReset;

  /// Dialog title for factory reset confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset App?'**
  String get factoryResetConfirmTitle;

  /// Warning message in factory reset dialog
  ///
  /// In en, this message translates to:
  /// **'This will delete all your data including purchase history, categories, and settings. This action cannot be undone.'**
  String get factoryResetConfirmMessage;

  /// Confirm button for factory reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get factoryResetButton;

  /// Snackbar message after factory reset
  ///
  /// In en, this message translates to:
  /// **'Factory reset completed'**
  String get factoryResetCompleted;

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

  /// Label showing similarity percentage
  ///
  /// In en, this message translates to:
  /// **'Similarity'**
  String get similarity;

  /// Label for scanned product in comparison dialog
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get scannedProduct;

  /// Label for existing product in comparison dialog
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get existingProduct;

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

  /// Default category label for food and groceries
  ///
  /// In en, this message translates to:
  /// **'Food & Groceries'**
  String get categoryFoodGroceries;

  /// Default category label for restaurants and dining out
  ///
  /// In en, this message translates to:
  /// **'Restaurants & Dining Out'**
  String get categoryRestaurantsDiningOut;

  /// Default category label for beverages
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// Default category label for transportation
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransportation;

  /// Default category label for fuel and energy
  ///
  /// In en, this message translates to:
  /// **'Fuel & Energy'**
  String get categoryFuelEnergy;

  /// Default category label for housing and rent
  ///
  /// In en, this message translates to:
  /// **'Housing & Rent'**
  String get categoryHousingRent;

  /// Default category label for utilities
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// Default category label for healthcare and medical
  ///
  /// In en, this message translates to:
  /// **'Healthcare & Medical'**
  String get categoryHealthcareMedical;

  /// Default category label for personal care and hygiene
  ///
  /// In en, this message translates to:
  /// **'Personal Care & Hygiene'**
  String get categoryPersonalCareHygiene;

  /// Default category label for household supplies
  ///
  /// In en, this message translates to:
  /// **'Household Supplies'**
  String get categoryHouseholdSupplies;

  /// Default category label for clothing and apparel
  ///
  /// In en, this message translates to:
  /// **'Clothing & Apparel'**
  String get categoryClothingApparel;

  /// Default category label for electronics and tech
  ///
  /// In en, this message translates to:
  /// **'Electronics & Tech'**
  String get categoryElectronicsTech;

  /// Hint text for desktop drag and drop
  ///
  /// In en, this message translates to:
  /// **'Drop a JPG, JPEG, PNG, or WEBP receipt image.'**
  String get scannerDropImage;

  /// Drag label for desktop drop zone
  ///
  /// In en, this message translates to:
  /// **'Drag a receipt image here'**
  String get scannerDragImage;

  /// Drop label when dragging over drop zone
  ///
  /// In en, this message translates to:
  /// **'Drop here'**
  String get scannerDropHere;

  /// Button to take photo with camera
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get scannerTakePhoto;

  /// Button to select image from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get scannerChooseImage;

  /// Title while AI processes receipt
  ///
  /// In en, this message translates to:
  /// **'Analyzing Receipt'**
  String get scannerAnalyzingTitle;

  /// Message while AI processes receipt
  ///
  /// In en, this message translates to:
  /// **'The AI is extracting line items, totals, and suggested categories.'**
  String get scannerAnalyzingMessage;

  /// Instructions on receipt review screen
  ///
  /// In en, this message translates to:
  /// **'Uncheck items you don\'t want to save. Tap names, prices, quantities, or categories to edit.'**
  String get scannerReviewInstructions;

  /// Title for inflation by category section
  ///
  /// In en, this message translates to:
  /// **'Inflation by Category'**
  String get categoryInflationTitle;

  /// Title for category details section
  ///
  /// In en, this message translates to:
  /// **'Category Details'**
  String get categoryDetailsTitle;

  /// Empty state when no price increases found
  ///
  /// In en, this message translates to:
  /// **'No price increases detected yet!'**
  String get overviewNoPriceIncreases;

  /// Empty state when no price decreases found
  ///
  /// In en, this message translates to:
  /// **'No price decreases detected yet.'**
  String get overviewNoPriceDecreases;

  /// Dialog title for duplicate product detection
  ///
  /// In en, this message translates to:
  /// **'Similar Product Found'**
  String get duplicateProductFound;

  /// Dialog body for duplicate product detection
  ///
  /// In en, this message translates to:
  /// **'\"{newName}\" looks similar to an existing product: \"{existing}\". Link to the existing product or create a new one?'**
  String duplicateProductMessage(String newName, String existing);

  /// Empty state when not enough data for chart
  ///
  /// In en, this message translates to:
  /// **'Not enough data to chart.'**
  String get categoryNoChartData;

  /// Dialog title for deleting an entry
  ///
  /// In en, this message translates to:
  /// **'Delete Entry?'**
  String get historyDeleteTitle;

  /// Dialog message for deleting an entry
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this purchase entry?'**
  String get historyDeleteMessage;

  /// Toggle label to enable price alert
  ///
  /// In en, this message translates to:
  /// **'Enable alert'**
  String get priceAlertEnableAlert;

  /// Subtitle for alert enable toggle
  ///
  /// In en, this message translates to:
  /// **'Notify me when the next logged price changes beyond this threshold.'**
  String get priceAlertNotifyMe;

  /// Label showing current threshold percentage
  ///
  /// In en, this message translates to:
  /// **'Threshold: {percent}%'**
  String priceAlertThresholdLabel(String percent);

  /// Button to save price alert
  ///
  /// In en, this message translates to:
  /// **'Save Alert'**
  String get priceAlertSaveAlert;

  /// Loading title while fetching alerts
  ///
  /// In en, this message translates to:
  /// **'Loading Alerts'**
  String get priceAlertLoadingAlerts;

  /// Loading message while fetching alerts
  ///
  /// In en, this message translates to:
  /// **'Gathering tracked products and existing alert thresholds.'**
  String get priceAlertLoadingAlertsMessage;

  /// Error title when alerts fail to load
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Alerts'**
  String get priceAlertLoadError;

  /// Empty state when no products to track
  ///
  /// In en, this message translates to:
  /// **'No Products To Track Yet'**
  String get priceAlertNoProducts;

  /// Empty state message for price alerts
  ///
  /// In en, this message translates to:
  /// **'Add a few purchases first, then enable alerts for the products you want to watch.'**
  String get priceAlertNoProductsMessage;

  /// Loading title while fetching settings
  ///
  /// In en, this message translates to:
  /// **'Loading Alert Settings'**
  String get priceAlertLoadingSettings;

  /// Loading message while fetching settings
  ///
  /// In en, this message translates to:
  /// **'Fetching saved thresholds for your tracked items.'**
  String get priceAlertLoadingSettingsMessage;

  /// Snackbar message when receipt items are saved
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 item saved successfully!} other {{count} items saved successfully!}}'**
  String scannerSavedItems(int count);

  /// Snackbar message when receipt items are saved and duplicates are skipped
  ///
  /// In en, this message translates to:
  /// **'{savedCount, plural, =0 {No new items saved. {skippedCount} duplicates skipped.} =1 {1 item saved. {skippedCount} duplicates skipped.} other {{savedCount} items saved. {skippedCount} duplicates skipped.}}'**
  String scannerSavedItemsWithSkippedDuplicates(
      int savedCount, int skippedCount);

  /// Empty state on category management screen
  ///
  /// In en, this message translates to:
  /// **'No categories found.'**
  String get categoryManagementEmpty;

  /// Error message when categories fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading categories: {error}'**
  String categoryManagementError(String error);

  /// Default store name when unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown Store'**
  String get unknownStore;

  /// Swiss Franc currency code
  ///
  /// In en, this message translates to:
  /// **'CHF'**
  String get currencyChf;

  /// Euro currency code
  ///
  /// In en, this message translates to:
  /// **'EUR'**
  String get currencyEur;

  /// US Dollar currency code
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get currencyUsd;

  /// British Pound currency code
  ///
  /// In en, this message translates to:
  /// **'GBP'**
  String get currencyGbp;

  /// Button to choose image from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get scannerChooseFromGallery;

  /// Error when saving scanned receipt items fails
  ///
  /// In en, this message translates to:
  /// **'Error saving items: {error}'**
  String scannerSaveError(String error);

  /// Manual entry option in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// Barcode scanner option in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// Receipt scanner option in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scannerOption;

  /// Message shown when barcode is scanned
  ///
  /// In en, this message translates to:
  /// **'Barcode: {barcode}'**
  String barcodeScanned(String barcode);

  /// Hint text shown in barcode scanner
  ///
  /// In en, this message translates to:
  /// **'Point camera at barcode'**
  String get scannerPointAtBarcode;

  /// Fallback item name when none was detected
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get unknownItem;

  /// Empty title when history filters hide all entries
  ///
  /// In en, this message translates to:
  /// **'No Matching Entries'**
  String get historyNoMatchingTitle;

  /// Empty-state guidance when history filters hide all entries
  ///
  /// In en, this message translates to:
  /// **'Try adjusting or clearing your filters.'**
  String get historyNoMatchingMessage;

  /// Empty-state guidance when no history exists yet
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first purchase entry.'**
  String get historyNoEntriesMessage;

  /// Tooltip for filter controls
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Tooltip for search button
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Bottom sheet title for search
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchTitle;

  /// Hint text for search input field
  ///
  /// In en, this message translates to:
  /// **'Search by item name...'**
  String get searchHint;

  /// Tooltip for clearing search
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// Tooltip for editing an entry
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get historyEditEntryTooltip;

  /// Error label for failed category loads
  ///
  /// In en, this message translates to:
  /// **'Error loading categories: {error}'**
  String errorLoadingCategories(String error);

  /// Subtitle line for category spend totals
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String categoryTotalSpend(String amount);

  /// Tooltip for overlay source info
  ///
  /// In en, this message translates to:
  /// **'Source details'**
  String get comparisonSourceDetails;

  /// Bottom-sheet title for CPI source information
  ///
  /// In en, this message translates to:
  /// **'CPI Source'**
  String get cpiSourceTitle;

  /// Bottom-sheet title for money-supply source information
  ///
  /// In en, this message translates to:
  /// **'Money Supply Source'**
  String get moneySupplySourceTitle;

  /// CPI source description for CHF
  ///
  /// In en, this message translates to:
  /// **'Swiss Federal Statistical Office (FSO) — monthly CPI index for Switzerland.'**
  String get cpiSourceChfDescription;

  /// CPI source description for EUR
  ///
  /// In en, this message translates to:
  /// **'Eurostat — harmonised index of consumer prices (HICP) for the Euro area.'**
  String get cpiSourceEurDescription;

  /// CPI source description fallback
  ///
  /// In en, this message translates to:
  /// **'No CPI data source is available for the selected currency.'**
  String get cpiSourceUnavailableDescription;

  /// Money-supply source description for CHF
  ///
  /// In en, this message translates to:
  /// **'Swiss National Bank (SNB) — M2 money supply for Switzerland.'**
  String get moneySupplySourceChfDescription;

  /// Money-supply source description for EUR
  ///
  /// In en, this message translates to:
  /// **'European Central Bank (ECB) — M2 money supply for the Euro area.'**
  String get moneySupplySourceEurDescription;

  /// Money-supply source description for USD
  ///
  /// In en, this message translates to:
  /// **'Federal Reserve (Fed) — M2 money supply for the United States.'**
  String get moneySupplySourceUsdDescription;

  /// Money-supply source description for GBP
  ///
  /// In en, this message translates to:
  /// **'Bank of England (BoE) — M2 money supply for the United Kingdom.'**
  String get moneySupplySourceGbpDescription;

  /// Money-supply source description fallback
  ///
  /// In en, this message translates to:
  /// **'No money supply data source is available for the selected currency.'**
  String get moneySupplySourceUnavailableDescription;

  /// Latest known price label for a product alert
  ///
  /// In en, this message translates to:
  /// **'Latest price: {price}'**
  String priceAlertLatestPrice(String price);

  /// Label for an enabled alert threshold
  ///
  /// In en, this message translates to:
  /// **'Alert at {percent}% change'**
  String priceAlertAlertAt(String percent);

  /// Label when an alert exists but is disabled
  ///
  /// In en, this message translates to:
  /// **'Alert disabled'**
  String get priceAlertDisabledStatus;

  /// Snackbar after enabling or saving an alert
  ///
  /// In en, this message translates to:
  /// **'Alert saved for {product}.'**
  String priceAlertSaved(String product);

  /// Snackbar after disabling an alert
  ///
  /// In en, this message translates to:
  /// **'Alert disabled for {product}.'**
  String priceAlertDisabled(String product);

  /// Error title for saved price-alert settings
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Alert Settings'**
  String get priceAlertLoadSettingsError;

  /// Label for time range selector
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get timeRangeLabel;

  /// 6 month time range option
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get timeRange6m;

  /// 1 year time range option
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get timeRange1y;

  /// 2 years time range option
  ///
  /// In en, this message translates to:
  /// **'2Y'**
  String get timeRange2y;

  /// 3 years time range option
  ///
  /// In en, this message translates to:
  /// **'3Y'**
  String get timeRange3y;

  /// 5 years time range option
  ///
  /// In en, this message translates to:
  /// **'5Y'**
  String get timeRange5y;

  /// 10 years time range option
  ///
  /// In en, this message translates to:
  /// **'10Y'**
  String get timeRange10y;

  /// Year to date time range option
  ///
  /// In en, this message translates to:
  /// **'YTD'**
  String get timeRangeYtd;

  /// All time range option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get timeRangeAll;

  /// Custom time range option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get timeRangeCustom;

  /// Filter from date label
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get filterDateFrom;

  /// Filter to date label
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get filterDateTo;

  /// Year label in date picker
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get filterYear;

  /// Month label in date picker
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get filterMonth;

  /// Apply button label
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Bitcoin mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Mode (Sats)'**
  String get bitcoinMode;

  /// Bitcoin mode toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'View inflation in satoshis'**
  String get bitcoinModeSubtitle;

  /// Label for sats-based inflation
  ///
  /// In en, this message translates to:
  /// **'Sats Inflation'**
  String get satsInflation;

  /// Fiat equivalent display
  ///
  /// In en, this message translates to:
  /// **'~{amount} {currency}'**
  String fiatEquivalent(String amount, String currency);

  /// Bottom sheet title for adding entry
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntryTitle;

  /// Option to select image from gallery
  ///
  /// In en, this message translates to:
  /// **'Select from Photos'**
  String get selectFromPhotos;

  /// Option to add entry manually
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get addManually;

  /// Toggle label for automatic database backup
  ///
  /// In en, this message translates to:
  /// **'Enable automatic backups'**
  String get autoBackupEnable;

  /// Description for automatic backup toggle
  ///
  /// In en, this message translates to:
  /// **'Keep local rolling backups and optionally copy them to an external folder.'**
  String get autoBackupEnableDesc;

  /// Action to trigger immediate auto backup
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get autoBackupBackupNow;

  /// Status when no automatic backup has run yet
  ///
  /// In en, this message translates to:
  /// **'No automatic backup yet'**
  String get autoBackupNoBackupYet;

  /// Status line showing timestamp of last automatic backup
  ///
  /// In en, this message translates to:
  /// **'Last backup: {dateTime}'**
  String autoBackupLastBackup(String dateTime);

  /// Snackbar after successful manual backup run
  ///
  /// In en, this message translates to:
  /// **'Backup completed successfully'**
  String get autoBackupManualSuccess;

  /// Snackbar when manual backup run fails
  ///
  /// In en, this message translates to:
  /// **'Backup could not be completed'**
  String get autoBackupManualFailure;

  /// Label for external backup directory chooser
  ///
  /// In en, this message translates to:
  /// **'External backup folder'**
  String get autoBackupExternalFolder;

  /// Placeholder when no external backup folder is configured
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get autoBackupExternalFolderNotSet;

  /// Guidance explaining why users should choose an external backup folder
  ///
  /// In en, this message translates to:
  /// **'Choose a folder outside the app container (iCloud Drive, Files, SD card, or network storage) so backups remain available after app uninstall.'**
  String get autoBackupExternalFolderHint;

  /// Snackbar after clearing configured external backup folder
  ///
  /// In en, this message translates to:
  /// **'External backup folder removed'**
  String get autoBackupFolderCleared;

  /// Dialog title for export format selection
  ///
  /// In en, this message translates to:
  /// **'Choose Export Format'**
  String get exportFormatTitle;

  /// Dialog message for export format selection
  ///
  /// In en, this message translates to:
  /// **'How would you like to export your data?'**
  String get exportFormatMessage;

  /// SQLite database export option
  ///
  /// In en, this message translates to:
  /// **'SQLite Database'**
  String get exportFormatSqlite;

  /// Description for SQLite export option
  ///
  /// In en, this message translates to:
  /// **'Full backup, can be restored to this app'**
  String get exportFormatSqliteDesc;

  /// CSV export option
  ///
  /// In en, this message translates to:
  /// **'CSV (Spreadsheet)'**
  String get exportFormatCsv;

  /// Description for CSV export option
  ///
  /// In en, this message translates to:
  /// **'Human-readable, works with Excel/Google Sheets'**
  String get exportFormatCsvDesc;

  /// JSON export option
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get exportFormatJson;

  /// Description for JSON export option
  ///
  /// In en, this message translates to:
  /// **'Full backup, machine-readable'**
  String get exportFormatJsonDesc;

  /// Settings section header for backup/restore
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackupRestore;

  /// List tile label for database export
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get settingsExportDatabase;

  /// List tile label for database import
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get settingsImportDatabase;

  /// List tile label for JSON export
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get settingsExportJson;

  /// Snackbar after successful database export
  ///
  /// In en, this message translates to:
  /// **'Database exported: {filename}'**
  String backupExportSuccess(String filename);

  /// Dialog title for import confirmation
  ///
  /// In en, this message translates to:
  /// **'Restore Database?'**
  String get backupImportConfirmTitle;

  /// Dialog message for import confirmation
  ///
  /// In en, this message translates to:
  /// **'This will REPLACE all existing products and settings. Continue?'**
  String get backupImportConfirmMessage;

  /// Snackbar after successful database import
  ///
  /// In en, this message translates to:
  /// **'Database successfully restored'**
  String get backupImportSuccess;

  /// Message shown after import requiring restart
  ///
  /// In en, this message translates to:
  /// **'Please restart the app to apply changes.'**
  String get backupRestartRequired;

  /// Error when importing invalid file
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get backupInvalidFile;

  /// Confirm button for restore
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreButton;

  /// Dialog title for duplicate entry detection
  ///
  /// In en, this message translates to:
  /// **'Similar Entry Found'**
  String get entryDuplicateTitle;

  /// Dialog body for duplicate entry detection
  ///
  /// In en, this message translates to:
  /// **'A similar purchase entry was found within the last 30 days with the same price:'**
  String get entryDuplicateMessage;

  /// Button to discard the new entry
  ///
  /// In en, this message translates to:
  /// **'Don\'t Save'**
  String get entryDuplicateDontSave;

  /// Button to save the entry despite duplicate
  ///
  /// In en, this message translates to:
  /// **'Save Anyway'**
  String get entryDuplicateSaveAnyway;

  /// Snackbar shown when an exact duplicate entry is automatically discarded
  ///
  /// In en, this message translates to:
  /// **'Entry discarded: an identical entry already exists for this store and price.'**
  String get entryExactDuplicateDiscarded;

  /// Notification title for price update reminder
  ///
  /// In en, this message translates to:
  /// **'Price Update Reminder'**
  String get priceUpdateNotificationTitle;

  /// Notification body for price update reminder
  ///
  /// In en, this message translates to:
  /// **'Some of your product prices may be outdated. Tap to check.'**
  String get priceUpdateNotificationBody;

  /// Popup title when opened from notification
  ///
  /// In en, this message translates to:
  /// **'Price Updates Available'**
  String get priceUpdatePopupTitle;

  /// Popup message showing count of products needing updates
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 product needs a price update} other {{count} products need price updates}}'**
  String priceUpdatePopupMessage(int count);

  /// Button to navigate to price updates screen
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get priceUpdatePopupAction;

  /// Button to dismiss the popup
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get priceUpdatePopupDismiss;

  /// Message when notification permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. Enable in Settings.'**
  String get priceUpdatePermissionDenied;

  /// AppBar title for the product detail screen
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailTitle;

  /// Delete action label for the product detail screen
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get productDetailDeleteProduct;

  /// Title shown when a product detail record no longer exists
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productDetailMissingTitle;

  /// Message shown when a product detail record no longer exists
  ///
  /// In en, this message translates to:
  /// **'This product may have been deleted already.'**
  String get productDetailMissingMessage;

  /// Label for the number of entries in product details
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get productDetailEntries;

  /// Label for the first purchase date in product details
  ///
  /// In en, this message translates to:
  /// **'First purchase'**
  String get productDetailFirstPurchase;

  /// Label for the latest purchase date in product details
  ///
  /// In en, this message translates to:
  /// **'Latest purchase'**
  String get productDetailLatestPurchase;

  /// Label for the product-specific inflation metric
  ///
  /// In en, this message translates to:
  /// **'Product inflation'**
  String get productDetailInflation;

  /// Helper text when product inflation uses a partial period baseline
  ///
  /// In en, this message translates to:
  /// **'Calculated from the first available in-range price.'**
  String get productDetailPartialPeriod;

  /// Title shown when a product has no purchase entries
  ///
  /// In en, this message translates to:
  /// **'No entries left'**
  String get productDetailNoEntriesTitle;

  /// Message shown when a product has no purchase entries
  ///
  /// In en, this message translates to:
  /// **'This product currently has no price history entries.'**
  String get productDetailNoEntriesMessage;

  /// Section title for the product detail history list
  ///
  /// In en, this message translates to:
  /// **'Price History'**
  String get productDetailPriceHistory;

  /// Snackbar shown when renaming a product to an existing name
  ///
  /// In en, this message translates to:
  /// **'Another product already uses this name.'**
  String get productDetailDuplicateNameMessage;

  /// Confirmation message when deleting a product and its entries
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all {count} linked entries?'**
  String productDetailDeleteProductMessage(String name, int count);

  /// Snackbar shown after deleting a product
  ///
  /// In en, this message translates to:
  /// **'Product deleted.'**
  String get productDetailDeleted;

  /// One month time range label for product detail chart
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get productDetailRange1m;

  /// Three month time range label for product detail chart
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get productDetailRange3m;

  /// Six month time range label for product detail chart
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get productDetailRange6m;

  /// Bottom sheet action to open product details from history
  ///
  /// In en, this message translates to:
  /// **'View Product'**
  String get productDetailViewAction;

  /// Snackbar shown when duplicate entries are auto-deleted on startup
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Removed 1 duplicate entry} other{Removed {count} duplicate entries}}'**
  String duplicateCleanupNotification(int count);

  /// Title for the quick add price dialog
  ///
  /// In en, this message translates to:
  /// **'Add Price'**
  String get quickAddPriceTitle;

  /// Title for store change confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Change Store?'**
  String get productDetailStoreChangeTitle;

  /// Message for store change confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This product has {count, plural, one{1 entry} other{{count} entries}}. Changing the store will update this product\'s default store for future quick-adds. Historical entries keep their original store. Continue?'**
  String productDetailStoreChangeConfirm(int count);

  /// SnackBar message after v12 migration
  ///
  /// In en, this message translates to:
  /// **'Products now have a fixed store — quick-add enabled!'**
  String get migrationV12Complete;

  /// Title for the AI consent dialog
  ///
  /// In en, this message translates to:
  /// **'AI Receipt Scanning'**
  String get aiConsentTitle;

  /// Explanation of what the AI scanner does and how user data is handled
  ///
  /// In en, this message translates to:
  /// **'The receipt scanner uses Google Gemini AI to extract product names, prices, and quantities from your receipt images.\n\nWhen you scan a receipt:\n• The image is sent to Google\'s servers for processing\n• Google processes the image to identify text and item details\n• Extracted data is returned to the app and stored locally on your device\n• Google may process the image in accordance with their privacy policy\n\nNo receipt images are stored by Google or shared with third parties beyond what is required for processing.\n\nBy accepting, you consent to sending your receipt images to Google Gemini for AI-powered text extraction.'**
  String get aiConsentBody;

  /// Button to accept AI consent and proceed to scanner
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get aiConsentAccept;

  /// Button to decline AI consent
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get aiConsentDecline;

  /// Message shown when user tries to use scanner without consent
  ///
  /// In en, this message translates to:
  /// **'AI consent is required to use the receipt scanner. You can add entries manually instead.'**
  String get aiConsentRequired;

  /// Title for the barcode section on the add/edit entry screen
  ///
  /// In en, this message translates to:
  /// **'Assign Barcode'**
  String get barcodeSectionTitle;

  /// Snackbar message when barcode is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Barcode copied'**
  String get barcodeCopied;

  /// Button text to assign a barcode
  ///
  /// In en, this message translates to:
  /// **'Assign Barcode'**
  String get barcodeAssign;

  /// Button text to change an existing barcode
  ///
  /// In en, this message translates to:
  /// **'Change Barcode'**
  String get barcodeChange;

  /// Button text to remove a barcode
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get barcodeRemove;

  /// Dialog title when barcode is already assigned to another product
  ///
  /// In en, this message translates to:
  /// **'Barcode Already Assigned'**
  String get barcodeConflictTitle;

  /// Dialog message when barcode conflict occurs
  ///
  /// In en, this message translates to:
  /// **'The barcode \"{barcode}\" is already assigned to \"{product}\".'**
  String barcodeConflictMessage(String barcode, String product);

  /// Dialog title for barcode removal confirmation
  ///
  /// In en, this message translates to:
  /// **'Remove Barcode?'**
  String get barcodeRemoveConfirmTitle;

  /// Dialog message for barcode removal confirmation
  ///
  /// In en, this message translates to:
  /// **'Remove the barcode from this product?'**
  String get barcodeRemoveConfirmMessage;

  /// Snackbar message when barcode is successfully assigned
  ///
  /// In en, this message translates to:
  /// **'Barcode assigned: {barcode}'**
  String barcodeAssigned(String barcode);

  /// Snackbar message when barcode is already assigned to the same product
  ///
  /// In en, this message translates to:
  /// **'This barcode is already assigned to this product.'**
  String get barcodeAlreadyAssigned;
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
      <String>['de', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
