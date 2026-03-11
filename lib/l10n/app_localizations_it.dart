// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'InflaBasket';

  @override
  String get navOverview => 'Panoramica';

  @override
  String get navHistory => 'Cronologia';

  @override
  String get navCategories => 'Categorie';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get addEntry => 'Aggiungi voce';

  @override
  String get editEntry => 'Modifica voce';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get confirm => 'Conferma';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get close => 'Chiudi';

  @override
  String get edit => 'Modifica';

  @override
  String get reset => 'Ripristina';

  @override
  String get loading => 'Caricamento…';

  @override
  String get errorGeneric => 'Si è verificato un errore. Riprova.';

  @override
  String get fieldRequired => 'Questo campo è obbligatorio';

  @override
  String get fieldInvalidNumber => 'Inserisci un numero valido';

  @override
  String get fieldPositiveNumber => 'Deve essere maggiore di zero';

  @override
  String get product => 'Prodotto';

  @override
  String get productHint => 'es. Latte intero';

  @override
  String get category => 'Categoria';

  @override
  String get store => 'Negozio';

  @override
  String get storeHint => 'es. Migros';

  @override
  String get location => 'Luogo / Filiale';

  @override
  String get locationHint => 'es. Lugano, Via Nassa';

  @override
  String get price => 'Prezzo';

  @override
  String get quantity => 'Quantità';

  @override
  String get unit => 'Unità';

  @override
  String get date => 'Data';

  @override
  String get notes => 'Note';

  @override
  String get notesHint => 'Note opzionali…';

  @override
  String get scanReceipt => 'Scansiona scontrino (Premium)';

  @override
  String get scanBarcode => 'Scansiona codice a barre';

  @override
  String get barcodeNotFound =>
      'Nessun prodotto trovato per questo codice a barre.';

  @override
  String get barcodeError =>
      'Impossibile scansionare il codice a barre. Riprova.';

  @override
  String get entrySaved => 'Voce salvata con successo.';

  @override
  String get entryDeleted => 'Voce eliminata.';

  @override
  String entrySaveError(String error) {
    return 'Errore durante il salvataggio: $error';
  }

  @override
  String get deleteEntryConfirm => 'Eliminare questa voce?';

  @override
  String get deleteEntryMessage => 'Questa azione non può essere annullata.';

  @override
  String get noEntriesYet => 'Ancora nessuna voce.';

  @override
  String get noEntriesFiltered => 'Nessuna voce corrisponde ai filtri attuali.';

  @override
  String get filterTitle => 'Filtra cronologia';

  @override
  String get filterDateRange => 'Periodo';

  @override
  String get filterLast30Days => 'Ultimi 30 giorni';

  @override
  String get filterLast6Months => 'Ultimi 6 mesi';

  @override
  String get filterAllTime => 'Tutto il periodo';

  @override
  String get filterCategory => 'Categoria';

  @override
  String get filterAllCategories => 'Tutte le categorie';

  @override
  String get applyFilters => 'Applica';

  @override
  String get clearFilters => 'Cancella';

  @override
  String get overviewTitle => 'La tua inflazione';

  @override
  String get overviewBasketIndex => 'Indice del paniere';

  @override
  String get overviewTopInflators => 'Maggiori aumenti';

  @override
  String get overviewTopDeflators => 'Maggiori riduzioni';

  @override
  String get overviewNoData =>
      'Registra almeno due acquisti dello stesso prodotto per vedere l\'inflazione.';

  @override
  String get showNationalAverage => 'vs Media nazionale';

  @override
  String get showComparisonOverlay => 'Confronta con';

  @override
  String get cpiUnavailable =>
      'Dati IPC nazionali non disponibili per la valuta selezionata.';

  @override
  String get cpiLoadError => 'Impossibile caricare i dati IPC nazionali.';

  @override
  String get comparisonLoadError => 'Impossibile caricare i dati di confronto.';

  @override
  String get yourInflation => 'La tua inflazione';

  @override
  String get nationalCpi => 'IPC nazionale';

  @override
  String get moneySupplyM2 => 'Offerta di moneta M2';

  @override
  String get coreInflationSnb => 'Inflazione core 1';

  @override
  String get categoriesTitle => 'Dettaglio per categoria';

  @override
  String get categoryNoCategoryData => 'Ancora nessun dato per categoria.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSubscription => 'Abbonamento';

  @override
  String get settingsPremiumActive => 'Premium attivo';

  @override
  String get settingsFreeTier => 'Piano gratuito';

  @override
  String get settingsPremiumSubtitle =>
      'Goditi la scansione AI degli scontrini e la categorizzazione automatica.';

  @override
  String get settingsFreeSubtitle =>
      'Passa a Premium per sbloccare la scansione AI degli scontrini.';

  @override
  String get settingsRestore => 'Ripristina';

  @override
  String get settingsUpgrade => 'Passa a Premium';

  @override
  String get settingsPreferences => 'Preferenze';

  @override
  String get settingsCurrency => 'Valuta';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsMetricSystem => 'Usa il sistema metrico';

  @override
  String get settingsMetricSubtitle => 'Per quantità e prezzi unitari';

  @override
  String get settingsDataManagement => 'Gestione dati';

  @override
  String get settingsManageCategories => 'Gestisci categorie';

  @override
  String get settingsManageCategoriesSubtitle =>
      'Aggiungi o rimuovi categorie personalizzate';

  @override
  String get settingsExportData => 'Esporta dati (CSV)';

  @override
  String get settingsExportSubtitle => 'Scarica la cronologia acquisti';

  @override
  String get settingsCategoryWeights => 'Pesi delle categorie';

  @override
  String get settingsCategoryWeightsSubtitle =>
      'Personalizza il contributo di ogni categoria al tuo paniere';

  @override
  String get settingsTemplates => 'Acquisti ricorrenti';

  @override
  String get settingsTemplatesSubtitle =>
      'Modelli per aggiungere rapidamente acquisti regolari';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsVersion => 'Versione';

  @override
  String get settingsPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get settingsTerms => 'Termini di servizio';

  @override
  String get settingsComingSoon => 'Prossimamente';

  @override
  String get categoryManagementTitle => 'Gestisci categorie';

  @override
  String get categoryManagementCustomBadge => 'Personalizzata';

  @override
  String get categoryManagementDefaultBadge => 'Predefinita';

  @override
  String get addCategoryTitle => 'Aggiungi categoria';

  @override
  String get addCategoryHint => 'Nome categoria';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get deleteCategoryHasProducts =>
      'Impossibile eliminare: questa categoria ha prodotti esistenti.';

  @override
  String get weightEditorTitle => 'Pesi delle categorie';

  @override
  String get weightEditorSubtitle =>
      'Regola il contributo di ogni categoria all\'inflazione del paniere. I pesi devono sommare al 100%.';

  @override
  String weightEditorTotal(int percent) {
    return 'Totale: $percent%';
  }

  @override
  String get weightEditorResetEqual => 'Ripristina uguali';

  @override
  String get weightEditorSaveError =>
      'I pesi devono sommare al 100% prima di salvare.';

  @override
  String get templatesTitle => 'Acquisti ricorrenti';

  @override
  String get templatesEmpty =>
      'Ancora nessun modello. Aggiungi un modello per inserire rapidamente acquisti regolari.';

  @override
  String get templateAdd => 'Aggiungi modello';

  @override
  String get templateDelete => 'Eliminare il modello?';

  @override
  String get templateUseButton => 'Usa';

  @override
  String get templateSaved => 'Modello salvato.';

  @override
  String get templateDeleted => 'Modello eliminato.';

  @override
  String get duplicateDetectionTitle => 'Prodotto simile trovato';

  @override
  String duplicateDetectionMessage(String newName, String existing) {
    return '\"$newName\" sembra simile a un prodotto esistente: \"$existing\". Collegare al prodotto esistente o crearne uno nuovo?';
  }

  @override
  String get duplicateDetectionLinkExisting => 'Collega all\'esistente';

  @override
  String get duplicateDetectionCreateNew => 'Crea nuovo';

  @override
  String get priceAlerts => 'Avvisi di prezzo';

  @override
  String priceAlertTitle(String product) {
    return 'Avviso prezzo: $product';
  }

  @override
  String priceAlertBody(
      String product, String percent, String oldPrice, String newPrice) {
    return '$product costa il $percent% in più rispetto all\'ultimo acquisto ($oldPrice → $newPrice).';
  }

  @override
  String priceAlertThreshold(int percent) {
    return 'Soglia avviso: $percent%';
  }

  @override
  String get scannerTitle => 'Scansiona scontrino';

  @override
  String get scannerSelectCamera => 'Fotocamera';

  @override
  String get scannerSelectGallery => 'Galleria';

  @override
  String get scannerProcessing => 'Elaborazione scontrino…';

  @override
  String get scannerError => 'Impossibile leggere lo scontrino. Riprova.';

  @override
  String get scannerReviewTitle => 'Verifica articoli';

  @override
  String scannerSaveItems(int count) {
    return 'Salva $count articoli';
  }

  @override
  String get scannerSelectAll => 'Seleziona tutto';

  @override
  String get scannerDeselectAll => 'Deseleziona tutto';

  @override
  String get categoryFoodGroceries => 'Alimentari & spesa';

  @override
  String get categoryRestaurantsDiningOut => 'Ristoranti & asporto';

  @override
  String get categoryBeverages => 'Bevande';

  @override
  String get categoryTransportation => 'Trasporti';

  @override
  String get categoryFuelEnergy => 'Carburanti & energia';

  @override
  String get categoryHousingRent => 'Casa & affitti';

  @override
  String get categoryUtilities => 'Utenze';

  @override
  String get categoryHealthcareMedical => 'Salute & medicina';

  @override
  String get categoryPersonalCareHygiene => 'Igiene personale';

  @override
  String get categoryHouseholdSupplies => 'Articoli per la casa';

  @override
  String get categoryClothingApparel => 'Abbigliamento & moda';

  @override
  String get categoryElectronicsTech => 'Elettronica & tech';

  @override
  String get scannerDropImage => 'Trascina un\'immagine JPG, JPEG, PNG o WEBP.';

  @override
  String get scannerDragImage => 'Trascina qui un\'immagine dello scontrino';

  @override
  String get scannerDropHere => 'Rilascia qui';

  @override
  String get scannerTakePhoto => 'Scatta foto';

  @override
  String get scannerChooseImage => 'Scegli immagine';

  @override
  String get scannerAnalyzingTitle => 'Analisi dello scontrino';

  @override
  String get scannerAnalyzingMessage =>
      'L\'IA sta estraendo articoli, totali e categorie suggerite.';

  @override
  String get scannerReviewInstructions =>
      'Deseleziona gli articoli da non salvare. Tocca nomi, prezzi, quantità o categorie per modificare.';

  @override
  String get settingsPriceAlertsSubtitle =>
      'Attiva notifiche per cambiamenti di prezzo';

  @override
  String get settingsMobileOnly => 'Solo mobile';

  @override
  String get settingsDebugUnlock => 'Sblocco debug';

  @override
  String get categoryInflationTitle => 'Inflazione per categoria';

  @override
  String get categoryDetailsTitle => 'Dettagli categoria';

  @override
  String get overviewNoPriceIncreases => 'Nessun aumento di prezzo rilevato!';

  @override
  String get overviewNoPriceDecreases =>
      'Nessuna riduzione di prezzo rilevata.';

  @override
  String templateSaveError(String error) {
    return 'Errore durante il salvataggio del modello: $error';
  }

  @override
  String get duplicateProductFound => 'Prodotto simile trovato';

  @override
  String duplicateProductMessage(String newName, String existing) {
    return '\"$newName\" sembra simile a un prodotto esistente: \"$existing\". Collegare al prodotto esistente o crearne uno nuovo?';
  }

  @override
  String get categoryNoChartData => 'Dati insufficienti per il grafico.';

  @override
  String get historyDeleteTitle => 'Eliminare voce?';

  @override
  String get historyDeleteMessage =>
      'Sei sicuro di voler eliminare questo acquisto?';

  @override
  String get priceAlertEnableAlert => 'Attiva avviso';

  @override
  String get priceAlertNotifyMe =>
      'Notificami quando il prossimo prezzo registrato cambia oltre questa soglia.';

  @override
  String priceAlertThresholdLabel(String percent) {
    return 'Soglia: $percent%';
  }

  @override
  String get priceAlertSaveAlert => 'Salva avviso';

  @override
  String get priceAlertLoadingAlerts => 'Caricamento avvisi';

  @override
  String get priceAlertLoadingAlertsMessage =>
      'Raccolta dei prodotti tracciati e delle soglie di avviso esistenti.';

  @override
  String get priceAlertLoadError => 'Impossibile caricare gli avvisi';

  @override
  String get priceAlertNoProducts => 'Nessun prodotto da tracciare';

  @override
  String get priceAlertNoProductsMessage =>
      'Aggiungi prima alcuni acquisti, poi attiva gli avvisi per i prodotti che desideri monitorare.';

  @override
  String get priceAlertLoadingSettings => 'Caricamento impostazioni';

  @override
  String get priceAlertLoadingSettingsMessage =>
      'Recupero delle soglie salvate per i tuoi prodotti tracciati.';

  @override
  String templateDeleteMessage(String name) {
    return 'Rimuovere \"$name\" dagli acquisti ricorrenti?';
  }

  @override
  String get addEntrySaveAsTemplate => 'Salva come modello';

  @override
  String scannerSavedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articoli salvati con successo!',
      one: '1 articolo salvato con successo!',
    );
    return '$_temp0';
  }

  @override
  String get weightEditorResetWeights => 'Reimposta pesi';

  @override
  String get weightEditorUseSpendWeighted => 'Usa basato su spesa';

  @override
  String get categoryManagementEmpty => 'Nessuna categoria trovata.';

  @override
  String categoryManagementError(String error) {
    return 'Errore nel caricamento delle categorie: $error';
  }

  @override
  String get unknownStore => 'Negozio sconosciuto';

  @override
  String get currencyChf => 'CHF';

  @override
  String get currencyEur => 'EUR';

  @override
  String get currencyUsd => 'USD';

  @override
  String get currencyGbp => 'GBP';

  @override
  String get scannerChooseFromGallery => 'Scegli dalla galleria';

  @override
  String scannerSaveError(String error) {
    return 'Errore durante il salvataggio degli articoli: $error';
  }

  @override
  String get unknownItem => 'Articolo sconosciuto';

  @override
  String get historyNoMatchingTitle => 'Nessuna voce corrispondente';

  @override
  String get historyNoMatchingMessage =>
      'Prova a modificare o cancellare i filtri.';

  @override
  String get historyNoEntriesMessage =>
      'Inizia aggiungendo il tuo primo acquisto.';

  @override
  String get filter => 'Filtra';

  @override
  String get historyEditEntryTooltip => 'Modifica voce';

  @override
  String errorLoadingCategories(String error) {
    return 'Errore nel caricamento delle categorie: $error';
  }

  @override
  String get settingsDebugPremiumSubtitle =>
      'Debug: Premium sbloccato per test.';

  @override
  String get settingsMobileOnlySubtitle =>
      'Gli abbonamenti sono disponibili solo su iOS e Android.';

  @override
  String get templatesLoadingTitle => 'Caricamento modelli';

  @override
  String get templatesLoadingMessage => 'Recupero degli acquisti ricorrenti.';

  @override
  String get templatesLoadError => 'Impossibile caricare i modelli';

  @override
  String get paywallTitle => 'Passa a Premium';

  @override
  String get paywallDebugTitle => 'Modalità debug';

  @override
  String get paywallDebugMessage =>
      'Le funzionalità Premium sono sbloccate per i test.';

  @override
  String get paywallBackToApp => 'Torna all\'app';

  @override
  String get paywallMobileOnlyTitle => 'Solo mobile';

  @override
  String get paywallMobileOnlyMessage =>
      'Gli abbonamenti sono disponibili solo su iOS e Android. Tutte le funzionalità sono sbloccate su desktop.';

  @override
  String get paywallNoOffersTitle => 'Nessuna offerta disponibile';

  @override
  String get paywallNoOffersMessage =>
      'Impossibile caricare le offerte di abbonamento. Riprova più tardi.';

  @override
  String get paywallProductTitle => 'InflaBasket Premium';

  @override
  String get paywallFeatures =>
      'Scansione AI degli scontrini • Categorizzazione automatica • Avvisi di prezzo';

  @override
  String get paywallWelcome => 'Benvenuto in Premium!';

  @override
  String get paywallRestorePurchases => 'Ripristina acquisti';

  @override
  String get paywallLoadingOffersTitle => 'Caricamento offerte';

  @override
  String get paywallLoadingOffersMessage =>
      'Recupero dei piani di abbonamento disponibili.';

  @override
  String get paywallLoadOffersError => 'Impossibile caricare le offerte';

  @override
  String categoryTotalSpend(String amount) {
    return 'Totale: $amount';
  }

  @override
  String get comparisonSourceDetails => 'Dettagli fonte';

  @override
  String get cpiSourceTitle => 'Fonte IPC';

  @override
  String get moneySupplySourceTitle => 'Fonte offerta di moneta';

  @override
  String get cpiSourceChfDescription =>
      'Ufficio federale di statistica (UST) — indice mensile dei prezzi al consumo (IPC) per la Svizzera.';

  @override
  String get cpiSourceEurDescription =>
      'Eurostat — indice armonizzato dei prezzi al consumo (IAPC) per l\'area euro.';

  @override
  String get cpiSourceUnavailableDescription =>
      'Nessuna fonte di dati IPC disponibile per la valuta selezionata.';

  @override
  String get moneySupplySourceChfDescription =>
      'Banca nazionale svizzera (BNS) — offerta di moneta M2 per la Svizzera.';

  @override
  String get moneySupplySourceEurDescription =>
      'Banca centrale europea (BCE) — offerta di moneta M2 per l\'area euro.';

  @override
  String get moneySupplySourceUsdDescription =>
      'Federal Reserve (Fed) — offerta di moneta M2 per gli Stati Uniti.';

  @override
  String get moneySupplySourceGbpDescription =>
      'Bank of England (BoE) — offerta di moneta M2 per il Regno Unito.';

  @override
  String get moneySupplySourceUnavailableDescription =>
      'Nessuna fonte di dati sull\'offerta di moneta disponibile per la valuta selezionata.';

  @override
  String get weightEditorSaved => 'Pesi salvati.';

  @override
  String get weightEditorResetMessage =>
      'Ripristinare tutti i pesi a distribuzione uguale?';

  @override
  String get weightEditorTotalLabel => 'Totale';

  @override
  String get weightEditorMustEqual100 => 'I pesi devono sommare al 100%.';

  @override
  String priceAlertLatestPrice(String price) {
    return 'Ultimo prezzo: $price';
  }

  @override
  String priceAlertAlertAt(String percent) {
    return 'Avviso al $percent% di variazione';
  }

  @override
  String get priceAlertDisabledStatus => 'Avviso disattivato';

  @override
  String priceAlertSaved(String product) {
    return 'Avviso salvato per $product.';
  }

  @override
  String priceAlertDisabled(String product) {
    return 'Avviso disattivato per $product.';
  }

  @override
  String get priceAlertLoadSettingsError =>
      'Impossibile caricare le impostazioni avvisi';
}
