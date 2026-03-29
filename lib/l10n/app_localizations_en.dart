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
  String get swipeToEdit => 'Swipe to edit';

  @override
  String get swipeToDelete => 'Swipe to delete';

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
  String get loadingChart => 'Loading chart';

  @override
  String get loadingStillTitle => 'Still loading...';

  @override
  String get loadingStillMessage =>
      'This might take a moment due to a slow connection.';

  @override
  String get emptyStateAnimationDescription => 'Empty state illustration';

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
  String get overviewTitle => 'Ø Yearly inflation';

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
  String get chartOverlayType => 'Chart Overlay';

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
  String get moneySupplyM2 => 'Money Supply (M2)';

  @override
  String get coreInflationSnb => 'Core Inflation';

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
  String get settingsPremiumSubtitle => 'AI receipt scanning';

  @override
  String get settingsFreeSubtitle => 'Unlock AI scanning';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsMetricSystem => 'Use Metric System';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeDesc => 'Use dark theme';

  @override
  String get settingsPriceUpdateReminder => 'Price Updates';

  @override
  String get settingsPriceUpdateReminderDesc => 'Get reminded to update prices';

  @override
  String get settingsReminder => 'Reminder';

  @override
  String get settingsReminderAfter => 'Reminder after';

  @override
  String get settingsShowPriceUpdateList => 'Show Price Update List';

  @override
  String get settingsPriceUpdateReminderDisabled =>
      'Enable to track price updates';

  @override
  String get priceUpdatesTitle => 'Update Prices';

  @override
  String get priceUpdatesNoPriceYet => 'No price yet';

  @override
  String get priceUpdatesSaved => 'Price saved';

  @override
  String get priceUpdatesAllCurrent => 'All prices are up to date – great!';

  @override
  String get priceUpdatesAllCurrentDesc =>
      'All your product prices are current.';

  @override
  String get settingsDataOptions => 'Data Options';

  @override
  String get settingsManageCategories => 'Manage Categories';

  @override
  String get settingsExportData => 'Export Data';

  @override
  String get settingsFactoryReset => 'Factory Reset';

  @override
  String get factoryResetConfirmTitle => 'Reset App?';

  @override
  String get factoryResetConfirmMessage =>
      'This will delete all your data including purchase history, categories, and settings. This action cannot be undone.';

  @override
  String get factoryResetButton => 'Reset';

  @override
  String get factoryResetCompleted => 'Factory reset completed';

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
  String get similarity => 'Similarity';

  @override
  String get scannedProduct => 'Scanned';

  @override
  String get existingProduct => 'Existing';

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

  @override
  String get categoryFoodGroceries => 'Food & Groceries';

  @override
  String get categoryRestaurantsDiningOut => 'Restaurants & Dining Out';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categoryTransportation => 'Transportation';

  @override
  String get categoryFuelEnergy => 'Fuel & Energy';

  @override
  String get categoryHousingRent => 'Housing & Rent';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryHealthcareMedical => 'Healthcare & Medical';

  @override
  String get categoryPersonalCareHygiene => 'Personal Care & Hygiene';

  @override
  String get categoryHouseholdSupplies => 'Household Supplies';

  @override
  String get categoryClothingApparel => 'Clothing & Apparel';

  @override
  String get categoryElectronicsTech => 'Electronics & Tech';

  @override
  String get scannerDropImage =>
      'Drop a JPG, JPEG, PNG, or WEBP receipt image.';

  @override
  String get scannerDragImage => 'Drag a receipt image here';

  @override
  String get scannerDropHere => 'Drop here';

  @override
  String get scannerTakePhoto => 'Take Photo';

  @override
  String get scannerChooseImage => 'Choose Image';

  @override
  String get scannerAnalyzingTitle => 'Analyzing Receipt';

  @override
  String get scannerAnalyzingMessage =>
      'The AI is extracting line items, totals, and suggested categories.';

  @override
  String get scannerReviewInstructions =>
      'Uncheck items you don\'t want to save. Tap names, prices, quantities, or categories to edit.';

  @override
  String get settingsMobileOnly => 'Mobile only';

  @override
  String get settingsDebugUnlock => 'Debug unlock';

  @override
  String get categoryInflationTitle => 'Inflation by Category';

  @override
  String get categoryDetailsTitle => 'Category Details';

  @override
  String get overviewNoPriceIncreases => 'No price increases detected yet!';

  @override
  String get overviewNoPriceDecreases => 'No price decreases detected yet.';

  @override
  String get duplicateProductFound => 'Similar Product Found';

  @override
  String duplicateProductMessage(String newName, String existing) {
    return '\"$newName\" looks similar to an existing product: \"$existing\". Link to the existing product or create a new one?';
  }

  @override
  String get categoryNoChartData => 'Not enough data to chart.';

  @override
  String get historyDeleteTitle => 'Delete Entry?';

  @override
  String get historyDeleteMessage =>
      'Are you sure you want to delete this purchase entry?';

  @override
  String get priceAlertEnableAlert => 'Enable alert';

  @override
  String get priceAlertNotifyMe =>
      'Notify me when the next logged price changes beyond this threshold.';

  @override
  String priceAlertThresholdLabel(String percent) {
    return 'Threshold: $percent%';
  }

  @override
  String get priceAlertSaveAlert => 'Save Alert';

  @override
  String get priceAlertLoadingAlerts => 'Loading Alerts';

  @override
  String get priceAlertLoadingAlertsMessage =>
      'Gathering tracked products and existing alert thresholds.';

  @override
  String get priceAlertLoadError => 'Could Not Load Alerts';

  @override
  String get priceAlertNoProducts => 'No Products To Track Yet';

  @override
  String get priceAlertNoProductsMessage =>
      'Add a few purchases first, then enable alerts for the products you want to watch.';

  @override
  String get priceAlertLoadingSettings => 'Loading Alert Settings';

  @override
  String get priceAlertLoadingSettingsMessage =>
      'Fetching saved thresholds for your tracked items.';

  @override
  String scannerSavedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items saved successfully!',
      one: '1 item saved successfully!',
    );
    return '$_temp0';
  }

  @override
  String scannerSavedItemsWithSkippedDuplicates(
      int savedCount, int skippedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      savedCount,
      locale: localeName,
      other: '$savedCount items saved. $skippedCount duplicates skipped.',
      one: '1 item saved. $skippedCount duplicates skipped.',
      zero: 'No new items saved. $skippedCount duplicates skipped.',
    );
    return '$_temp0';
  }

  @override
  String get categoryManagementEmpty => 'No categories found.';

  @override
  String categoryManagementError(String error) {
    return 'Error loading categories: $error';
  }

  @override
  String get unknownStore => 'Unknown Store';

  @override
  String get currencyChf => 'CHF';

  @override
  String get currencyEur => 'EUR';

  @override
  String get currencyUsd => 'USD';

  @override
  String get currencyGbp => 'GBP';

  @override
  String get scannerChooseFromGallery => 'Choose from Gallery';

  @override
  String scannerSaveError(String error) {
    return 'Error saving items: $error';
  }

  @override
  String get manual => 'Manual';

  @override
  String get barcode => 'Barcode';

  @override
  String get scannerOption => 'Scanner';

  @override
  String barcodeScanned(String barcode) {
    return 'Barcode: $barcode';
  }

  @override
  String get scannerPointAtBarcode => 'Point camera at barcode';

  @override
  String get unknownItem => 'Unknown Item';

  @override
  String get historyNoMatchingTitle => 'No Matching Entries';

  @override
  String get historyNoMatchingMessage =>
      'Try adjusting or clearing your filters.';

  @override
  String get historyNoEntriesMessage =>
      'Start by adding your first purchase entry.';

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Search';

  @override
  String get searchTitle => 'Search History';

  @override
  String get searchHint => 'Search by item name...';

  @override
  String get searchClear => 'Clear search';

  @override
  String get historyEditEntryTooltip => 'Edit entry';

  @override
  String errorLoadingCategories(String error) {
    return 'Error loading categories: $error';
  }

  @override
  String get settingsDebugPremiumSubtitle =>
      'Debug: Premium unlocked for testing.';

  @override
  String get settingsMobileOnlySubtitle =>
      'Subscriptions are only available on iOS and Android.';

  @override
  String get paywallTitle => 'Go Premium';

  @override
  String get paywallDebugTitle => 'Debug Mode';

  @override
  String get paywallDebugMessage =>
      'Premium features are unlocked for testing.';

  @override
  String get paywallBackToApp => 'Back to App';

  @override
  String get paywallMobileOnlyTitle => 'Mobile Only';

  @override
  String get paywallMobileOnlyMessage =>
      'Subscriptions are only available on iOS and Android. All features are unlocked on desktop.';

  @override
  String get paywallNoOffersTitle => 'No Offers Available';

  @override
  String get paywallNoOffersMessage =>
      'Could not load subscription offers. Please try again later.';

  @override
  String get paywallProductTitle => 'InflaBasket Premium';

  @override
  String get paywallFeatures =>
      'AI receipt scanning • Auto-categorization • Price alerts';

  @override
  String get paywallWelcome => 'Welcome to Premium!';

  @override
  String get paywallRestorePurchases => 'Restore Purchases';

  @override
  String get paywallLoadingOffersTitle => 'Loading Offers';

  @override
  String get paywallLoadingOffersMessage =>
      'Fetching available subscription plans.';

  @override
  String get paywallLoadOffersError => 'Could Not Load Offers';

  @override
  String categoryTotalSpend(String amount) {
    return 'Total: $amount';
  }

  @override
  String get comparisonSourceDetails => 'Source details';

  @override
  String get cpiSourceTitle => 'CPI Source';

  @override
  String get moneySupplySourceTitle => 'Money Supply Source';

  @override
  String get cpiSourceChfDescription =>
      'Swiss Federal Statistical Office (FSO) — monthly CPI index for Switzerland.';

  @override
  String get cpiSourceEurDescription =>
      'Eurostat — harmonised index of consumer prices (HICP) for the Euro area.';

  @override
  String get cpiSourceUnavailableDescription =>
      'No CPI data source is available for the selected currency.';

  @override
  String get moneySupplySourceChfDescription =>
      'Swiss National Bank (SNB) — M2 money supply for Switzerland.';

  @override
  String get moneySupplySourceEurDescription =>
      'European Central Bank (ECB) — M2 money supply for the Euro area.';

  @override
  String get moneySupplySourceUsdDescription =>
      'Federal Reserve (Fed) — M2 money supply for the United States.';

  @override
  String get moneySupplySourceGbpDescription =>
      'Bank of England (BoE) — M2 money supply for the United Kingdom.';

  @override
  String get moneySupplySourceUnavailableDescription =>
      'No money supply data source is available for the selected currency.';

  @override
  String priceAlertLatestPrice(String price) {
    return 'Latest price: $price';
  }

  @override
  String priceAlertAlertAt(String percent) {
    return 'Alert at $percent% change';
  }

  @override
  String get priceAlertDisabledStatus => 'Alert disabled';

  @override
  String priceAlertSaved(String product) {
    return 'Alert saved for $product.';
  }

  @override
  String priceAlertDisabled(String product) {
    return 'Alert disabled for $product.';
  }

  @override
  String get priceAlertLoadSettingsError => 'Could Not Load Alert Settings';

  @override
  String get timeRangeLabel => 'Time Range';

  @override
  String get timeRange6m => '6M';

  @override
  String get timeRange1y => '1Y';

  @override
  String get timeRange2y => '2Y';

  @override
  String get timeRange3y => '3Y';

  @override
  String get timeRange5y => '5Y';

  @override
  String get timeRange10y => '10Y';

  @override
  String get timeRangeYtd => 'YTD';

  @override
  String get timeRangeAll => 'All';

  @override
  String get timeRangeCustom => 'Custom';

  @override
  String get filterDateFrom => 'From';

  @override
  String get filterDateTo => 'To';

  @override
  String get filterYear => 'Year';

  @override
  String get filterMonth => 'Month';

  @override
  String get apply => 'Apply';

  @override
  String get bitcoinMode => 'Bitcoin Mode (Sats)';

  @override
  String get bitcoinModeSubtitle => 'View inflation in satoshis';

  @override
  String get satsInflation => 'Sats Inflation';

  @override
  String fiatEquivalent(String amount, String currency) {
    return '~$amount $currency';
  }

  @override
  String get addEntryTitle => 'Add Entry';

  @override
  String get selectFromPhotos => 'Select from Photos';

  @override
  String get addManually => 'Add Manually';

  @override
  String get premiumFeature => 'Premium feature';

  @override
  String get notAvailableDesktop => 'Not available on desktop';

  @override
  String get exportFormatTitle => 'Choose Export Format';

  @override
  String get exportFormatMessage => 'How would you like to export your data?';

  @override
  String get exportFormatSqlite => 'SQLite Database';

  @override
  String get exportFormatSqliteDesc =>
      'Full backup, can be restored to this app';

  @override
  String get exportFormatCsv => 'CSV (Spreadsheet)';

  @override
  String get exportFormatCsvDesc =>
      'Human-readable, works with Excel/Google Sheets';

  @override
  String get exportFormatJson => 'JSON';

  @override
  String get exportFormatJsonDesc => 'Full backup, machine-readable';

  @override
  String get settingsBackupRestore => 'Backup & Restore';

  @override
  String get settingsExportDatabase => 'Export Database';

  @override
  String get settingsImportDatabase => 'Import Database';

  @override
  String get settingsExportJson => 'Export as JSON';

  @override
  String backupExportSuccess(String filename) {
    return 'Database exported: $filename';
  }

  @override
  String get backupImportConfirmTitle => 'Restore Database?';

  @override
  String get backupImportConfirmMessage =>
      'This will REPLACE all existing products and settings. Continue?';

  @override
  String get backupImportSuccess => 'Database successfully restored';

  @override
  String get backupRestartRequired =>
      'Please restart the app to apply changes.';

  @override
  String get backupInvalidFile => 'Invalid backup file';

  @override
  String get backupRestoreButton => 'Restore';

  @override
  String get entryDuplicateTitle => 'Similar Entry Found';

  @override
  String get entryDuplicateMessage =>
      'A similar purchase entry was found within the last 30 days with the same price:';

  @override
  String get entryDuplicateDontSave => 'Don\'t Save';

  @override
  String get entryDuplicateSaveAnyway => 'Save Anyway';

  @override
  String get entryExactDuplicateDiscarded =>
      'Entry discarded: an identical entry already exists for this store and price.';

  @override
  String get priceUpdateNotificationTitle => 'Price Update Reminder';

  @override
  String get priceUpdateNotificationBody =>
      'Some of your product prices may be outdated. Tap to check.';

  @override
  String get priceUpdatePopupTitle => 'Price Updates Available';

  @override
  String priceUpdatePopupMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products need price updates',
      one: '1 product needs a price update',
    );
    return '$_temp0';
  }

  @override
  String get priceUpdatePopupAction => 'Update Now';

  @override
  String get priceUpdatePopupDismiss => 'Later';

  @override
  String get priceUpdatePermissionDenied =>
      'Notification permission denied. Enable in Settings.';

  @override
  String get productDetailTitle => 'Product Details';

  @override
  String get productDetailDeleteProduct => 'Delete Product';

  @override
  String get productDetailMissingTitle => 'Product not found';

  @override
  String get productDetailMissingMessage =>
      'This product may have been deleted already.';

  @override
  String get productDetailEntries => 'Entries';

  @override
  String get productDetailFirstPurchase => 'First purchase';

  @override
  String get productDetailLatestPurchase => 'Latest purchase';

  @override
  String get productDetailInflation => 'Product inflation';

  @override
  String get productDetailPartialPeriod =>
      'Calculated from the first available in-range price.';

  @override
  String get productDetailNoEntriesTitle => 'No entries left';

  @override
  String get productDetailNoEntriesMessage =>
      'This product currently has no price history entries.';

  @override
  String get productDetailPriceHistory => 'Price History';

  @override
  String get productDetailDuplicateNameMessage =>
      'Another product already uses this name.';

  @override
  String productDetailDeleteProductMessage(String name, int count) {
    return 'Delete \"$name\" and all $count linked entries?';
  }

  @override
  String get productDetailDeleted => 'Product deleted.';

  @override
  String get productDetailRange1m => '1M';

  @override
  String get productDetailRange3m => '3M';

  @override
  String get productDetailRange6m => '6M';

  @override
  String get productDetailViewAction => 'View Product';

  @override
  String duplicateCleanupNotification(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count duplicate entries',
      one: 'Removed 1 duplicate entry',
    );
    return '$_temp0';
  }

  @override
  String get quickAddPriceTitle => 'Add Price';

  @override
  String get productDetailStoreChangeTitle => 'Change Store?';

  @override
  String productDetailStoreChangeConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'This product has $_temp0. Changing the store will update this product\'s default store for future quick-adds. Historical entries keep their original store. Continue?';
  }

  @override
  String get migrationV12Complete =>
      'Products now have a fixed store — quick-add enabled!';

  @override
  String get aiConsentTitle => 'AI Receipt Scanning';

  @override
  String get aiConsentBody =>
      'The receipt scanner uses Google Gemini AI to extract product names, prices, and quantities from your receipt images.\n\nWhen you scan a receipt:\n• The image is sent to Google\'s servers for processing\n• Google processes the image to identify text and item details\n• Extracted data is returned to the app and stored locally on your device\n• Google may process the image in accordance with their privacy policy\n\nNo receipt images are stored by Google or shared with third parties beyond what is required for processing.\n\nBy accepting, you consent to sending your receipt images to Google Gemini for AI-powered text extraction.';

  @override
  String get aiConsentAccept => 'Accept & Continue';

  @override
  String get aiConsentDecline => 'Decline';

  @override
  String get aiConsentRequired =>
      'AI consent is required to use the receipt scanner. You can add entries manually instead.';

  @override
  String get barcodeSectionTitle => 'Assign Barcode';

  @override
  String get barcodeCopied => 'Barcode copied';

  @override
  String get barcodeAssign => 'Assign Barcode';

  @override
  String get barcodeChange => 'Change Barcode';

  @override
  String get barcodeRemove => 'Remove';

  @override
  String get barcodeConflictTitle => 'Barcode Already Assigned';

  @override
  String barcodeConflictMessage(String barcode, String product) {
    return 'The barcode \"$barcode\" is already assigned to \"$product\".';
  }

  @override
  String get barcodeRemoveConfirmTitle => 'Remove Barcode?';

  @override
  String get barcodeRemoveConfirmMessage =>
      'Remove the barcode from this product?';

  @override
  String barcodeAssigned(String barcode) {
    return 'Barcode assigned: $barcode';
  }

  @override
  String get barcodeAlreadyAssigned =>
      'This barcode is already assigned to this product.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStartTracking => 'Start Tracking';

  @override
  String get onboardingWelcomeTitle => 'Track Your Grocery Inflation';

  @override
  String get onboardingWelcomeSubtitle =>
      'Log your purchases and see how prices change over time.';

  @override
  String get onboardingModesTitle => 'View Prices Your Way';

  @override
  String get onboardingModesSubtitle =>
      'Switch between fiat currency and satoshis to see the true cost in sound money.';

  @override
  String get onboardingModesFiatTitle => 'Fiat Mode';

  @override
  String get onboardingModesFiatDesc =>
      'Track inflation in your local currency.';

  @override
  String get onboardingModesBitcoinTitle => 'Bitcoin Mode';

  @override
  String get onboardingModesBitcoinDesc =>
      'See prices in satoshis — the true cost in sound money.';

  @override
  String get onboardingStartTitle => 'Ready to Track Prices';

  @override
  String get onboardingStartSubtitle =>
      'Add your first purchase to start tracking. Scan with AI or enter manually.';

  @override
  String get privacyPolicySubtitle => 'Last updated: March 2026';

  @override
  String get privacyPolicySection1Title => 'Controller';

  @override
  String get privacyPolicySection1Body =>
      'InflaBasket is operated as a personal project. For questions regarding this privacy policy, please contact us via the information provided below.';

  @override
  String get privacyPolicySection2Title => 'Data Collected & Purpose';

  @override
  String get privacyPolicySection2Body =>
      'InflaBasket collects only the data you manually enter:\n\n• Product names, prices, quantities, and purchase dates\n• Store names and categories\n• Optional notes you add to entries\n\nAll data is entered by you and used solely to calculate and display price trends and inflation within the app. No data is collected automatically.';

  @override
  String get privacyPolicySection3Title => 'Data Storage & Retention';

  @override
  String get privacyPolicySection3Body =>
      'All your data is stored locally on your device in an SQLite database. No data is transmitted to external servers.\n\nYou may optionally export your data as a backup file (SQLite, CSV, or JSON). These exports are saved to locations you choose.\n\nData is retained until you delete it or perform a factory reset within the app.';

  @override
  String get privacyPolicySection4Title => 'Data Sharing';

  @override
  String get privacyPolicySection4Body =>
      'InflaBasket does not share your personal data with any third parties.\n\nIf you use the AI receipt scanner (Premium feature), receipt images are sent to Google Gemini for text extraction. No images are stored by Google or shared beyond what is required for processing. You must explicitly consent to this before using the scanner.\n\nSee the AI consent dialog for full details on how receipt images are handled.';

  @override
  String get privacyPolicySection5Title => 'Your Rights (GDPR)';

  @override
  String get privacyPolicySection5Body =>
      'Under the General Data Protection Regulation (GDPR), you have the right to:\n\n• Access your data – All data is stored locally and accessible within the app\n• Rectification – Edit any entry directly in the app\n• Deletion – Delete individual entries, categories, or perform a factory reset\n• Data portability – Export your data in CSV, JSON, or SQLite format\n• Restriction & objection – Data processing is minimal and local\n\nSince all data is stored locally on your device, you have full control over your data at all times.';

  @override
  String get privacyPolicySection6Title => 'Contact';

  @override
  String get privacyPolicySection6Body =>
      'For privacy-related inquiries, please open an issue on our GitHub repository or contact us through the app store listing.';

  @override
  String get termsSubtitle => 'Last updated: March 2026';

  @override
  String get termsSection1Title => 'Acceptance of Terms';

  @override
  String get termsSection1Body =>
      'By downloading, installing, or using InflaBasket, you agree to be bound by these Terms of Service. If you do not agree to these terms, you must not use the application.\n\nThese terms constitute a legally binding agreement between you and InflaBasket regarding your use of the application and its services.';

  @override
  String get termsSection2Title => 'Use of the Service';

  @override
  String get termsSection2Body =>
      'InflaBasket is provided as a personal productivity tool for tracking grocery prices and calculating inflation. You agree to:\n\n• Use the application only for lawful purposes\n• Not reverse-engineer, decompile, or disassemble the application\n• Not use the application to transmit malicious code or interfere with its operation\n• Not attempt to gain unauthorized access to any part of the service\n\nThe application is provided \"as is\" and \"as available\" without warranties of any kind.';

  @override
  String get termsSection3Title => 'User Accounts & Data';

  @override
  String get termsSection3Body =>
      'InflaBasket does not require user accounts. All data is stored locally on your device.\n\nYou are solely responsible for:\n\n• The accuracy of data you enter into the application\n• Maintaining backups of your data (via the export feature)\n• Any consequences arising from data loss\n\nWe are not responsible for data loss resulting from device failure, app uninstallation, or user error.';

  @override
  String get termsSection4Title => 'Intellectual Property';

  @override
  String get termsSection4Body =>
      'InflaBasket and its original content, features, and functionality are owned by InflaBasket and are protected by copyright, trademark, and other intellectual property laws.\n\nYou may not reproduce, distribute, modify, or create derivative works from any part of the application without prior written consent.';

  @override
  String get termsSection5Title => 'Limitation of Liability';

  @override
  String get termsSection5Body =>
      'To the maximum extent permitted by applicable law, InflaBasket shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your use of or inability to use the application.\n\nThis includes, but is not limited to:\n\n• Loss of data or profits\n• Business interruption\n• Personal injury or property damage\n• Any other damages resulting from the use of the application\n\nThe total liability of InflaBasket shall not exceed the amount you paid for the application, if any.';

  @override
  String get termsSection6Title => 'Changes to Terms';

  @override
  String get termsSection6Body =>
      'We reserve the right to modify these Terms of Service at any time. We will notify users of material changes by updating the \"Last updated\" date at the top of this document.\n\nYour continued use of the application after any changes constitutes acceptance of the updated terms. If you disagree with the revised terms, you must stop using the application.\n\nFor questions about these terms, please contact us through the app store listing or by opening an issue on our GitHub repository.';

  @override
  String get settingsAutoSaveBackup => 'Auto-Save Backup';

  @override
  String get autoSaveEnable => 'Enable Auto-Save';

  @override
  String get autoSaveStorageType => 'Storage Location';

  @override
  String get autoSaveStorageLocal => 'Local';

  @override
  String get autoSaveStorageCloud => 'Cloud';

  @override
  String get autoSaveLastBackup => 'Last backup';

  @override
  String get autoSaveBackupNow => 'Backup Now';

  @override
  String get autoSaveSelectFolder => 'Select Folder';

  @override
  String get autoSavePathNotSet => 'No folder selected';

  @override
  String get autoSaveSuccess => 'Backup saved successfully';

  @override
  String autoSaveError(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get autoSaveEnablePrompt =>
      'Enable auto-save to select storage location';

  @override
  String get autoSaveManualBackup => 'Manual Backup';

  @override
  String get autoSaveNoBackup => 'No backup yet';
}
