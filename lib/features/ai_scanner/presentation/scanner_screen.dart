import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/ai_scanner/data/vision_client.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _isProcessing = false;

  Future<void> _scanReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() => _isProcessing = true);

      try {
        final client = ref.read(visionClientProvider);
        final result = await client.parseReceipt(File(pickedFile.path));

        if (mounted) {
          setState(() => _isProcessing = false);
          _showReviewDialog(result);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  void _showReviewDialog(Map<String, dynamic> result) {
    final storeName = result['storeName'] as String? ?? 'Unknown Store';
    final dateStr = result['date'] as String?;
    final receiptDate =
        (dateStr != null ? DateTime.tryParse(dateStr) : null) ?? DateTime.now();
    final items = result['items'] as List<dynamic>? ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? <Category>[];

    showDialog(
      context: context,
      builder: (context) => _ReceiptReviewDialog(
        storeName: storeName,
        receiptDate: receiptDate,
        items: items,
        categories: categories,
        onSave: (selectedItems) async {
          try {
            await ref.read(entryRepositoryProvider).bulkAddFromReceipt(
                  storeName: storeName,
                  receiptDate: receiptDate,
                  items: selectedItems,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'} saved successfully!'),
                ),
              );
              context.pop();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving receipt: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI is analyzing your receipt...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 100, color: Colors.grey),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _scanReceipt(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _scanReceipt(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Stateful review dialog: per-item checkboxes, editable product names,
/// category dropdowns. Only checked items are saved.
class _ReceiptReviewDialog extends StatefulWidget {
  final String storeName;
  final DateTime receiptDate;
  final List<dynamic> items;
  final List<Category> categories;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;

  const _ReceiptReviewDialog({
    required this.storeName,
    required this.receiptDate,
    required this.items,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_ReceiptReviewDialog> createState() => _ReceiptReviewDialogState();
}

class _ReceiptReviewDialogState extends State<_ReceiptReviewDialog> {
  late final List<bool> _selected;
  late final List<TextEditingController> _nameControllers;
  late final List<String> _categorySelections;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selected = List.generate(widget.items.length, (_) => true);
    _nameControllers = widget.items
        .map((item) =>
            TextEditingController(text: item['productName'] as String? ?? ''))
        .toList();
    _categorySelections = widget.items
        .map((item) =>
            _resolveCategory(item['suggestedCategory'] as String? ?? ''))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _categoryNames {
    if (widget.categories.isNotEmpty) {
      return widget.categories.map((c) => c.name).toList();
    }
    // Fallback list if DB categories not yet loaded
    return [
      'Food & Groceries',
      'Dairy',
      'Meat',
      'Beverages',
      'Household',
      'Personal Care',
      'Electronics',
      'Fuel/Transportation',
      'Dining Out',
    ];
  }

  String _resolveCategory(String suggested) {
    final names = _categoryNames;
    if (names.isEmpty) return suggested.isNotEmpty ? suggested : 'Groceries';
    // Exact match (case-insensitive)
    for (final n in names) {
      if (n.toLowerCase() == suggested.toLowerCase()) return n;
    }
    // Partial match
    for (final n in names) {
      if (n.toLowerCase().contains(suggested.toLowerCase()) ||
          suggested.toLowerCase().contains(n.toLowerCase())) {
        return n;
      }
    }
    return names.first;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final selectedItems = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.items.length; i++) {
      if (_selected[i]) {
        final item =
            Map<String, dynamic>.from(widget.items[i] as Map<String, dynamic>);
        item['productName'] = _nameControllers[i].text.trim().isEmpty
            ? 'Unknown'
            : _nameControllers[i].text.trim();
        item['categoryName'] = _categorySelections[i];
        selectedItems.add(item);
      }
    }
    Navigator.of(context).pop();
    await widget.onSave(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((s) => s).length;
    final dateLabel = DateFormat.yMMMd().format(widget.receiptDate);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 560,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review Receipt',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.storeName} · $dateLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uncheck items you don\'t want to save. Tap names or categories to edit.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Item list
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = widget.items[index] as Map<String, dynamic>;
                  final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                  final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;

                  return CheckboxListTile(
                    value: _selected[index],
                    onChanged: (val) =>
                        setState(() => _selected[index] = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.only(left: 4, right: 12),
                    title: TextField(
                      controller: _nameControllers[index],
                      enabled: _selected[index],
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _categorySelections[index],
                              isExpanded: true,
                              isDense: true,
                              underline: const SizedBox(),
                              style: Theme.of(context).textTheme.bodySmall,
                              onChanged: _selected[index]
                                  ? (val) {
                                      if (val != null) {
                                        setState(() =>
                                            _categorySelections[index] = val);
                                      }
                                    }
                                  : null,
                              items: _categoryNames
                                  .map((n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(n),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${qty % 1 == 0 ? qty.toInt() : qty} × '
                            '${price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
              child: Row(
                children: [
                  // Select all / none
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            final allSelected = _selected.every((s) => s);
                            setState(() {
                              for (int i = 0; i < _selected.length; i++) {
                                _selected[i] = !allSelected;
                              }
                            });
                          },
                    child: Text(_selected.every((s) => s)
                        ? 'Deselect All'
                        : 'Select All'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_isSaving || selectedCount == 0) ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save $selectedCount Item${selectedCount == 1 ? '' : 's'}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
