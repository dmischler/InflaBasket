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
}
