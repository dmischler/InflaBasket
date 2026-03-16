import 'dart:io';
import 'dart:ui';

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
import 'package:inflabasket/core/services/store_logo_cache.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/ai_scanner/data/vision_client.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final ImageSource? initialSource;
  final XFile? initialFile;

  const ScannerScreen({super.key, this.initialSource, this.initialFile});

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
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (!mounted) return;

      if (pickedFile != null) {
        await _processReceiptFile(File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      String message;
      if (e.toString().contains('photo library') ||
          e.toString().contains('photos')) {
        message = l10n.scannerSaveError(
            'Photo library access denied. Please enable in Settings.');
      } else if (e.toString().contains('camera')) {
        message = l10n.scannerSaveError(
            'Camera access denied. Please enable in Settings.');
      } else {
        message = l10n.scannerSaveError(e.toString());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scannerDropImage)),
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
    final l10n = AppLocalizations.of(context)!;
    final storeName = result['storeName'] as String? ?? l10n.unknownStore;
    final storeWebsite = result['storeWebsite'] as String? ?? '';
    final dateStr = result['date'] as String?;
    final receiptDate =
        (dateStr != null ? DateTime.tryParse(dateStr) : null) ?? DateTime.now();
    final items = result['items'] as List<dynamic>? ?? [];
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? <Category>[];
    final settings = ref.read(settingsControllerProvider);

    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == const Color(0xFF050505);

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isLuxeMode ? Colors.transparent : null,
      barrierColor: isLuxeMode ? Colors.black.withValues(alpha: 0.5) : null,
      builder: (dialogContext) {
        Widget child = _ReceiptReviewDialog(
          storeName: storeName,
          storeWebsite: storeWebsite,
          receiptDate: receiptDate,
          items: items,
          categories: categories,
          isMetric: settings.isMetric,
          onSave: (selectedItems) async {
            try {
              final result =
                  await ref.read(entryRepositoryProvider).bulkAddFromReceipt(
                        storeName: storeName,
                        receiptDate: receiptDate,
                        items: selectedItems,
                      );
              if (storeWebsite.isNotEmpty) {
                await ref
                    .read(storeLogoCacheProvider)
                    .setWebsite(storeName, storeWebsite);
              }
              if (!dialogContext.mounted) return;
              final sl10n = AppLocalizations.of(dialogContext)!;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    result.skippedDuplicateCount > 0
                        ? sl10n.scannerSavedItemsWithSkippedDuplicates(
                            result.savedCount,
                            result.skippedDuplicateCount,
                          )
                        : sl10n.scannerSavedItems(result.savedCount),
                  ),
                ),
              );
              Navigator.of(dialogContext).pop(true);
            } catch (e) {
              if (!dialogContext.mounted) return;
              final el10n = AppLocalizations.of(dialogContext)!;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(el10n.scannerSaveError(e.toString())),
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
              );
            }
          },
        );

        if (isLuxeMode) {
          child = BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withValues(alpha: 0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(
                  top: BorderSide(color: Color(0x14FFFFFF), width: 1),
                ),
              ),
              child: child,
            ),
          );
        }

        return child;
      },
    ).then((saved) {
      if (saved == true && mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (widget.initialFile != null) {
        await _processReceiptFile(File(widget.initialFile!.path));
        return;
      }

      final initialSource = widget.initialSource;
      if (initialSource == null) return;

      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _scanReceipt(initialSource);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = _isProcessing
        ? StateMessageCard(
            icon: Icons.auto_awesome,
            animationAsset: StateIllustrations.loadingMinimal,
            title: l10n.scannerAnalyzingTitle,
            message: l10n.scannerAnalyzingMessage,
            isLoading: true,
          )
        : _supportsDesktopDragAndDrop
            ? _buildDesktopDropZone(context)
            : _buildPickerActions(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scannerTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: body,
      ),
    );
  }

  Widget _buildPickerActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                label: Text(l10n.scannerTakePhoto),
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
                _supportsCameraCapture
                    ? l10n.scannerChooseFromGallery
                    : l10n.scannerChooseImage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDropZone(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      ? l10n.scannerDropHere
                      : l10n.scannerDragImage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.scannerDropImage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _scanReceipt(ImageSource.gallery),
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.scannerChooseImage),
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
  final String storeWebsite;
  final DateTime receiptDate;
  final List<dynamic> items;
  final List<Category> categories;
  final bool isMetric;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;

  const _ReceiptReviewDialog({
    required this.storeName,
    required this.storeWebsite,
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
  late final List<TextEditingController> _priceControllers;
  late final List<TextEditingController> _quantityControllers;
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
    _priceControllers = widget.items.map((item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      return TextEditingController(
        text: price > 0 ? price.toStringAsFixed(2) : '0.00',
      );
    }).toList();
    _quantityControllers = widget.items.map((item) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
      return TextEditingController(
        text: qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
      );
    }).toList();
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
    for (final c in _priceControllers) {
      c.dispose();
    }
    for (final c in _quantityControllers) {
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    final selectedItems = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.items.length; i++) {
      if (_selected[i]) {
        final item =
            Map<String, dynamic>.from(widget.items[i] as Map<String, dynamic>);
        item['productName'] = _nameControllers[i].text.trim().isEmpty
            ? l10n.unknownItem
            : _nameControllers[i].text.trim();
        item['categoryName'] = _categorySelections[i];
        item['unit'] = _unitSelections[i].name;
        // Parse price and quantity from editable fields
        final priceText = _priceControllers[i].text.trim();
        final price = double.tryParse(priceText.replaceAll(',', '.'));
        item['price'] = price ?? 0.0;
        final qtyText = _quantityControllers[i].text.trim();
        final qty = double.tryParse(qtyText.replaceAll(',', '.'));
        item['quantity'] = qty ?? 1.0;
        selectedItems.add(item);
      }
    }
    await widget.onSave(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCount = _selected.where((s) => s).length;
    final dateLabel = DateFormat.yMMMd().format(widget.receiptDate);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle for bottom sheet
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.scannerReviewTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.storeName} · $dateLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.scannerReviewInstructions,
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
                          // Quantity field
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: _quantityControllers[index],
                              enabled: _selected[index],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: UnderlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                          ),
                          Text(
                            ' × ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          // Price field
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: _priceControllers[index],
                              enabled: _selected[index],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: UnderlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 4),
                                hintText: '0.00',
                              ),
                            ),
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
                        ? l10n.scannerDeselectAll
                        : l10n.scannerSelectAll),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
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
                        : Text(l10n.scannerSaveItems(selectedCount)),
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
