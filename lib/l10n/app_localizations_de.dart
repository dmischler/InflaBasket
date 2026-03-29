// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'InflaBasket';

  @override
  String get navOverview => 'Übersicht';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get navCategories => 'Kategorien';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get addEntry => 'Eintrag hinzufügen';

  @override
  String get editEntry => 'Eintrag bearbeiten';

  @override
  String get swipeToEdit => 'Wischen zum Bearbeiten';

  @override
  String get swipeToDelete => 'Wischen zum Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get close => 'Schliessen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get loading => 'Lädt…';

  @override
  String get loadingChart => 'Diagramm wird geladen';

  @override
  String get loadingStillTitle => 'Lädt immer noch...';

  @override
  String get loadingStillMessage =>
      'Das kann wegen einer langsamen Verbindung etwas länger dauern.';

  @override
  String get emptyStateAnimationDescription => 'Leere-Zustands-Illustration';

  @override
  String get errorGeneric =>
      'Ein Fehler ist aufgetreten. Bitte versuche es erneut.';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich';

  @override
  String get fieldInvalidNumber => 'Bitte eine gültige Zahl eingeben';

  @override
  String get fieldPositiveNumber => 'Muss grösser als null sein';

  @override
  String get product => 'Produkt';

  @override
  String get productHint => 'z.B. Vollmilch';

  @override
  String get category => 'Kategorie';

  @override
  String get store => 'Geschäft';

  @override
  String get storeHint => 'z.B. Migros';

  @override
  String get price => 'Preis';

  @override
  String get quantity => 'Menge';

  @override
  String get unit => 'Einheit';

  @override
  String get date => 'Datum';

  @override
  String get notes => 'Notizen';

  @override
  String get notesHint => 'Optionale Notizen…';

  @override
  String get scanReceipt => 'Quittung scannen (Premium)';

  @override
  String get scanBarcode => 'Barcode scannen';

  @override
  String get barcodeNotFound => 'Kein Produkt für diesen Barcode gefunden.';

  @override
  String get barcodeError =>
      'Barcode konnte nicht gescannt werden. Bitte versuche es erneut.';

  @override
  String get entrySaved => 'Eintrag erfolgreich gespeichert.';

  @override
  String get entryDeleted => 'Eintrag gelöscht.';

  @override
  String entrySaveError(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String get deleteEntryConfirm => 'Diesen Eintrag löschen?';

  @override
  String get deleteEntryMessage =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get noEntriesYet => 'Noch keine Einträge.';

  @override
  String get noEntriesFiltered =>
      'Keine Einträge entsprechen den aktuellen Filtern.';

  @override
  String get filterTitle => 'Verlauf filtern';

  @override
  String get filterDateRange => 'Zeitraum';

  @override
  String get filterLast30Days => 'Letzte 30 Tage';

  @override
  String get filterLast6Months => 'Letzte 6 Monate';

  @override
  String get filterAllTime => 'Gesamter Zeitraum';

  @override
  String get filterCategory => 'Kategorie';

  @override
  String get filterAllCategories => 'Alle Kategorien';

  @override
  String get applyFilters => 'Anwenden';

  @override
  String get clearFilters => 'Löschen';

  @override
  String get overviewTitle => 'Ø Jahresinflation';

  @override
  String get overviewBasketIndex => 'Warenkorb-Index';

  @override
  String get overviewTopInflators => 'Grösste Preisanstiege';

  @override
  String get overviewTopDeflators => 'Grösste Preisrückgänge';

  @override
  String get overviewNoData =>
      'Erfasse mindestens zwei Käufe des gleichen Produkts, um die Inflation anzuzeigen.';

  @override
  String get showNationalAverage => 'vs. Nationalem Durchschnitt';

  @override
  String get showComparisonOverlay => 'Vergleichen mit';

  @override
  String get chartOverlayType => 'Diagramm-Overlay';

  @override
  String get cpiUnavailable =>
      'Nationale KPI-Daten für die gewählte Währung nicht verfügbar.';

  @override
  String get cpiLoadError =>
      'Nationale KPI-Daten konnten nicht geladen werden.';

  @override
  String get comparisonLoadError =>
      'Vergleichsdaten konnten nicht geladen werden.';

  @override
  String get yourInflation => 'Deine Inflation';

  @override
  String get nationalCpi => 'Nationaler KPI';

  @override
  String get moneySupplyM2 => 'Geldmenge (M2)';

  @override
  String get coreInflationSnb => 'Kerninflation';

  @override
  String get categoriesTitle => 'Kategorienübersicht';

  @override
  String get categoryNoCategoryData => 'Noch keine Kategoriedaten verfügbar.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSubscription => 'Abonnement';

  @override
  String get settingsPremiumActive => 'Premium aktiv';

  @override
  String get settingsFreeTier => 'Kostenlos';

  @override
  String get settingsPremiumSubtitle => 'KI-Belegscannen';

  @override
  String get settingsFreeSubtitle => 'KI-Scannen freischalten';

  @override
  String get settingsRestore => 'Wiederherstellen';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsMetricSystem => 'Metrisches System verwenden';

  @override
  String get settingsDarkMode => 'Dunkler Modus';

  @override
  String get settingsDarkModeDesc => 'Dunkles Design verwenden';

  @override
  String get settingsPriceUpdateReminder => 'Preis-Updates';

  @override
  String get settingsPriceUpdateReminderDesc => 'Erinnerung zum Aktualisieren';

  @override
  String get settingsReminder => 'Erinnerung';

  @override
  String get settingsReminderAfter => 'Erinnerung nach';

  @override
  String get settingsShowPriceUpdateList => 'Preis-Update-Liste anzeigen';

  @override
  String get settingsPriceUpdateReminderDisabled =>
      'Aktivieren, um Preis-Updates zu verfolgen';

  @override
  String get priceUpdatesTitle => 'Preise aktualisieren';

  @override
  String get priceUpdatesNoPriceYet => 'Noch kein Preis';

  @override
  String get priceUpdatesSaved => 'Preis gespeichert';

  @override
  String get priceUpdatesAllCurrent => 'Alle Preise sind aktuell – super!';

  @override
  String get priceUpdatesAllCurrentDesc =>
      'Alle Ihre Produktpreise sind auf dem neuesten Stand.';

  @override
  String get settingsDataOptions => 'Datenoptionen';

  @override
  String get settingsManageCategories => 'Kategorien verwalten';

  @override
  String get settingsExportData => 'Daten exportieren';

  @override
  String get settingsFactoryReset => 'Werkseinstellungen';

  @override
  String get factoryResetConfirmTitle => 'App zurücksetzen?';

  @override
  String get factoryResetConfirmMessage =>
      'Alle Ihre Daten werden gelöscht, einschließlich Kaufhistorie, Kategorien und Einstellungen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get factoryResetButton => 'Zurücksetzen';

  @override
  String get factoryResetCompleted => 'Auf Werkseinstellung zurückgesetzt';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String get settingsComingSoon => 'Demnächst verfügbar';

  @override
  String get categoryManagementTitle => 'Kategorien verwalten';

  @override
  String get categoryManagementCustomBadge => 'Benutzerdefiniert';

  @override
  String get categoryManagementDefaultBadge => 'Standard';

  @override
  String get addCategoryTitle => 'Kategorie hinzufügen';

  @override
  String get addCategoryHint => 'Kategoriename';

  @override
  String deleteCategoryConfirm(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String get deleteCategoryHasProducts =>
      'Kann nicht gelöscht werden: Diese Kategorie hat bestehende Produkte.';

  @override
  String get duplicateDetectionTitle => 'Ähnliches Produkt gefunden';

  @override
  String duplicateDetectionMessage(String newName, String existing) {
    return '\"$newName\" sieht ähnlich aus wie ein bestehendes Produkt: \"$existing\". Mit bestehendem Produkt verknüpfen oder neues erstellen?';
  }

  @override
  String get duplicateDetectionLinkExisting => 'Mit Bestehendem verknüpfen';

  @override
  String get duplicateDetectionCreateNew => 'Neu erstellen';

  @override
  String get similarity => 'Ähnlichkeit';

  @override
  String get scannedProduct => 'Gescannt';

  @override
  String get existingProduct => 'Vorhanden';

  @override
  String get priceAlerts => 'Preisalarme';

  @override
  String priceAlertTitle(String product) {
    return 'Preisalarm: $product';
  }

  @override
  String priceAlertBody(
      String product, String percent, String oldPrice, String newPrice) {
    return '$product ist $percent% teurer als beim letzten Kauf ($oldPrice → $newPrice).';
  }

  @override
  String priceAlertThreshold(int percent) {
    return 'Alarmgrenze: $percent%';
  }

  @override
  String get scannerTitle => 'Quittung scannen';

  @override
  String get scannerSelectCamera => 'Kamera';

  @override
  String get scannerSelectGallery => 'Galerie';

  @override
  String get scannerProcessing => 'Quittung wird verarbeitet…';

  @override
  String get scannerError =>
      'Quittung konnte nicht gelesen werden. Bitte versuche es erneut.';

  @override
  String get scannerReviewTitle => 'Artikel prüfen';

  @override
  String scannerSaveItems(int count) {
    return '$count Artikel speichern';
  }

  @override
  String get scannerSelectAll => 'Alle auswählen';

  @override
  String get scannerDeselectAll => 'Alle abwählen';

  @override
  String get categoryFoodGroceries => 'Lebensmittel & Einkäufe';

  @override
  String get categoryRestaurantsDiningOut => 'Restaurants & Auswärts essen';

  @override
  String get categoryBeverages => 'Getränke';

  @override
  String get categoryTransportation => 'Transport';

  @override
  String get categoryFuelEnergy => 'Brennstoff & Energie';

  @override
  String get categoryHousingRent => 'Wohnen & Miete';

  @override
  String get categoryUtilities => 'Nebenkosten';

  @override
  String get categoryHealthcareMedical => 'Gesundheit & Medizin';

  @override
  String get categoryPersonalCareHygiene => 'Körperpflege & Hygiene';

  @override
  String get categoryHouseholdSupplies => 'Haushaltsartikel';

  @override
  String get categoryClothingApparel => 'Kleidung & Mode';

  @override
  String get categoryElectronicsTech => 'Elektronik & Technik';

  @override
  String get scannerDropImage =>
      'JPG, JPEG, PNG oder WEBP Bild hierher ziehen.';

  @override
  String get scannerDragImage => 'Belegbild hier ablegen';

  @override
  String get scannerDropHere => 'Hier ablegen';

  @override
  String get scannerTakePhoto => 'Foto aufnehmen';

  @override
  String get scannerChooseImage => 'Bild auswählen';

  @override
  String get scannerAnalyzingTitle => 'Quittung wird analysiert';

  @override
  String get scannerAnalyzingMessage =>
      'Die KI extrahiert Artikel, Summen und vorgeschlagene Kategorien.';

  @override
  String get scannerReviewInstructions =>
      'Abwählen was nicht gespeichert werden soll. Namen, Preise, Mengen oder Kategorien antippen zum Bearbeiten.';

  @override
  String get settingsMobileOnly => 'Nur Mobile';

  @override
  String get settingsDebugUnlock => 'Debug Entsperrung';

  @override
  String get categoryInflationTitle => 'Inflation nach Kategorie';

  @override
  String get categoryDetailsTitle => 'Kategoriedetails';

  @override
  String get overviewNoPriceIncreases => 'Noch keine Preiserhöhungen erkannt!';

  @override
  String get overviewNoPriceDecreases => 'Noch keine Preisreduktionen erkannt.';

  @override
  String get duplicateProductFound => 'Ähnliches Produkt gefunden';

  @override
  String duplicateProductMessage(String newName, String existing) {
    return '\"$newName\" sieht ähnlich aus wie ein bestehendes Produkt: \"$existing\". Mit bestehendem Produkt verknüpfen oder neues erstellen?';
  }

  @override
  String get categoryNoChartData => 'Nicht genügend Daten für Diagramm.';

  @override
  String get historyDeleteTitle => 'Eintrag löschen?';

  @override
  String get historyDeleteMessage =>
      'Bist du sicher, dass du diesen Kauf löschen möchtest?';

  @override
  String get priceAlertEnableAlert => 'Alarm aktivieren';

  @override
  String get priceAlertNotifyMe =>
      'Benachrichtige mich, wenn sich der nächste erfasste Preis über diesem Schwellenwert ändert.';

  @override
  String priceAlertThresholdLabel(String percent) {
    return 'Schwelle: $percent%';
  }

  @override
  String get priceAlertSaveAlert => 'Alarm speichern';

  @override
  String get priceAlertLoadingAlerts => 'Alarme werden geladen';

  @override
  String get priceAlertLoadingAlertsMessage =>
      'Verfolge Produkte und bestehende Alarmschwellen werden erfasst.';

  @override
  String get priceAlertLoadError => 'Alarme konnten nicht geladen werden';

  @override
  String get priceAlertNoProducts => 'Noch keine Produkte zum Verfolgen';

  @override
  String get priceAlertNoProductsMessage =>
      'Füge zuerst einige Käufe hinzu, dann kannst du Alarme für Produkte aktivieren.';

  @override
  String get priceAlertLoadingSettings => 'Alarm-Einstellungen werden geladen';

  @override
  String get priceAlertLoadingSettingsMessage =>
      'Gespeicherte Schwellenwerte für deine verfolgten Produkte werden abgerufen.';

  @override
  String scannerSavedItems(int count) {
    return '$count Artikel erfolgreich gespeichert!';
  }

  @override
  String scannerSavedItemsWithSkippedDuplicates(
      int savedCount, int skippedCount) {
    return '$savedCount Artikel gespeichert, $skippedCount Duplikate übersprungen.';
  }

  @override
  String get categoryManagementEmpty => 'Keine Kategorien gefunden.';

  @override
  String categoryManagementError(String error) {
    return 'Fehler beim Laden der Kategorien: $error';
  }

  @override
  String get unknownStore => 'Unbekanntes Geschäft';

  @override
  String get currencyChf => 'CHF';

  @override
  String get currencyEur => 'EUR';

  @override
  String get currencyUsd => 'USD';

  @override
  String get currencyGbp => 'GBP';

  @override
  String get scannerChooseFromGallery => 'Aus Galerie wählen';

  @override
  String scannerSaveError(String error) {
    return 'Fehler beim Speichern der Artikel: $error';
  }

  @override
  String get manual => 'Manuell';

  @override
  String get barcode => 'Barcode';

  @override
  String get scannerOption => 'Scanner';

  @override
  String barcodeScanned(String barcode) {
    return 'Barcode: $barcode';
  }

  @override
  String get scannerPointAtBarcode => 'Kamera auf Barcode richten';

  @override
  String get unknownItem => 'Unbekannter Artikel';

  @override
  String get historyNoMatchingTitle => 'Keine passenden Einträge';

  @override
  String get historyNoMatchingMessage =>
      'Versuche, deine Filter anzupassen oder zu löschen.';

  @override
  String get historyNoEntriesMessage =>
      'Füge deinen ersten Kauf hinzu, um zu beginnen.';

  @override
  String get filter => 'Filtern';

  @override
  String get search => 'Suchen';

  @override
  String get searchTitle => 'Verlauf durchsuchen';

  @override
  String get searchHint => 'Nach Artikelname suchen...';

  @override
  String get searchClear => 'Suche löschen';

  @override
  String get historyEditEntryTooltip => 'Eintrag bearbeiten';

  @override
  String errorLoadingCategories(String error) {
    return 'Fehler beim Laden der Kategorien: $error';
  }

  @override
  String get settingsDebugPremiumSubtitle =>
      'Debug: Premium für Tests freigeschaltet.';

  @override
  String get settingsMobileOnlySubtitle =>
      'Abonnements sind nur unter iOS und Android verfügbar.';

  @override
  String get paywallTitle => 'Premium werden';

  @override
  String get paywallDebugTitle => 'Debug-Modus';

  @override
  String get paywallDebugMessage =>
      'Premium-Funktionen sind für Tests freigeschaltet.';

  @override
  String get paywallBackToApp => 'Zurück zur App';

  @override
  String get paywallMobileOnlyTitle => 'Nur Mobile';

  @override
  String get paywallMobileOnlyMessage =>
      'Abonnements sind nur unter iOS und Android verfügbar. Auf dem Desktop sind alle Funktionen freigeschaltet.';

  @override
  String get paywallNoOffersTitle => 'Keine Angebote verfügbar';

  @override
  String get paywallNoOffersMessage =>
      'Abonnement-Angebote konnten nicht geladen werden. Bitte später erneut versuchen.';

  @override
  String get paywallProductTitle => 'InflaBasket Premium';

  @override
  String get paywallFeatures =>
      'KI-Belegscannen • Automatische Kategorisierung • Preisalarme';

  @override
  String get paywallWelcome => 'Willkommen bei Premium!';

  @override
  String get paywallRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get paywallLoadingOffersTitle => 'Angebote werden geladen';

  @override
  String get paywallLoadingOffersMessage =>
      'Verfügbare Abonnements werden abgerufen.';

  @override
  String get paywallLoadOffersError => 'Angebote konnten nicht geladen werden';

  @override
  String categoryTotalSpend(String amount) {
    return 'Gesamt: $amount';
  }

  @override
  String get comparisonSourceDetails => 'Quellendetails';

  @override
  String get cpiSourceTitle => 'KPI-Quelle';

  @override
  String get moneySupplySourceTitle => 'Geldmengen-Quelle';

  @override
  String get cpiSourceChfDescription =>
      'Bundesamt für Statistik (BFS) — monatlicher Landesindex der Konsumentenpreise (LIK).';

  @override
  String get cpiSourceEurDescription =>
      'Eurostat — Harmonisierter Verbraucherpreisindex (HVPI) für das Euro-Gebiet.';

  @override
  String get cpiSourceUnavailableDescription =>
      'Für die gewählte Währung ist keine KPI-Datenquelle verfügbar.';

  @override
  String get moneySupplySourceChfDescription =>
      'Schweizerische Nationalbank (SNB) — M2-Geldmenge für die Schweiz.';

  @override
  String get moneySupplySourceEurDescription =>
      'Europäische Zentralbank (EZB) — M2-Geldmenge für das Euro-Gebiet.';

  @override
  String get moneySupplySourceUsdDescription =>
      'Federal Reserve (Fed) — M2-Geldmenge für die Vereinigten Staaten.';

  @override
  String get moneySupplySourceGbpDescription =>
      'Bank of England (BoE) — M2-Geldmenge für das Vereinigte Königreich.';

  @override
  String get moneySupplySourceUnavailableDescription =>
      'Für die gewählte Währung ist keine Geldmengendatenquelle verfügbar.';

  @override
  String priceAlertLatestPrice(String price) {
    return 'Aktueller Preis: $price';
  }

  @override
  String priceAlertAlertAt(String percent) {
    return 'Alarm ab $percent% Änderung';
  }

  @override
  String get priceAlertDisabledStatus => 'Alarm deaktiviert';

  @override
  String priceAlertSaved(String product) {
    return 'Alarm für $product gespeichert.';
  }

  @override
  String priceAlertDisabled(String product) {
    return 'Alarm für $product deaktiviert.';
  }

  @override
  String get priceAlertLoadSettingsError =>
      'Alarm-Einstellungen konnten nicht geladen werden';

  @override
  String get timeRangeLabel => 'Zeitraum';

  @override
  String get timeRange6m => '6M';

  @override
  String get timeRange1y => '1J';

  @override
  String get timeRange2y => '2J';

  @override
  String get timeRange3y => '3J';

  @override
  String get timeRange5y => '5J';

  @override
  String get timeRange10y => '10J';

  @override
  String get timeRangeYtd => 'JTD';

  @override
  String get timeRangeAll => 'Alle';

  @override
  String get timeRangeCustom => 'Custom';

  @override
  String get filterDateFrom => 'Von';

  @override
  String get filterDateTo => 'Bis';

  @override
  String get filterYear => 'Jahr';

  @override
  String get filterMonth => 'Monat';

  @override
  String get apply => 'Anwenden';

  @override
  String get bitcoinMode => 'Bitcoin-Modus (Sats)';

  @override
  String get bitcoinModeSubtitle => 'Inflation in Satoshis anzeigen';

  @override
  String get satsInflation => 'Sats-Inflation';

  @override
  String fiatEquivalent(String amount, String currency) {
    return '~$amount $currency';
  }

  @override
  String get addEntryTitle => 'Eintrag hinzufügen';

  @override
  String get selectFromPhotos => 'Aus Fotos auswählen';

  @override
  String get addManually => 'Manuell hinzufügen';

  @override
  String get premiumFeature => 'Premium-Funktion';

  @override
  String get notAvailableDesktop => 'Auf Desktop nicht verfügbar';

  @override
  String get exportFormatTitle => 'Exportformat wählen';

  @override
  String get exportFormatMessage => 'Wie möchten Sie Ihre Daten exportieren?';

  @override
  String get exportFormatSqlite => 'SQLite-Datenbank';

  @override
  String get exportFormatSqliteDesc =>
      'Vollständiges Backup, kann in dieser App wiederhergestellt werden';

  @override
  String get exportFormatCsv => 'CSV (Tabelle)';

  @override
  String get exportFormatCsvDesc =>
      'Lesbar, kompatibel mit Excel/Google Sheets';

  @override
  String get exportFormatJson => 'JSON';

  @override
  String get exportFormatJsonDesc => 'Vollständiges Backup, maschinenlesbar';

  @override
  String get settingsBackupRestore => 'Backup & Wiederherstellen';

  @override
  String get settingsExportDatabase => 'Datenbank exportieren';

  @override
  String get settingsImportDatabase => 'Datenbank importieren';

  @override
  String get settingsExportJson => 'Als JSON exportieren';

  @override
  String backupExportSuccess(String filename) {
    return 'Datenbank exportiert: $filename';
  }

  @override
  String get backupImportConfirmTitle => 'Datenbank wiederherstellen?';

  @override
  String get backupImportConfirmMessage =>
      'Dies ersetzt ALLE vorhandenen Produkte und Einstellungen. Fortfahren?';

  @override
  String get backupImportSuccess => 'Datenbank erfolgreich wiederhergestellt';

  @override
  String get backupRestartRequired =>
      'Bitte starten Sie die App neu, um die Änderungen anzuwenden.';

  @override
  String get backupInvalidFile => 'Ungültige Backup-Datei';

  @override
  String get backupRestoreButton => 'Wiederherstellen';

  @override
  String get entryDuplicateTitle => 'Ähnlicher Eintrag gefunden';

  @override
  String get entryDuplicateMessage =>
      'Ein ähnlicher Kauf wurde in den letzten 30 Tagen mit demselben Preis gefunden:';

  @override
  String get entryDuplicateDontSave => 'Nicht speichern';

  @override
  String get entryDuplicateSaveAnyway => 'Trotzdem speichern';

  @override
  String get entryExactDuplicateDiscarded =>
      'Eintrag verworfen: Ein identischer Eintrag für diesen Laden und Preis existiert bereits.';

  @override
  String get priceUpdateNotificationTitle => 'Preisaktualisierungs-Erinnerung';

  @override
  String get priceUpdateNotificationBody =>
      'Einige Ihrer Produktpreise sind möglicherweise veraltet. Tippen Sie zum Überprüfen.';

  @override
  String get priceUpdatePopupTitle => 'Preisaktualisierungen verfügbar';

  @override
  String priceUpdatePopupMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte benötigen Preisaktualisierungen',
      one: '1 Produkt benötigt eine Preisaktualisierung',
    );
    return '$_temp0';
  }

  @override
  String get priceUpdatePopupAction => 'Jetzt aktualisieren';

  @override
  String get priceUpdatePopupDismiss => 'Später';

  @override
  String get priceUpdatePermissionDenied =>
      'Benachrichtigungsberechtigung verweigert. Aktivieren Sie sie in den Einstellungen.';

  @override
  String get productDetailTitle => 'Produktdetails';

  @override
  String get productDetailDeleteProduct => 'Produkt löschen';

  @override
  String get productDetailMissingTitle => 'Produkt nicht gefunden';

  @override
  String get productDetailMissingMessage =>
      'Dieses Produkt wurde möglicherweise bereits gelöscht.';

  @override
  String get productDetailEntries => 'Einträge';

  @override
  String get productDetailFirstPurchase => 'Erster Kauf';

  @override
  String get productDetailLatestPurchase => 'Letzter Kauf';

  @override
  String get productDetailInflation => 'Produktinflation';

  @override
  String get productDetailPartialPeriod =>
      'Berechnet ab dem ersten verfügbaren Preis im Zeitraum.';

  @override
  String get productDetailNoEntriesTitle => 'Keine Einträge mehr';

  @override
  String get productDetailNoEntriesMessage =>
      'Dieses Produkt hat derzeit keine Preiseinträge.';

  @override
  String get productDetailPriceHistory => 'Preisverlauf';

  @override
  String get productDetailDuplicateNameMessage =>
      'Ein anderes Produkt verwendet bereits diesen Namen.';

  @override
  String productDetailDeleteProductMessage(String name, int count) {
    return '\"$name\" und alle $count verknüpften Einträge löschen?';
  }

  @override
  String get productDetailDeleted => 'Produkt gelöscht.';

  @override
  String get productDetailRange1m => '1M';

  @override
  String get productDetailRange3m => '3M';

  @override
  String get productDetailRange6m => '6M';

  @override
  String get productDetailViewAction => 'Produkt anzeigen';

  @override
  String duplicateCleanupNotification(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Duplikate entfernt',
      one: '1 Duplikat entfernt',
    );
    return '$_temp0';
  }

  @override
  String get quickAddPriceTitle => 'Preis hinzufügen';

  @override
  String get productDetailStoreChangeTitle => 'Geschäft ändern?';

  @override
  String productDetailStoreChangeConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return 'Dieses Produkt hat $_temp0. Das Ändern des Geschäfts wird das Standardgeschäft für zukünftige Schnell hinzufügen aktualisieren. Historische Einträge behalten ihr ursprüngliches Geschäft. Fortfahren?';
  }

  @override
  String get migrationV12Complete =>
      'Produkte haben jetzt ein festes Geschäft — Schnell hinzufügen aktiviert!';

  @override
  String get aiConsentTitle => 'KI-Quittungsscanner';

  @override
  String get aiConsentBody =>
      'Der Quittungsscanner verwendet Google Gemini KI, um Produktnamen, Preise und Mengen aus deinen Quittungsbildern zu extrahieren.\n\nWenn du eine Quittung scannst:\n• Das Bild wird zur Verarbeitung an Googles Server gesendet\n• Google verarbeitet das Bild, um Text und Artikeldetails zu erkennen\n• Die extrahierten Daten werden an die App zurückgegeben und lokal auf deinem Gerät gespeichert\n• Google kann das Bild gemäss ihrer Datenschutzrichtlinie verarbeiten\n\nEs werden keine Quittungsbilder von Google gespeichert oder an Dritte weitergegeben, ausser für die erforderliche Verarbeitung.\n\nMit der Annahme stimmst du dem Senden deiner Quittungsbilder an Google Gemini für die KI-gestützte Textextraktion zu.';

  @override
  String get aiConsentAccept => 'Akzeptieren & Fortfahren';

  @override
  String get aiConsentDecline => 'Ablehnen';

  @override
  String get aiConsentRequired =>
      'KI-Einwilligung ist erforderlich, um den Quittungsscanner zu verwenden. Du kannst stattdessen Einträge manuell hinzufügen.';

  @override
  String get barcodeSectionTitle => 'Barcode zuweisen';

  @override
  String get barcodeCopied => 'Barcode kopiert';

  @override
  String get barcodeAssign => 'Barcode zuweisen';

  @override
  String get barcodeChange => 'Barcode ändern';

  @override
  String get barcodeRemove => 'Entfernen';

  @override
  String get barcodeConflictTitle => 'Barcode bereits vergeben';

  @override
  String barcodeConflictMessage(String barcode, String product) {
    return 'Der Barcode \"$barcode\" ist bereits dem Produkt \"$product\" zugewiesen.';
  }

  @override
  String get barcodeRemoveConfirmTitle => 'Barcode entfernen?';

  @override
  String get barcodeRemoveConfirmMessage =>
      'Möchten Sie den Barcode von diesem Produkt entfernen?';

  @override
  String barcodeAssigned(String barcode) {
    return 'Barcode zugewiesen: $barcode';
  }

  @override
  String get barcodeAlreadyAssigned =>
      'Diesem Produkt ist dieser Barcode bereits zugewiesen.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStartTracking => 'Jetzt starten';

  @override
  String get onboardingWelcomeTitle => 'Verfolge deine Lebensmittel-Inflation';

  @override
  String get onboardingWelcomeSubtitle =>
      'Erfasse deine Einkäufe und sieh, wie sich Preise über die Zeit ändern.';

  @override
  String get onboardingModesTitle => 'Zeige Preise auf deine Weise';

  @override
  String get onboardingModesSubtitle =>
      'Wechsle zwischen Fiat-Währung und Satoshis, um die wahren Kosten in hartem Geld zu sehen.';

  @override
  String get onboardingModesFiatTitle => 'Fiat-Modus';

  @override
  String get onboardingModesFiatDesc =>
      'Verfolge die Inflation in deiner Landeswährung.';

  @override
  String get onboardingModesBitcoinTitle => 'Bitcoin-Modus';

  @override
  String get onboardingModesBitcoinDesc =>
      'Sieh Preise in Satoshis — die wahren Kosten in hartem Geld.';

  @override
  String get onboardingStartTitle => 'Bereit, Preise zu verfolgen';

  @override
  String get onboardingStartSubtitle =>
      'Füge deinen ersten Einkauf hinzu, um loszulegen. Scanne mit KI oder gib manuell ein.';

  @override
  String get privacyPolicySubtitle => 'Zuletzt aktualisiert: März 2026';

  @override
  String get privacyPolicySection1Title => 'Verantwortlicher';

  @override
  String get privacyPolicySection1Body =>
      'InflaBasket wird als persönliches Projekt betrieben. Bei Fragen zu dieser Datenschutzrichtlinie kontaktieren Sie uns bitte über die untenstehenden Angaben.';

  @override
  String get privacyPolicySection2Title => 'Erhobene Daten & Zweck';

  @override
  String get privacyPolicySection2Body =>
      'InflaBasket erhebt nur Daten, die Sie manuell eingeben:\n\n• Produktnamen, Preise, Mengen und Kaufdaten\n• Geschäftsnamen und Kategorien\n• Optionale Notizen zu Einträgen\n\nAlle Daten werden von Ihnen eingegeben und ausschliesslich zur Berechnung und Anzeige von Preisentwicklungen und Inflation innerhalb der App verwendet. Es werden keine Daten automatisch erhoben.';

  @override
  String get privacyPolicySection3Title => 'Datenspeicherung & Aufbewahrung';

  @override
  String get privacyPolicySection3Body =>
      'Alle Ihre Daten werden lokal auf Ihrem Gerät in einer SQLite-Datenbank gespeichert. Es werden keine Daten an externe Server übertragen.\n\nSie können Ihre Daten optional als Backup-Datei (SQLite, CSV oder JSON) exportieren. Diese Exporte werden an von Ihnen gewählten Orten gespeichert.\n\nDaten werden aufbewahrt, bis Sie sie löschen oder in der App auf Werkseinstellungen zurücksetzen.';

  @override
  String get privacyPolicySection4Title => 'Datenweitergabe';

  @override
  String get privacyPolicySection4Body =>
      'InflaBasket gibt Ihre persönlichen Daten nicht an Dritte weiter.\n\nWenn Sie den KI-Quittungsscanner (Premium-Funktion) verwenden, werden Quittungsbilder zur Textextraktion an Google Gemini gesendet. Es werden keine Bilder von Google gespeichert oder über die erforderliche Verarbeitung hinaus weitergegeben. Sie müssen dem explizit zustimmen, bevor Sie den Scanner verwenden.\n\nIm KI-Einwilligungsdialog finden Sie vollständige Informationen zur Verarbeitung von Quittungsbildern.';

  @override
  String get privacyPolicySection5Title => 'Ihre Rechte (DSGVO)';

  @override
  String get privacyPolicySection5Body =>
      'Gemäss der Datenschutz-Grundverordnung (DSGVO) haben Sie das Recht auf:\n\n• Auskunft – Alle Daten sind lokal gespeichert und in der App zugänglich\n• Berichtigung – Bearbeiten Sie jeden Eintrag direkt in der App\n• Löschung – Löschen Sie einzelne Einträge, Kategorien oder setzen Sie auf Werkseinstellungen zurück\n• Datenübertragbarkeit – Exportieren Sie Ihre Daten im CSV-, JSON- oder SQLite-Format\n• Einschränkung & Widerspruch – Die Datenverarbeitung ist minimal und lokal\n\nDa alle Daten lokal auf Ihrem Gerät gespeichert sind, haben Sie jederzeit die volle Kontrolle über Ihre Daten.';

  @override
  String get privacyPolicySection6Title => 'Kontakt';

  @override
  String get privacyPolicySection6Body =>
      'Für datenschutzbezogene Anfragen öffnen Sie bitte ein Issue in unserem GitHub-Repository oder kontaktieren Sie uns über die App-Store-Eintragsseite.';

  @override
  String get termsSubtitle => 'Zuletzt aktualisiert: März 2026';

  @override
  String get termsSection1Title => 'Annahme der Bedingungen';

  @override
  String get termsSection1Body =>
      'Durch das Herunterladen, Installieren oder Verwenden von InflaBasket stimmen Sie diesen Nutzungsbedingungen zu. Wenn Sie diesen Bedingungen nicht zustimmen, dürfen Sie die Anwendung nicht verwenden.\n\nDiese Bedingungen bilden eine rechtlich bindende Vereinbarung zwischen Ihnen und InflaBasket bezüglich der Nutzung der Anwendung und ihrer Dienste.';

  @override
  String get termsSection2Title => 'Nutzung des Dienstes';

  @override
  String get termsSection2Body =>
      'InflaBasket wird als persönliches Werkzeug zur Verfolgung von Lebensmittelpreisen und Berechnung von Inflation bereitgestellt. Sie stimmen zu:\n\n• Die Anwendung nur für rechtmässige Zwecke zu verwenden\n• Die Anwendung nicht zurückzuentwickeln, zu dekompilieren oder zu disassemblieren\n• Die Anwendung nicht zu verwenden, um Schadsoftware zu verbreichen oder ihren Betrieb zu stören\n• Keinen unbefugten Zugriff auf Teile des Dienstes zu versuchen\n\nDie Anwendung wird \"wie besehen\" und \"wie verfuegbar\" ohne jegliche Garantien bereitgestellt.';

  @override
  String get termsSection3Title => 'Benutzerkonten & Daten';

  @override
  String get termsSection3Body =>
      'InflaBasket erfordert keine Benutzerkonten. Alle Daten werden lokal auf Ihrem Gerät gespeichert.\n\nSie sind allein verantwortlich für:\n\n• Die Genauigkeit der eingegebenen Daten\n• Das Erstellen von Datensicherungen (über die Export-Funktion)\n• Folgen, die aus Datenverlust entstehen\n\nWir haften nicht für Datenverluste durch Geräteausfälle, Deinstallation der App oder Benutzerfehler.';

  @override
  String get termsSection4Title => 'Geistiges Eigentum';

  @override
  String get termsSection4Body =>
      'InflaBasket und seine originären Inhalte, Funktionen und Funktionalitäten sind Eigentum von InflaBasket und durch Urheberrecht, Markenrecht und andere Gesetze zum geistigen Eigentum geschützt.\n\nSie dürfen keinen Teil der Anwendung ohne vorherige schriftliche Zustimmung reproduzieren, verbreiten, modifizieren oder abgeleitete Werke erstellen.';

  @override
  String get termsSection5Title => 'Haftungsbeschränkung';

  @override
  String get termsSection5Body =>
      'Im gesetzlich zulässigen Umfang haftet InflaBasket nicht für indirekte, zufällige, besondere, Folge- oder Strafschäden, die aus Ihrer Nutzung oder Unmöglichkeit der Nutzung der Anwendung entstehen.\n\nDies umfasst, ohne Einschränkung:\n\n• Daten- oder Gewinnverluste\n• Betriebsunterbrechung\n• Personenschäden oder Sachschäden\n• Sonstige Schäden aus der Nutzung der Anwendung\n\nDie Gesamthaftung von InflaBasket übersteigt nicht den Betrag, den Sie für die Anwendung bezahlt haben, falls vorhanden.';

  @override
  String get termsSection6Title => 'Änderungen der Bedingungen';

  @override
  String get termsSection6Body =>
      'Wir behalten uns das Recht vor, diese Nutzungsbedingungen jederzeit zu ändern. Über wesentliche Änderungen informieren wir Benutzer durch Aktualisierung des Datums \"Zuletzt aktualisiert\" oben in diesem Dokument.\n\nDie fortgesetzte Nutzung der Anwendung nach Änderungen gilt als Annahme der aktualisierten Bedingungen. Wenn Sie mit den geänderten Bedingungen nicht einverstanden sind, müssen Sie die Anwendung nicht mehr verwenden.\n\nFür Fragen zu diesen Bedingungen kontaktieren Sie uns bitte über die App-Store-Eintragsseite oder öffnen Sie ein Issue in unserem GitHub-Repository.';

  @override
  String get settingsAutoSaveBackup => 'Auto-Speicherung';

  @override
  String get autoSaveEnable => 'Auto-Speicherung aktivieren';

  @override
  String get autoSaveStorageType => 'Speicherort';

  @override
  String get autoSaveStorageLocal => 'Lokal';

  @override
  String get autoSaveStorageCloud => 'Cloud';

  @override
  String get autoSaveLastBackup => 'Letzte Sicherung';

  @override
  String get autoSaveBackupNow => 'Jetzt sichern';

  @override
  String get autoSaveSelectFolder => 'Ordner wählen';

  @override
  String get autoSavePathNotSet => 'Kein Ordner gewählt';

  @override
  String get autoSaveSuccess => 'Sicherung erfolgreich';

  @override
  String autoSaveError(String error) {
    return 'Sicherung fehlgeschlagen: $error';
  }

  @override
  String get autoSaveEnablePrompt =>
      'Aktivieren Sie Auto-Speicherung um den Speicherort zu wählen';

  @override
  String get autoSaveManualBackup => 'Manuelle Sicherung';

  @override
  String get autoSaveNoBackup => 'Noch keine Sicherung';
}
