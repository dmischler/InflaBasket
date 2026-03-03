import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _categoryController = TextEditingController();
  final _storeController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1.0');
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _productController.dispose();
    _categoryController.dispose();
    _storeController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(addEntryControllerProvider.notifier).submitEntry(
            productName: _productController.text,
            categoryName: _categoryController.text,
            storeName: _storeController.text,
            price: double.parse(_priceController.text),
            quantity: double.parse(_quantityController.text),
            date: _selectedDate,
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
          );
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Purchase Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(
                    labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                    labelText: 'Category', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storeController,
                decoration: const InputDecoration(
                    labelText: 'Store Name', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: 'Location (City/Branch)',
                    border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          prefixText: '\$'),
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Save Manual Entry'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              ),
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
                icon: const Icon(Icons.document_scanner, color: Colors.purple),
                label: const Text('Scan Receipt (Premium)'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
