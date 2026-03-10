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
  String get location => 'Ort / Filiale';

  @override
  String get locationHint => 'z.B. Zürich, Bahnhofstrasse';

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
  String get overviewTitle => 'Deine Inflation';

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
  String get moneySupplyM2 => 'M2-Geldmenge';

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
  String get settingsPremiumSubtitle =>
      'Geniesse KI-Belegscannen und automatische Kategorisierung.';

  @override
  String get settingsFreeSubtitle => 'Upgrade für KI-Belegscannen.';

  @override
  String get settingsRestore => 'Wiederherstellen';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsPreferences => 'Einstellungen';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsMetricSystem => 'Metrisches System verwenden';

  @override
  String get settingsMetricSubtitle => 'Für Mengen und Stückpreise';

  @override
  String get settingsDataManagement => 'Datenverwaltung';

  @override
  String get settingsManageCategories => 'Kategorien verwalten';

  @override
  String get settingsManageCategoriesSubtitle =>
      'Benutzerdefinierte Kategorien hinzufügen oder entfernen';

  @override
  String get settingsExportData => 'Daten exportieren (CSV)';

  @override
  String get settingsExportSubtitle => 'Kaufhistorie herunterladen';

  @override
  String get settingsCategoryWeights => 'Kategoriegewichtungen';

  @override
  String get settingsCategoryWeightsSubtitle =>
      'Gewichtung der Kategorien im Warenkorb anpassen';

  @override
  String get settingsTemplates => 'Wiederkehrende Einkäufe';

  @override
  String get settingsTemplatesSubtitle =>
      'Vorlagen für schnelle Einträge bei regelmässigen Einkäufen';

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
  String get weightEditorTitle => 'Kategoriegewichtungen';

  @override
  String get weightEditorSubtitle =>
      'Lege fest, wie stark jede Kategorie zur Warenkorbinflation beiträgt. Die Gewichtungen müssen 100 % ergeben.';

  @override
  String weightEditorTotal(int percent) {
    return 'Gesamt: $percent%';
  }

  @override
  String get weightEditorResetEqual => 'Gleichmässig zurücksetzen';

  @override
  String get weightEditorSaveError =>
      'Gewichtungen müssen 100 % ergeben, bevor gespeichert werden kann.';

  @override
  String get templatesTitle => 'Wiederkehrende Einkäufe';

  @override
  String get templatesEmpty =>
      'Noch keine Vorlagen. Füge eine Vorlage hinzu, um regelmässige Einkäufe schnell zu erfassen.';

  @override
  String get templateAdd => 'Vorlage hinzufügen';

  @override
  String get templateDelete => 'Vorlage löschen?';

  @override
  String get templateUseButton => 'Verwenden';

  @override
  String get templateSaved => 'Vorlage gespeichert.';

  @override
  String get templateDeleted => 'Vorlage gelöscht.';

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
      'Abwählen was nicht gespeichert werden soll. Namen oder Kategorien antippen zum Bearbeiten.';

  @override
  String get settingsPriceAlertsSubtitle =>
      'Benachrichtigungen für Preisänderungen aktivieren';

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
  String templateSaveError(String error) {
    return 'Fehler beim Speichern der Vorlage: $error';
  }

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
  String templateDeleteMessage(String name) {
    return '\"$name\" aus wiederkehrenden Einkäufen entfernen?';
  }

  @override
  String get addEntrySaveAsTemplate => 'Als Vorlage speichern';

  @override
  String scannerSavedItems(int count) {
    return '$count Artikel erfolgreich gespeichert!';
  }

  @override
  String get weightEditorResetWeights => 'Gewichte zurücksetzen';

  @override
  String get weightEditorUseSpendWeighted => 'Ausgaben-basiert verwenden';

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
  String get templatesLoadingTitle => 'Vorlagen werden geladen';

  @override
  String get templatesLoadingMessage =>
      'Deine wiederkehrenden Einkäufe werden abgerufen.';

  @override
  String get templatesLoadError => 'Vorlagen konnten nicht geladen werden';

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
  String get weightEditorSaved => 'Gewichtungen gespeichert.';

  @override
  String get weightEditorResetMessage =>
      'Alle Kategoriegewichtungen auf gleiche Verteilung zurücksetzen?';

  @override
  String get weightEditorTotalLabel => 'Gesamt';

  @override
  String get weightEditorMustEqual100 => 'Gewichtungen müssen 100 % ergeben.';

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
}
