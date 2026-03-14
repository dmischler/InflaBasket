import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/core/services/product_duplicate_detector.dart';
import 'package:inflabasket/core/services/price_history_service.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/entry_management/presentation/product_match_dialog.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/features/barcode/presentation/product_name_dialog.dart';
import 'package:inflabasket/features/barcode/presentation/price_prompt_dialog.dart';

class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends ConsumerState<BarcodeScreen> {
  MobileScannerController? _controller;
  final TextEditingController _manualBarcodeController =
      TextEditingController();
  bool _hasScanned = false;
  bool _isLooking = false;
  bool _productNotFound = false;
  bool _showManualEntry = false;
  String? _statusMessage;
  String? _lastBarcode;

  bool get _supportsCamera =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_supportsCamera) {
      _initController();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showManualEntry = true;
        });
      });
    }
  }

  void _initController() {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      if (mounted) setState(() {});
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showManualEntry = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned || _isLooking) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _hasScanned = true;
        await _lookupAndNavigate(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _lookupAndNavigate(String barcode) async {
    setState(() {
      _isLooking = true;
      _productNotFound = false;
      _statusMessage = 'Looking up "$barcode"...';
      _lastBarcode = barcode;
    });

    try {
      // 1. First check local database for existing product with this barcode
      final repo = ref.read(entryRepositoryProvider);
      final existingProduct = await repo.getProductByBarcode(barcode);

      if (!mounted) return;

      if (existingProduct != null) {
        // Exact barcode match found - show price prompt instead of AddEntryScreen
        final priceHistoryService = ref.read(priceHistoryServiceProvider);

        setState(() {
          _isLooking = false;
          _hasScanned = false;
        });

        final price = await showPricePromptDialog(
          context: context,
          productName: existingProduct.name,
          productId: existingProduct.id,
        );

        if (!mounted) return;

        if (price != null && price > 0) {
          await priceHistoryService.addPrice(
            productId: existingProduct.id,
            price: price,
          );

          HapticFeedback.mediumImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Preis für "${existingProduct.name}" gespeichert'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        return;
      }

      // 2. Not in local DB - query Open Food Facts API
      final settings = ref.read(settingsControllerProvider);
      final client = ref.read(openFoodFactsClientProvider);
      var info = await client.lookupBarcode(barcode, locale: settings.locale);

      if (!mounted) return;

      if (info != null && info.name.isNotEmpty) {
        HapticFeedback.mediumImpact();

        // Show name selection dialog if multiple variants available
        final variants = info.nameVariants;

        // Reset state BEFORE navigating away so it doesn't show "processing" on return
        setState(() {
          _isLooking = false;
          _hasScanned = false;
        });

        if (variants.length > 1) {
          final selectedName = await ProductNameDialog.show(context, info);
          print('🔍 Dialog returned: "$selectedName"');
          if (selectedName == null) {
            // User cancelled - return to input screen
            return;
          }
          // Update product info with selected name using copyWith
          info = info.copyWith(name: selectedName);
          print('🔍 ProductInfo after copyWith: name=${info.name}');
        }

        // Stage 2: Check for similar products in local database using fuzzy matching
        final detector =
            ProductDuplicateDetectorService(ref.read(appDatabaseProvider));
        final similarProducts = await detector.findSimilarProducts(
          name: info.name,
          brand: info.brand,
        );

        if (similarProducts.isNotEmpty && mounted) {
          final bestMatch = similarProducts.first;
          final action = await showProductMatchDialog(
            context: context,
            newProduct: info,
            existingProduct: bestMatch.existingProduct,
            similarityScore: bestMatch.similarityScore,
          );

          if (!mounted) return;

          if (action == ProductMatchAction.useExisting) {
            // Update existing product with new barcode and brand, then navigate
            await detector.updateProductBrand(
                bestMatch.existingProduct.id, info.brand ?? '');
            final existingProduct = bestMatch.existingProduct;
            final updatedInfo = ProductInfo(
              name: existingProduct.name,
              barcode: barcode,
              brand: info.brand ?? existingProduct.brand,
            );
            if (mounted) {
              context.push('/home/add', extra: updatedInfo);
            }
            return;
          } else if (action == ProductMatchAction.cancel) {
            // User cancelled - reset and let them scan again
            setState(() {
              _hasScanned = false;
              _isLooking = false;
              _statusMessage = null;
            });
            return;
          }
          // If createNew, proceed with new product from Open Food Facts
        }

        print('🔍 Navigating to AddEntryScreen with: $info');
        if (mounted) {
          context.push('/home/add', extra: info);
        }
      } else {
        setState(() {
          _isLooking = false;
          _productNotFound = true;
          _statusMessage = 'Product not found in database';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLooking = false;
        _productNotFound = true;
        _statusMessage = 'Error looking up product';
      });
    }
  }

  void _addManually() {
    context.push('/home/add',
        extra: ProductInfo(
          name: '',
          barcode: _lastBarcode,
        ));
  }

  void _resetAndGoBack() {
    setState(() {
      _productNotFound = false;
      _isLooking = false;
      _hasScanned = false;
      _statusMessage = null;
      _lastBarcode = null;
    });
    context.pop();
  }

  void _onManualLookup() {
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isEmpty) return;
    _lookupAndNavigate(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.barcode),
        actions: _supportsCamera && _controller != null
            ? [
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: _controller!,
                    builder: (context, state, child) {
                      return Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                      );
                    },
                  ),
                  onPressed: () => _controller?.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch),
                  onPressed: () => _controller?.switchCamera(),
                ),
              ]
            : null,
      ),
      body: _isLooking
          ? _buildLoadingState(colorScheme)
          : _productNotFound
              ? _buildProductNotFoundState(colorScheme, l10n)
              : _buildBody(colorScheme, l10n),
    );
  }

  Widget _buildProductNotFoundState(
      ColorScheme colorScheme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Product not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Barcode: $_lastBarcode',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This product is not in the Open Food Facts database.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _addManually,
              icon: const Icon(Icons.add),
              label: const Text('Add Manually'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _productNotFound = false;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Another'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _resetAndGoBack,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Platform.isIOS
              ? const CupertinoActivityIndicator(radius: 20)
              : CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            _statusMessage ?? 'Looking up...',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_supportsCamera && _controller != null && !_showManualEntry) ...[
            _buildCameraView(colorScheme, l10n),
            const SizedBox(height: 16),
          ],
          if (!_supportsCamera || _showManualEntry) ...[
            _buildManualEntry(colorScheme, l10n),
          ] else ...[
            TextButton.icon(
              onPressed: () => setState(() => _showManualEntry = true),
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter barcode manually'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraView(ColorScheme colorScheme, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry(ColorScheme colorScheme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.keyboard, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Enter barcode manually',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualBarcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
                hintText: 'e.g. 7613034626844',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              maxLength: 14,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onManualLookup(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _onManualLookup,
              icon: const Icon(Icons.search),
              label: const Text('Look Up Product'),
            ),
            const SizedBox(height: 8),
            Text(
              'Test with Swiss product barcodes like:\n'
              '7613034626844 (Nesquik)\n'
              '7610200001636 (Caotina)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
