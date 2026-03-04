import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/entry_management/presentation/autocomplete_field.dart';
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(addEntryControllerProvider.notifier).submitEntry(
            productName: _productController.text,
            categoryName: _selectedCategoryName!,
            storeName: _storeController.text,
            price: double.parse(_priceController.text),
            quantity: double.parse(_quantityController.text),
            date: _selectedDate,
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final repo = ref.read(entryRepositoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.entryToEdit != null;

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
              AsyncAutocompleteField(
                labelText: 'Product Name',
                controller: _productController,
                optionsBuilder: repo.searchProductNames,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: dropdownValue,
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                          labelText: 'Quantity', border: OutlineInputBorder()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null
                          ? 'Invalid Qty'
                          : null,
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
              if (!isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    final isPremium =
                        ref.read(subscriptionControllerProvider).valueOrNull ??
                            false;
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
