import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/ai_scanner/data/vision_client.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _isProcessing = false;
  bool _isDraggingFile = false;

  bool get _supportsDesktopDragAndDrop {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  bool get _supportsCameraCapture {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (!mounted) return;

    if (pickedFile != null) {
      await _processReceiptFile(File(pickedFile.path));
    }
  }

  Future<void> _processReceiptFile(File imageFile) async {
    setState(() => _isProcessing = true);

    try {
      final client = ref.read(visionClientProvider);
      final categories =
          ref.read(categoriesProvider).valueOrNull ?? <Category>[];
      final customCategoryNames = categories
          .where((category) => category.isCustom)
          .map((category) => category.name)
          .toList(growable: false);
      final result = await client.parseReceipt(
        imageFile,
        defaultCategoryKeys: CategoryLocalization.defaultCategoryKeys,
        customCategoryNames: customCategoryNames,
      );
      if (!mounted) return;

      setState(() => _isProcessing = false);
      _showReviewDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty || _isProcessing) return;

    XFile? firstImage;
    for (final file in files) {
      if (_isSupportedImageFile(file.path)) {
        firstImage = file;
        break;
      }
    }

    if (firstImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drop a JPG, JPEG, PNG, or WEBP receipt image.'),
        ),
      );
      return;
    }

    await _processReceiptFile(File(firstImage.path));
  }

  bool _isSupportedImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension);
  }

  void _showReviewDialog(Map<String, dynamic> result) {
    final storeName = result['storeName'] as String? ?? 'Unknown Store';
    final dateStr = result['date'] as String?;
    final receiptDate =
        (dateStr != null ? DateTime.tryParse(dateStr) : null) ?? DateTime.now();
    final items = result['items'] as List<dynamic>? ?? [];
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? <Category>[];
    final settings = ref.read(settingsControllerProvider);

    showDialog(
      context: context,
      builder: (context) => _ReceiptReviewDialog(
        storeName: storeName,
        receiptDate: receiptDate,
        items: items,
        categories: categories,
        isMetric: settings.isMetric,
        onSave: (selectedItems) async {
          try {
            await ref.read(entryRepositoryProvider).bulkAddFromReceipt(
                  storeName: storeName,
                  receiptDate: receiptDate,
                  items: selectedItems,
                );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'} saved successfully!'),
              ),
            );
            context.pop();
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving receipt: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _isProcessing
        ? const StateMessageCard(
            icon: Icons.auto_awesome,
            title: 'Analyzing Receipt',
            message:
                'The AI is extracting line items, totals, and suggested categories.',
            isLoading: true,
          )
        : _supportsDesktopDragAndDrop
            ? _buildDesktopDropZone(context)
            : _buildPickerActions(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: body,
      ),
    );
  }

  Widget _buildPickerActions(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            if (_supportsCameraCapture)
              ElevatedButton.icon(
                onPressed: () => _scanReceipt(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            if (_supportsCameraCapture) const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _scanReceipt(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: Text(
                _supportsCameraCapture ? 'Choose from Gallery' : 'Choose Image',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDropZone(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DropTarget(
          onDragEntered: (_) => setState(() => _isDraggingFile = true),
          onDragExited: (_) => setState(() => _isDraggingFile = false),
          onDragDone: (detail) async {
            setState(() => _isDraggingFile = false);
            await _handleDroppedFiles(detail.files);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _isDraggingFile
                  ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDraggingFile
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: _isDraggingFile ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isDraggingFile
                      ? Icons.file_download_done
                      : Icons.upload_file,
                  size: 56,
                  color: _isDraggingFile
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _isDraggingFile
                      ? 'Drop the receipt image here'
                      : 'Drag and drop a receipt image',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Desktop mode accepts JPG, PNG, or WEBP files. You can also browse for an image if you prefer.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _scanReceipt(ImageSource.gallery),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose Image'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stateful review dialog: per-item checkboxes, editable product names,
/// category dropdowns, and unit pickers. Only checked items are saved.
class _ReceiptReviewDialog extends StatefulWidget {
  final String storeName;
  final DateTime receiptDate;
  final List<dynamic> items;
  final List<Category> categories;
  final bool isMetric;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;

  const _ReceiptReviewDialog({
    required this.storeName,
    required this.receiptDate,
    required this.items,
    required this.categories,
    required this.isMetric,
    required this.onSave,
  });

  @override
  State<_ReceiptReviewDialog> createState() => _ReceiptReviewDialogState();
}

class _ReceiptReviewDialogState extends State<_ReceiptReviewDialog> {
  late final List<bool> _selected;
  late final List<TextEditingController> _nameControllers;
  late final List<String> _categorySelections;
  late final List<UnitType> _unitSelections;
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
    _unitSelections = widget.items.map((item) {
      final unitStr = item['unit'] as String?;
      final parsed = unitTypeFromString(unitStr);
      // If the parsed unit isn't available for the current metric/imperial
      // setting, fall back to count.
      final available = availableUnits(widget.isMetric);
      return available.contains(parsed) ? parsed : UnitType.count;
    }).toList();
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
      return widget.categories.map<String>((c) => c.name).toList();
    }
    return CategoryLocalization.defaultCategoryKeys;
  }

  String _resolveCategory(String suggested) {
    return CategoryLocalization.resolveCanonicalName(
      suggested,
      _categoryNames,
    );
  }

  String _displayCategoryName(String categoryName) {
    return CategoryLocalization.displayNameForContext(context, categoryName);
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
        item['unit'] = _unitSelections[i].name;
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
                                        child: Text(_displayCategoryName(n)),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unit picker
                          DropdownButton<UnitType>(
                            value: _unitSelections[index],
                            isDense: true,
                            underline: const SizedBox(),
                            style: Theme.of(context).textTheme.bodySmall,
                            onChanged: _selected[index]
                                ? (val) {
                                    if (val != null) {
                                      setState(
                                          () => _unitSelections[index] = val);
                                    }
                                  }
                                : null,
                            items: availableUnits(widget.isMetric)
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u.label),
                                    ))
                                .toList(),
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
