import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/entry_management/presentation/autocomplete_field.dart';
import 'package:inflabasket/features/entry_management/presentation/barcode_scan_dialog.dart';
import 'package:inflabasket/features/entry_management/presentation/duplicate_dialog.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  final EntryWithDetails? entryToEdit;

  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productController;
  late final TextEditingController _storeController;
  late final TextEditingController _locationController;
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
    _productController = TextEditingController(text: edit?.product.name ?? '');
    _selectedCategoryName = edit?.category.name;
    _storeController = TextEditingController(text: edit?.entry.storeName ?? '');
    _locationController =
        TextEditingController(text: edit?.entry.location ?? '');
    _priceController =
        TextEditingController(text: edit?.entry.price.toString() ?? '');
    _quantityController =
        TextEditingController(text: edit?.entry.quantity.toString() ?? '1.0');
    _notesController = TextEditingController(text: edit?.entry.notes ?? '');
    _selectedDate = edit?.entry.purchaseDate ?? DateTime.now();
    _selectedUnit = unitTypeFromString(edit?.entry.unit);
  }

  @override
  void dispose() {
    _productController.dispose();
    _storeController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Barcode scan ──────────────────────────────────────────────────────────

  Future<void> _onBarcodeScan() async {
    final info = await showBarcodeScanDialog(context);
    if (info == null || !mounted) return;

    setState(() {
      _productController.text = info.name;
      if (info.suggestedCategory != null) {
        _selectedCategoryName = info.suggestedCategory;
      }
      if (info.brand != null && _storeController.text.trim().isEmpty) {
        // Fill brand as a store hint if the store field is still blank
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
            productName: effectiveName,
            categoryName: _selectedCategoryName!,
            storeName: _storeController.text,
            price: double.parse(_priceController.text),
            quantity: double.parse(_quantityController.text),
            date: _selectedDate,
            unit: _selectedUnit,
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            existingEntryId: widget.entryToEdit?.entry.id,
          );

      if (!mounted) return;
      final state = ref.read(addEntryControllerProvider);
      if (state is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: ${state.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        context.pop();
      }
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(addTemplateControllerProvider.notifier).addTemplateFromForm(
          productName: (_resolvedProductName ?? _productController.text).trim(),
          categoryName: _selectedCategoryName!,
          storeName: _storeController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          quantity: double.parse(_quantityController.text),
          unit: _selectedUnit,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;

    final state = ref.read(addTemplateControllerProvider);
    if (state is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving template: ${state.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template saved.')),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final repo = ref.read(entryRepositoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.entryToEdit != null;
    final units = availableUnits(settings.isMetric);
    final isPremium =
        ref.watch(subscriptionControllerProvider).valueOrNull ?? false;

    final categories = categoriesAsync.valueOrNull ?? <Category>[];

    // Auto-select the first category once the list loads, if nothing is chosen
    if (_selectedCategoryName == null && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedCategoryName = categories.first.name);
        }
      });
    }

    // Safe dropdown value: only use _selectedCategoryName if it's in the list
    final dropdownValue = (_selectedCategoryName != null &&
            categories.any((c) => c.name == _selectedCategoryName))
        ? _selectedCategoryName
        : null;

    return Scaffold(
      appBar: AppBar(
          title:
              Text(isEditing ? 'Edit Purchase Entry' : 'Add Purchase Entry')),
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
                      labelText: 'Product Name',
                      controller: _productController,
                      optionsBuilder: repo.searchProductNames,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Barcode scan button (always visible, no premium gate)
                  if (supportsBarcodeScannerOnCurrentPlatform)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton.filledTonal(
                        tooltip: 'Scan barcode',
                        onPressed: _onBarcodeScan,
                        icon: const Icon(Icons.barcode_reader),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: dropdownValue,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategoryName = val);
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AsyncAutocompleteField(
                labelText: 'Store Name',
                controller: _storeController,
                optionsBuilder: repo.searchStoreNames,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AsyncAutocompleteField(
                labelText: 'Location (City/Branch)',
                controller: _locationController,
                optionsBuilder: repo.searchLocations,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                leading: const Icon(Icons.calendar_month),
                title: const Text('Date'),
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
                    labelText: 'Price',
                    border: const OutlineInputBorder(),
                    prefixText: '${settings.currency} '),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null
                    ? 'Invalid Price'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 500',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null
                          ? 'Invalid'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<UnitType>(
                      initialValue: units.contains(_selectedUnit)
                          ? _selectedUnit
                          : UnitType.count,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. on sale, organic, bulk pack',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save Changes' : 'Save Manual Entry'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saveTemplate,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save as Template'),
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
                  label: const Text('Scan Receipt (Premium)'),
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
