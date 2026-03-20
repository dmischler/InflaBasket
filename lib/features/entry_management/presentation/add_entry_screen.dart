import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/services/store_logo_cache.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/entry_management/presentation/autocomplete_field.dart';
import 'package:inflabasket/features/entry_management/presentation/barcode_scan_dialog.dart';
import 'package:inflabasket/features/entry_management/presentation/duplicate_dialog.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/widgets/barcode_section.dart';
import 'package:inflabasket/core/widgets/price_quantity_row.dart';
import 'package:inflabasket/core/widgets/receipt_scan_button.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  final EntryWithDetails? entryToEdit;
  final ProductInfo? productInfoFromBarcode;
  final bool lockSharedFields;

  const AddEntryScreen({
    super.key,
    this.entryToEdit,
    this.productInfoFromBarcode,
    this.lockSharedFields = false,
  });

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productController;
  late final TextEditingController _categoryController;
  late final FocusNode _categoryFocusNode;
  late final TextEditingController _storeController;
  late final TextEditingController _websiteController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  String? _selectedCategoryName;
  UnitType _selectedUnit = UnitType.count;
  bool _isEditingCategorySearch = false;

  // When the user taps "Link to Existing" in the duplicate dialog we record
  // the canonical product name so the repository resolves the right product.
  String? _resolvedProductName;

  @override
  void initState() {
    super.initState();
    final edit = widget.entryToEdit;
    final barcodeInfo = widget.productInfoFromBarcode;

    _productController = TextEditingController(
      text: edit?.product.name ?? barcodeInfo?.name ?? '',
    );
    _selectedCategoryName = edit?.category.name ??
        barcodeInfo?.suggestedCategory ??
        'Food & Groceries';
    _categoryController = TextEditingController();
    _categoryFocusNode = FocusNode();
    _categoryFocusNode.addListener(() {
      if (_categoryFocusNode.hasFocus) return;
      if (!_isEditingCategorySearch || _selectedCategoryName == null) return;
      setState(() {
        _isEditingCategorySearch = false;
        _categoryController.text = CategoryLocalization.displayNameForContext(
          context,
          _selectedCategoryName!,
        );
      });
    });
    _storeController = TextEditingController(
      text: edit?.entry.storeName ??
          (barcodeInfo?.stores.isNotEmpty == true
              ? barcodeInfo!.stores.first.name
              : barcodeInfo?.brand) ??
          '',
    );
    _websiteController = TextEditingController();
    _priceController =
        TextEditingController(text: edit?.entry.price.toString() ?? '');
    _quantityController =
        TextEditingController(text: edit?.entry.quantity.toString() ?? '1.0');
    _notesController = TextEditingController(text: edit?.entry.notes ?? '');
    _selectedDate = edit?.entry.purchaseDate ?? DateTime.now();
    _selectedUnit = unitTypeFromString(edit?.entry.unit);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWebsiteFromCache();
    });
  }

  Future<void> _loadWebsiteFromCache() async {
    final storeName = _storeController.text.trim();
    if (storeName.isEmpty) return;
    final website =
        await ref.read(storeLogoCacheProvider).getWebsite(storeName);
    if (website != null && website.isNotEmpty && mounted) {
      _websiteController.text = website;
    }
  }

  Future<void> _saveWebsiteToCache() async {
    final storeName = _storeController.text.trim();
    final website = _websiteController.text.trim();
    if (storeName.isEmpty || website.isEmpty) return;
    await ref.read(storeLogoCacheProvider).setWebsite(storeName, website);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategoryName == null || _isEditingCategorySearch) return;
    final displayName = CategoryLocalization.displayNameForContext(
      context,
      _selectedCategoryName!,
    );
    if (_categoryController.text != displayName) {
      _categoryController.text = displayName;
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _categoryController.dispose();
    _categoryFocusNode.dispose();
    _storeController.dispose();
    _websiteController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _beginCategorySearch() {
    if (_selectedCategoryName == null || _isEditingCategorySearch) return;

    final displayName = CategoryLocalization.displayNameForContext(
        context, _selectedCategoryName!);
    if (_categoryController.text == displayName) {
      setState(() {
        _isEditingCategorySearch = true;
        _categoryController.clear();
      });
    }
  }

  // ─── Barcode scan ──────────────────────────────────────────────────────────

  Future<void> _onBarcodeScan() async {
    final info = await showBarcodeScanDialog(context);
    if (info == null || !mounted) return;

    if (info.name.isEmpty && info.barcode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Barcode ${info.barcode} not found in database. You can add it manually.'),
        ),
      );
      return;
    }

    setState(() {
      _productController.text = info.name;
      if (info.suggestedCategory != null) {
        _selectedCategoryName = info.suggestedCategory;
      }
      if (info.brand != null && _storeController.text.trim().isEmpty) {
        _storeController.text = info.brand!;
      }
    });
  }

  // ─── LLM duplicate detection (Premium only) ────────────────────────────────

  /// Checks for a similar product name in the same category using a simple
  /// normalised-string similarity heuristic. For Premium users we additionally
  /// call the OpenAI API (via VisionClient chat endpoint) for semantic
  /// matching; here we keep it as a lightweight edit-distance check since
  /// VisionClient is primarily an image model and adding a full chat call
  /// would require a separate chat endpoint — deferred to a later iteration.
  Future<void> _checkForDuplicate(String typedName, int categoryId) async {
    if (typedName.trim().isEmpty) return;

    final repo = ref.read(entryRepositoryProvider);
    final names = await repo.getProductNamesForCategory(categoryId);
    if (names.isEmpty) return;

    final typed = typedName.toLowerCase().trim();

    // Find the best match by Jaro-Winkler-ish heuristic:
    // Use normalised longest-common-subsequence length as a proxy.
    String? bestMatch;
    double bestScore = 0;
    for (final name in names) {
      final score = _similarity(typed, name.toLowerCase().trim());
      if (score > bestScore) {
        bestScore = score;
        bestMatch = name;
      }
    }

    // Threshold: flag if > 70% similar but not exact
    if (bestScore > 0.70 &&
        bestMatch != null &&
        bestMatch.toLowerCase() != typed) {
      if (!mounted) return;
      final action = await showDuplicateDialog(
        context: context,
        newName: typedName,
        existingName: bestMatch,
      );
      if (action == DuplicateAction.linkToExisting) {
        setState(() {
          _resolvedProductName = bestMatch;
          _productController.text = bestMatch!;
        });
      } else {
        // createNew — clear any previous resolved name
        _resolvedProductName = null;
      }
    }
  }

  /// Computes a simple 0–1 similarity score between [a] and [b] based on
  /// the length of their longest common subsequence.
  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final m = a.length;
    final n = b.length;
    // LCS via DP
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }
    final lcs = dp[m][n];
    return (2 * lcs) / (m + n);
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final isPremium =
          ref.read(subscriptionControllerProvider).valueOrNull ?? false;

      // Run duplicate detection before saving (Premium only, new entries only)
      if (isPremium && widget.entryToEdit == null) {
        final categories =
            ref.read(categoriesProvider).valueOrNull ?? <Category>[];
        final cat = categories
            .where((c) => c.name == _selectedCategoryName)
            .firstOrNull;
        if (cat != null) {
          await _checkForDuplicate(_productController.text, cat.id);
          if (!mounted) return;
        }
      }

      final effectiveName = _resolvedProductName ?? _productController.text;

      await ref.read(addEntryControllerProvider.notifier).submitEntry(
            context: context,
            productName: effectiveName,
            categoryName: _selectedCategoryName!,
            storeName: _storeController.text,
            price: double.parse(_priceController.text),
            quantity: double.parse(_quantityController.text),
            date: _selectedDate,
            unit: _selectedUnit,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            existingEntryId: widget.entryToEdit?.entry.id,
            barcode: widget.productInfoFromBarcode?.barcode,
            forcedProductId:
                widget.lockSharedFields ? widget.entryToEdit?.product.id : null,
            storeWebsite: _websiteController.text.trim().isEmpty
                ? null
                : _websiteController.text.trim(),
          );

      if (!mounted) return;
      final state = ref.read(addEntryControllerProvider);
      if (state is AsyncError) {
        if (state.error is ExactDuplicateDiscardedException) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.entryExactDuplicateDiscarded)),
          );
          return;
        }

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.entrySaveError(state.error.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        // If coming from barcode scan, go back to home; otherwise just pop
        if (widget.productInfoFromBarcode != null) {
          context.go('/home');
        } else {
          context.pop();
        }
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final repo = ref.read(entryRepositoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.entryToEdit != null;
    final lockSharedFields = widget.lockSharedFields;
    final units = availableUnits(settings.isMetric);
    final isPremium =
        ref.watch(subscriptionControllerProvider).valueOrNull ?? false;

    final categories = categoriesAsync.valueOrNull ?? <Category>[];

    // Set default category if none selected and categories are available
    if (_selectedCategoryName == null && categories.isNotEmpty) {
      _selectedCategoryName = categories.first.name;
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.editEntry : l10n.addEntry)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AsyncAutocompleteField(
                      labelText: l10n.product,
                      controller: _productController,
                      suggestionsCallback: repo.searchProductNames,
                      enabled: !lockSharedFields,
                      minChars: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? l10n.fieldRequired
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Barcode scan button (always visible, no premium gate)
                  if (!lockSharedFields &&
                      supportsBarcodeScannerOnCurrentPlatform)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton.filledTonal(
                        tooltip: l10n.scanBarcode,
                        onPressed: _onBarcodeScan,
                        icon: const Icon(Icons.barcode_reader),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TypeAheadField<String>(
                controller: _categoryController,
                focusNode: _categoryFocusNode,
                suggestionsCallback: (search) =>
                    repo.searchCategoryNames(search),
                builder: (context, textController, focusNode) {
                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: const OutlineInputBorder(),
                    ),
                    onTap: lockSharedFields ? null : _beginCategorySearch,
                    enabled: !lockSharedFields,
                    validator: (value) => value == null || value.isEmpty
                        ? l10n.fieldRequired
                        : null,
                  );
                },
                itemBuilder: (context, itemData) {
                  return ListTile(
                    title: Text(CategoryLocalization.displayNameForContext(
                        context, itemData)),
                    dense: true,
                  );
                },
                onSelected: (selection) {
                  _categoryController.text =
                      CategoryLocalization.displayNameForContext(
                          context, selection);
                  setState(() {
                    _selectedCategoryName = selection;
                    _isEditingCategorySearch = false;
                  });
                },
                debounceDuration: const Duration(milliseconds: 300),
                hideOnEmpty: false,
              ),
              const SizedBox(height: 16),
              AsyncAutocompleteField(
                labelText: l10n.store,
                controller: _storeController,
                suggestionsCallback: repo.searchStoreNames,
                enabled: !lockSharedFields,
                validator: (value) =>
                    value == null || value.isEmpty ? l10n.fieldRequired : null,
                onSelected: (_) {
                  _loadWebsiteFromCache();
                  _saveWebsiteToCache();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(
                  labelText: 'Store Website (optional)',
                  hintText: 'e.g., www.migros.ch',
                  border: const OutlineInputBorder(),
                  suffixIcon: _websiteController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _websiteController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) {
                  setState(() {});
                  _saveWebsiteToCache();
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                leading: const Icon(Icons.calendar_month),
                title: Text(l10n.date),
                subtitle: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              PriceQuantityRow(
                priceController: _priceController,
                quantityController: _quantityController,
                selectedUnit: _selectedUnit,
                units: units,
                currency: settings.currency,
                priceLabel: l10n.price,
                quantityLabel: l10n.quantity,
                unitLabel: l10n.unit,
                priceValidator: (value) => value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null
                    ? l10n.fieldInvalidNumber
                    : null,
                quantityValidator: (value) => value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null
                    ? l10n.fieldInvalidNumber
                    : null,
                onUnitChanged: (val) {
                  setState(() => _selectedUnit = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  border: const OutlineInputBorder(),
                  hintText: l10n.notesHint,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              if (isEditing && !lockSharedFields) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                BarcodeSection(product: widget.entryToEdit!.product),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? l10n.save : l10n.addEntry),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 12),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                ReceiptScanButton(isPremium: isPremium),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
