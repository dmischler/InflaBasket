// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'InflaBasket';

  @override
  String get navOverview => 'Aperçu';

  @override
  String get navHistory => 'Historique';

  @override
  String get navCategories => 'Catégories';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get addEntry => 'Ajouter une entrée';

  @override
  String get editEntry => 'Modifier l\'entrée';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get close => 'Fermer';

  @override
  String get edit => 'Modifier';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get loading => 'Chargement…';

  @override
  String get errorGeneric => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire';

  @override
  String get fieldInvalidNumber => 'Veuillez saisir un nombre valide';

  @override
  String get fieldPositiveNumber => 'Doit être supérieur à zéro';

  @override
  String get product => 'Produit';

  @override
  String get productHint => 'ex. Lait entier';

  @override
  String get category => 'Catégorie';

  @override
  String get store => 'Magasin';

  @override
  String get storeHint => 'ex. Coop';

  @override
  String get location => 'Lieu / Succursale';

  @override
  String get locationHint => 'ex. Genève, Rue du Mont-Blanc';

  @override
  String get price => 'Prix';

  @override
  String get quantity => 'Quantité';

  @override
  String get unit => 'Unité';

  @override
  String get date => 'Date';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Notes optionnelles…';

  @override
  String get scanReceipt => 'Scanner le reçu (Premium)';

  @override
  String get scanBarcode => 'Scanner le code-barres';

  @override
  String get barcodeNotFound => 'Aucun produit trouvé pour ce code-barres.';

  @override
  String get barcodeError =>
      'Impossible de scanner le code-barres. Veuillez réessayer.';

  @override
  String get entrySaved => 'Entrée enregistrée avec succès.';

  @override
  String get entryDeleted => 'Entrée supprimée.';

  @override
  String entrySaveError(String error) {
    return 'Erreur lors de l\'enregistrement : $error';
  }

  @override
  String get deleteEntryConfirm => 'Supprimer cette entrée ?';

  @override
  String get deleteEntryMessage => 'Cette action est irréversible.';

  @override
  String get noEntriesYet => 'Aucune entrée pour l\'instant.';

  @override
  String get noEntriesFiltered =>
      'Aucune entrée ne correspond aux filtres actuels.';

  @override
  String get filterTitle => 'Filtrer l\'historique';

  @override
  String get filterDateRange => 'Période';

  @override
  String get filterLast30Days => '30 derniers jours';

  @override
  String get filterLast6Months => '6 derniers mois';

  @override
  String get filterAllTime => 'Toute la période';

  @override
  String get filterCategory => 'Catégorie';

  @override
  String get filterAllCategories => 'Toutes les catégories';

  @override
  String get applyFilters => 'Appliquer';

  @override
  String get clearFilters => 'Effacer';

  @override
  String get overviewTitle => 'Votre inflation';

  @override
  String get overviewBasketIndex => 'Indice du panier';

  @override
  String get overviewTopInflators => 'Principales hausses';

  @override
  String get overviewTopDeflators => 'Principales baisses';

  @override
  String get overviewNoData =>
      'Enregistrez au moins deux achats du même produit pour voir l\'inflation.';

  @override
  String get showNationalAverage => 'vs Moyenne nationale';

  @override
  String get showComparisonOverlay => 'Comparer avec';

  @override
  String get cpiUnavailable =>
      'Données IPC nationales non disponibles pour la devise sélectionnée.';

  @override
  String get cpiLoadError =>
      'Impossible de charger les données IPC nationales.';

  @override
  String get comparisonLoadError =>
      'Impossible de charger les données de comparaison.';

  @override
  String get yourInflation => 'Votre inflation';

  @override
  String get nationalCpi => 'IPC national';

  @override
  String get moneySupplyM2 => 'Masse monétaire M2';

  @override
  String get coreInflationSnb => 'Inflation sous-jacente 1';

  @override
  String get categoriesTitle => 'Répartition par catégorie';

  @override
  String get categoryNoCategoryData => 'Aucune donnée de catégorie disponible.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSubscription => 'Abonnement';

  @override
  String get settingsPremiumActive => 'Premium actif';

  @override
  String get settingsFreeTier => 'Gratuit';

  @override
  String get settingsPremiumSubtitle =>
      'Profitez du scan de reçus par IA et de la catégorisation automatique.';

  @override
  String get settingsFreeSubtitle =>
      'Passez au Premium pour débloquer le scan de reçus par IA.';

  @override
  String get settingsRestore => 'Restaurer';

  @override
  String get settingsUpgrade => 'Passer au Premium';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsMetricSystem => 'Utiliser le système métrique';

  @override
  String get settingsMetricSubtitle =>
      'Pour les quantités et les prix unitaires';

  @override
  String get settingsDataManagement => 'Gestion des données';

  @override
  String get settingsManageCategories => 'Gérer les catégories';

  @override
  String get settingsManageCategoriesSubtitle =>
      'Ajouter ou supprimer des catégories personnalisées';

  @override
  String get settingsExportData => 'Exporter les données (CSV)';

  @override
  String get settingsExportSubtitle => 'Télécharger votre historique d\'achats';

  @override
  String get settingsCategoryWeights => 'Pondérations des catégories';

  @override
  String get settingsCategoryWeightsSubtitle =>
      'Personnalisez la contribution de chaque catégorie à votre panier';

  @override
  String get settingsTemplates => 'Achats récurrents';

  @override
  String get settingsTemplatesSubtitle =>
      'Modèles pour ajouter rapidement des achats réguliers';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsComingSoon => 'Bientôt disponible';

  @override
  String get categoryManagementTitle => 'Gérer les catégories';

  @override
  String get categoryManagementCustomBadge => 'Personnalisé';

  @override
  String get categoryManagementDefaultBadge => 'Par défaut';

  @override
  String get addCategoryTitle => 'Ajouter une catégorie';

  @override
  String get addCategoryHint => 'Nom de la catégorie';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Supprimer \"$name\" ?';
  }

  @override
  String get deleteCategoryHasProducts =>
      'Impossible de supprimer : cette catégorie contient des produits.';

  @override
  String get weightEditorTitle => 'Pondérations des catégories';

  @override
  String get weightEditorSubtitle =>
      'Ajustez la contribution de chaque catégorie à votre inflation. La somme doit être égale à 100 %.';

  @override
  String weightEditorTotal(int percent) {
    return 'Total : $percent %';
  }

  @override
  String get weightEditorResetEqual => 'Répartition égale';

  @override
  String get weightEditorSaveError =>
      'Les pondérations doivent totaliser 100 % avant d\'enregistrer.';

  @override
  String get templatesTitle => 'Achats récurrents';

  @override
  String get templatesEmpty =>
      'Aucun modèle pour l\'instant. Ajoutez un modèle pour saisir rapidement vos achats réguliers.';

  @override
  String get templateAdd => 'Ajouter un modèle';

  @override
  String get templateDelete => 'Supprimer le modèle ?';

  @override
  String get templateUseButton => 'Utiliser';

  @override
  String get templateSaved => 'Modèle enregistré.';

  @override
  String get templateDeleted => 'Modèle supprimé.';

  @override
  String get duplicateDetectionTitle => 'Produit similaire trouvé';

  @override
  String duplicateDetectionMessage(String newName, String existing) {
    return '\"$newName\" ressemble à un produit existant : \"$existing\". Lier au produit existant ou en créer un nouveau ?';
  }

  @override
  String get duplicateDetectionLinkExisting => 'Lier à l\'existant';

  @override
  String get duplicateDetectionCreateNew => 'Créer un nouveau';

  @override
  String get priceAlerts => 'Alertes de prix';

  @override
  String priceAlertTitle(String product) {
    return 'Alerte prix : $product';
  }

  @override
  String priceAlertBody(
      String product, String percent, String oldPrice, String newPrice) {
    return '$product coûte $percent % de plus que votre dernier achat ($oldPrice → $newPrice).';
  }

  @override
  String priceAlertThreshold(int percent) {
    return 'Seuil d\'alerte : $percent %';
  }

  @override
  String get scannerTitle => 'Scanner le reçu';

  @override
  String get scannerSelectCamera => 'Caméra';

  @override
  String get scannerSelectGallery => 'Galerie';

  @override
  String get scannerProcessing => 'Traitement du reçu…';

  @override
  String get scannerError => 'Impossible de lire le reçu. Veuillez réessayer.';

  @override
  String get scannerReviewTitle => 'Vérifier les articles';

  @override
  String scannerSaveItems(int count) {
    return 'Enregistrer $count articles';
  }

  @override
  String get scannerSelectAll => 'Tout sélectionner';

  @override
  String get scannerDeselectAll => 'Tout désélectionner';

  @override
  String get categoryFoodGroceries => 'Alimentation & courses';

  @override
  String get categoryRestaurantsDiningOut => 'Restaurants & terrasse';

  @override
  String get categoryBeverages => 'Boissons';

  @override
  String get categoryTransportation => 'Transports';

  @override
  String get categoryFuelEnergy => 'Carburant & énergie';

  @override
  String get categoryHousingRent => 'Logement & loyer';

  @override
  String get categoryUtilities => 'Services publics';

  @override
  String get categoryHealthcareMedical => 'Santé & médical';

  @override
  String get categoryPersonalCareHygiene => 'Hygiène personnelle';

  @override
  String get categoryHouseholdSupplies => 'Articles ménagers';

  @override
  String get categoryClothingApparel => 'Vêtements & mode';

  @override
  String get categoryElectronicsTech => 'Électronique & tech';

  @override
  String get scannerDropImage => 'Déposez une image JPG, JPEG, PNG ou WEBP.';

  @override
  String get scannerDragImage => 'Faites glisser une image de reçu ici';

  @override
  String get scannerDropHere => 'Déposez ici';

  @override
  String get scannerTakePhoto => 'Prendre une photo';

  @override
  String get scannerChooseImage => 'Choisir une image';

  @override
  String get scannerAnalyzingTitle => 'Analyse du reçu';

  @override
  String get scannerAnalyzingMessage =>
      'L\'IA extrait les articles, les totaux et les catégories suggérées.';

  @override
  String get scannerReviewInstructions =>
      'Décochez les articles à exclure. Appuyez sur les noms, prix, quantités ou catégories pour modifier.';

  @override
  String get settingsPriceAlertsSubtitle =>
      'Activer les notifications pour les changements de prix';

  @override
  String get settingsMobileOnly => 'Mobile uniquement';

  @override
  String get settingsDebugUnlock => 'Débogage déverrouillé';

  @override
  String get categoryInflationTitle => 'Inflation par catégorie';

  @override
  String get categoryDetailsTitle => 'Détails des catégories';

  @override
  String get overviewNoPriceIncreases => 'Aucune hausse de prix détectée !';

  @override
  String get overviewNoPriceDecreases => 'Aucune baisse de prix détectée.';

  @override
  String templateSaveError(String error) {
    return 'Erreur lors de l\'enregistrement du modèle : $error';
  }

  @override
  String get duplicateProductFound => 'Produit similaire trouvé';

  @override
  String duplicateProductMessage(String newName, String existing) {
    return '\"$newName\" ressemble à un produit existant : \"$existing\". Lier au produit existant ou en créer un nouveau ?';
  }

  @override
  String get categoryNoChartData => 'Pas assez de données pour le graphique.';

  @override
  String get historyDeleteTitle => 'Supprimer l\'entrée ?';

  @override
  String get historyDeleteMessage =>
      'Êtes-vous sûr de vouloir supprimer cet achat ?';

  @override
  String get priceAlertEnableAlert => 'Activer l\'alerte';

  @override
  String get priceAlertNotifyMe =>
      'Me prévenir lorsque le prochain prix enregistré dépasse ce seuil.';

  @override
  String priceAlertThresholdLabel(String percent) {
    return 'Seuil : $percent%';
  }

  @override
  String get priceAlertSaveAlert => 'Enregistrer l\'alerte';

  @override
  String get priceAlertLoadingAlerts => 'Chargement des alertes';

  @override
  String get priceAlertLoadingAlertsMessage =>
      'Récupération des produits suivis et des seuils d\'alerte existants.';

  @override
  String get priceAlertLoadError => 'Impossible de charger les alertes';

  @override
  String get priceAlertNoProducts => 'Aucun produit à suivre';

  @override
  String get priceAlertNoProductsMessage =>
      'Ajoutez d\'abord quelques achats, puis activez les alertes pour les produits souhaités.';

  @override
  String get priceAlertLoadingSettings => 'Chargement des paramètres';

  @override
  String get priceAlertLoadingSettingsMessage =>
      'Récupération des seuils enregistrés pour vos produits suivis.';

  @override
  String templateDeleteMessage(String name) {
    return 'Retirer \"$name\" des achats récurrents ?';
  }

  @override
  String get addEntrySaveAsTemplate => 'Enregistrer comme modèle';

  @override
  String scannerSavedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles enregistrés avec succès !',
      one: '1 article enregistré avec succès !',
    );
    return '$_temp0';
  }

  @override
  String get weightEditorResetWeights => 'Réinitialiser les poids';

  @override
  String get weightEditorUseSpendWeighted => 'Utiliser pondéré par dépenses';

  @override
  String get categoryManagementEmpty => 'Aucune catégorie trouvée.';

  @override
  String categoryManagementError(String error) {
    return 'Erreur lors du chargement des catégories : $error';
  }

  @override
  String get unknownStore => 'Magasin inconnu';

  @override
  String get currencyChf => 'CHF';

  @override
  String get currencyEur => 'EUR';

  @override
  String get currencyUsd => 'USD';

  @override
  String get currencyGbp => 'GBP';

  @override
  String get scannerChooseFromGallery => 'Choisir depuis la galerie';

  @override
  String scannerSaveError(String error) {
    return 'Erreur lors de l\'enregistrement des articles : $error';
  }

  @override
  String get unknownItem => 'Article inconnu';

  @override
  String get historyNoMatchingTitle => 'Aucune entrée correspondante';

  @override
  String get historyNoMatchingMessage =>
      'Essayez d\'ajuster ou d\'effacer vos filtres.';

  @override
  String get historyNoEntriesMessage =>
      'Commencez par ajouter votre premier achat.';

  @override
  String get filter => 'Filtrer';

  @override
  String get historyEditEntryTooltip => 'Modifier l\'entrée';

  @override
  String errorLoadingCategories(String error) {
    return 'Erreur lors du chargement des catégories : $error';
  }

  @override
  String get settingsDebugPremiumSubtitle =>
      'Débogage : Premium déverrouillé pour les tests.';

  @override
  String get settingsMobileOnlySubtitle =>
      'Les abonnements ne sont disponibles que sur iOS et Android.';

  @override
  String get templatesLoadingTitle => 'Chargement des modèles';

  @override
  String get templatesLoadingMessage =>
      'Récupération de vos achats récurrents.';

  @override
  String get templatesLoadError => 'Impossible de charger les modèles';

  @override
  String get paywallTitle => 'Passer Premium';

  @override
  String get paywallDebugTitle => 'Mode débogage';

  @override
  String get paywallDebugMessage =>
      'Les fonctionnalités Premium sont déverrouillées pour les tests.';

  @override
  String get paywallBackToApp => 'Retour à l\'application';

  @override
  String get paywallMobileOnlyTitle => 'Mobile uniquement';

  @override
  String get paywallMobileOnlyMessage =>
      'Les abonnements ne sont disponibles que sur iOS et Android. Toutes les fonctionnalités sont déverrouillées sur ordinateur.';

  @override
  String get paywallNoOffersTitle => 'Aucune offre disponible';

  @override
  String get paywallNoOffersMessage =>
      'Impossible de charger les offres d\'abonnement. Veuillez réessayer plus tard.';

  @override
  String get paywallProductTitle => 'InflaBasket Premium';

  @override
  String get paywallFeatures =>
      'Scan de reçus par IA • Catégorisation automatique • Alertes de prix';

  @override
  String get paywallWelcome => 'Bienvenue dans Premium !';

  @override
  String get paywallRestorePurchases => 'Restaurer les achats';

  @override
  String get paywallLoadingOffersTitle => 'Chargement des offres';

  @override
  String get paywallLoadingOffersMessage =>
      'Récupération des abonnements disponibles.';

  @override
  String get paywallLoadOffersError => 'Impossible de charger les offres';

  @override
  String categoryTotalSpend(String amount) {
    return 'Total : $amount';
  }

  @override
  String get comparisonSourceDetails => 'Détails de la source';

  @override
  String get cpiSourceTitle => 'Source IPC';

  @override
  String get moneySupplySourceTitle => 'Source masse monétaire';

  @override
  String get cpiSourceChfDescription =>
      'Office fédéral de la statistique (OFS) — indice mensuel des prix à la consommation (IPC) pour la Suisse.';

  @override
  String get cpiSourceEurDescription =>
      'Eurostat — indice des prix à la consommation harmonisé (IPCH) pour la zone euro.';

  @override
  String get cpiSourceUnavailableDescription =>
      'Aucune source de données IPC n\'est disponible pour la devise sélectionnée.';

  @override
  String get moneySupplySourceChfDescription =>
      'Banque nationale suisse (BNS) — masse monétaire M2 pour la Suisse.';

  @override
  String get moneySupplySourceEurDescription =>
      'Banque centrale européenne (BCE) — masse monétaire M2 pour la zone euro.';

  @override
  String get moneySupplySourceUsdDescription =>
      'Réserve fédérale (Fed) — masse monétaire M2 pour les États-Unis.';

  @override
  String get moneySupplySourceGbpDescription =>
      'Banque d\'Angleterre (BoE) — masse monétaire M2 pour le Royaume-Uni.';

  @override
  String get moneySupplySourceUnavailableDescription =>
      'Aucune source de données sur la masse monétaire n\'est disponible pour la devise sélectionnée.';

  @override
  String get weightEditorSaved => 'Pondérations enregistrées.';

  @override
  String get weightEditorResetMessage =>
      'Réinitialiser toutes les pondérations à une répartition égale ?';

  @override
  String get weightEditorTotalLabel => 'Total';

  @override
  String get weightEditorMustEqual100 =>
      'Les pondérations doivent totaliser 100 %.';

  @override
  String priceAlertLatestPrice(String price) {
    return 'Dernier prix : $price';
  }

  @override
  String priceAlertAlertAt(String percent) {
    return 'Alerte à $percent% de variation';
  }

  @override
  String get priceAlertDisabledStatus => 'Alerte désactivée';

  @override
  String priceAlertSaved(String product) {
    return 'Alerte enregistrée pour $product.';
  }

  @override
  String priceAlertDisabled(String product) {
    return 'Alerte désactivée pour $product.';
  }

  @override
  String get priceAlertLoadSettingsError =>
      'Impossible de charger les paramètres d\'alerte';
}
