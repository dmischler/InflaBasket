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
  String get cpiUnavailable =>
      'Données IPC nationales non disponibles pour la devise sélectionnée.';

  @override
  String get cpiLoadError =>
      'Impossible de charger les données IPC nationales.';

  @override
  String get yourInflation => 'Votre inflation';

  @override
  String get nationalCpi => 'IPC national';

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
}
