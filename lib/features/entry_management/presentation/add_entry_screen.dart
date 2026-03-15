import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/services/barcode_assignment_service.dart';
import 'package:inflabasket/core/services/price_history_service.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/entry_management/presentation/autocomplete_field.dart';
import 'package:inflabasket/features/entry_management/presentation/barcode_scan_dialog.dart';
import 'package:inflabasket/features/entry_management/presentation/duplicate_dialog.dart';
import 'package:inflabasket/features/barcode/presentation/barcode_input_dialog.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  final EntryWithDetails? entryToEdit;
  final ProductInfo? productInfoFromBarcode;

  const AddEntryScreen({
    super.key,
    this.entryToEdit,
    this.productInfoFromBarcode,
  });

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productController;
  late final TextEditingController _categoryController;
  late final TextEditingController _storeController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  String? _selectedCategoryName;
  UnitType _selectedUnit = UnitType.count;

  // When the user taps "Link to Existing" in the duplicate dialog we record
  // the canonical product name so the repository resolves the right product.
  String? _resolvedProductName;

  @override
  void initState() {
    super.initState();
    final edit = widget.entryToEdit;
    final barcodeInfo = widget.productInfoFromBarcode;

    print('🔍 AddEntryScreen initState: barcodeInfo=$barcodeInfo');
    print('🔍 AddEntryScreen: barcodeInfo.name=${barcodeInfo?.name}');

    _productController = TextEditingController(
      text: edit?.product.name ?? barcodeInfo?.name ?? '',
    );
    _selectedCategoryName = edit?.category.name ??
        barcodeInfo?.suggestedCategory ??
        'Food & Groceries';
    _categoryController = TextEditingController();
    _storeController = TextEditingController(
      text: edit?.entry.storeName ??
          (barcodeInfo?.stores.isNotEmpty == true
              ? barcodeInfo!.stores.first.name
              : barcodeInfo?.brand) ??
          '',
    );
    _priceController =
        TextEditingController(text: edit?.entry.price.toString() ?? '');
    _quantityController =
        TextEditingController(text: edit?.entry.quantity.toString() ?? '1.0');
    _notesController = TextEditingController(text: edit?.entry.notes ?? '');
    _selectedDate = edit?.entry.purchaseDate ?? DateTime.now();
    _selectedUnit = unitTypeFromString(edit?.entry.unit);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoryController.text = CategoryLocalization.displayNameForContext(
        context, _selectedCategoryName!);
  }

  @override
  void dispose() {
    _productController.dispose();
    _categoryController.dispose();
    _storeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
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
          );

      if (!mounted) return;
      final state = ref.read(addEntryControllerProvider);
      if (state is AsyncError) {
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

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(addTemplateControllerProvider.notifier).addTemplateFromForm(
          productName: (_resolvedProductName ?? _productController.text).trim(),
          categoryName: _selectedCategoryName!,
          storeName: _storeController.text.trim(),
          quantity: double.parse(_quantityController.text),
          unit: _selectedUnit,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;

    final state = ref.read(addTemplateControllerProvider);
    if (state is AsyncError) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.templateSaveError(state.error.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.templateSaved)),
    );
  }

  Widget _buildBarcodeSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entry = widget.entryToEdit;
    if (entry == null) return const SizedBox.shrink();

    final product = entry.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barcode zuweisen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        if (product.barcode != null && product.barcode!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  product.barcode!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.copy,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: product.barcode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barcode kopiert')),
                    );
                  },
                  tooltip: 'Kopieren',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                  onPressed: () => _removeBarcode(context, product.id),
                  tooltip: 'Entfernen',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => _assignBarcode(context, product.id),
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(
              product.barcode == null ? 'Barcode zuweisen' : 'Barcode ändern'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceHistorySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entry = widget.entryToEdit;
    if (entry == null) return const SizedBox.shrink();

    final priceHistoryStream = ref
        .watch(priceHistoryServiceProvider)
        .watchPriceHistoryForProduct(entry.product.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preisverlauf',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<PriceHistory>>(
          stream: priceHistoryStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final prices = snapshot.data ?? [];
            if (prices.isEmpty) {
              return Text(
                'Noch keine Preise erfasst',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              );
            }
            return Column(
              children: prices.take(6).map((price) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        PriceHistoryService.formatGermanMonth(price.monthYear),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'CHF ${price.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _assignBarcode(BuildContext context, int productId) async {
    final barcode = await showBarcodeInputDialog(context);
    if (barcode == null || !mounted) return;

    final service = ref.read(barcodeAssignmentServiceProvider);
    final result =
        await service.assignBarcode(productId: productId, barcode: barcode);

    if (!mounted) return;

    if (result.status == BarcodeAssignmentStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcode zugewiesen: $barcode')),
      );
      context.pop();
      context.push('/home/add', extra: widget.entryToEdit);
    } else if (result.status == BarcodeAssignmentStatus.conflict) {
      final conflicting = result.conflictingProduct!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Barcode bereits vergeben'),
          content: Text(
            'Der Barcode "$barcode" ist bereits dem Produkt "${conflicting.name}" zugewiesen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (result.status == BarcodeAssignmentStatus.alreadyAssigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Diesem Produkt ist dieser Barcode bereits zugewiesen.')),
      );
    }
  }

  Future<void> _removeBarcode(BuildContext context, int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode entfernen?'),
        content:
            const Text('Möchten Sie den Barcode von diesem Produkt entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(barcodeAssignmentServiceProvider);
      await service.removeBarcode(productId);
      context.pop();
      context.push('/home/add', extra: widget.entryToEdit);
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
                      minChars: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? l10n.fieldRequired
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Barcode scan button (always visible, no premium gate)
                  if (supportsBarcodeScannerOnCurrentPlatform)
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
                suggestionsCallback: (search) =>
                    repo.searchCategoryNames(search),
                builder: (context, textController, focusNode) {
                  return TextFormField(
                    controller: _categoryController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: const OutlineInputBorder(),
                    ),
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
                  setState(() => _selectedCategoryName = selection);
                },
                debounceDuration: const Duration(milliseconds: 300),
                hideOnEmpty: false,
              ),
              const SizedBox(height: 16),
              AsyncAutocompleteField(
                labelText: l10n.store,
                controller: _storeController,
                suggestionsCallback: repo.searchStoreNames,
                validator: (value) =>
                    value == null || value.isEmpty ? l10n.fieldRequired : null,
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
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                    labelText: l10n.price,
                    border: const OutlineInputBorder(),
                    prefixText: '${settings.currency} '),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null
                    ? l10n.fieldInvalidNumber
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: l10n.quantity,
                        border: const OutlineInputBorder(),
                        hintText: l10n.productHint,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null
                          ? l10n.fieldInvalidNumber
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<UnitType>(
                      value: units.contains(_selectedUnit)
                          ? _selectedUnit
                          : UnitType.count,
                      decoration: InputDecoration(
                        labelText: l10n.unit,
                        border: const OutlineInputBorder(),
                      ),
                      items: units
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.label),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
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
              if (isEditing) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildBarcodeSection(context),
                const SizedBox(height: 16),
                _buildPriceHistorySection(context),
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
              OutlinedButton.icon(
                onPressed: _saveTemplate,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(l10n.templateAdd),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    if (isPremium) {
                      context.push('/scanner');
                    } else {
                      context.push('/paywall');
                    }
                  },
                  icon:
                      const Icon(Icons.document_scanner, color: Colors.purple),
                  label: Text(l10n.scanReceipt),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
