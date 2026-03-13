import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

bool get supportsBarcodeScannerOnCurrentPlatform {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Shows a camera barcode scanner in a bottom sheet.
/// Returns a [ProductInfo] when a barcode is successfully decoded and
/// matched against Open Food Facts, or null if the user cancels.
Future<ProductInfo?> showBarcodeScanDialog(BuildContext context) {
  if (!supportsBarcodeScannerOnCurrentPlatform) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Barcode scanning is currently available on mobile only.',
        ),
      ),
    );
    return Future.value(null);
  }

  return showModalBottomSheet<ProductInfo?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (_) => const _BarcodeScanSheet(),
  );
}

class _BarcodeScanSheet extends ConsumerStatefulWidget {
  const _BarcodeScanSheet();

  @override
  ConsumerState<_BarcodeScanSheet> createState() => _BarcodeScanSheetState();
}

class _BarcodeScanSheetState extends ConsumerState<_BarcodeScanSheet> {
  MobileScannerController? _controller;
  bool _isLooking = false;
  bool _hasError = false;
  bool _productNotFound = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _lastBarcode;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      if (mounted) setState(() {});
    } catch (e) {
      _setError('Failed to initialize camera: $e');
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isLooking || _hasError || _productNotFound) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!;
    _lastBarcode = code;
    setState(() {
      _isLooking = true;
      _statusMessage = 'Looking up "$code"...';
    });

    try {
      await _controller?.stop();
    } catch (_) {}

    try {
      final settings = ref.read(settingsControllerProvider);
      final client = ref.read(openFoodFactsClientProvider);
      final info = await client.lookupBarcode(code, locale: settings.locale);

      if (!mounted) return;

      if (info != null) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(info);
      } else {
        setState(() {
          _isLooking = false;
          _productNotFound = true;
          _statusMessage = 'Product not found. You can add it manually.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLooking = false;
        _productNotFound = true;
        _statusMessage = 'Error looking up product. You can add it manually.';
      });
    }
  }

  void _addManually() {
    final productInfo = ProductInfo(
      name: '',
      barcode: _lastBarcode,
    );
    Navigator.of(context).pop(productInfo);
  }

  Future<void> _retryScan() async {
    setState(() {
      _productNotFound = false;
      _statusMessage = null;
    });
    try {
      await _controller?.start();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!supportsBarcodeScannerOnCurrentPlatform) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Barcode scanning is currently available on mobile only.',
              style: TextStyle(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Camera error',
                  style: TextStyle(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Close',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        child: Center(
          child: Platform.isIOS
              ? const CupertinoActivityIndicator()
              : CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _statusMessage ?? 'Align barcode within the frame',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (_isLooking) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Platform.isIOS
                          ? const CupertinoActivityIndicator(
                              color: Colors.white)
                          : const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (_productNotFound) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _retryScan,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _addManually,
                          child: const Text('Add Anyway'),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
