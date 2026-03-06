import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';

/// Shows a camera barcode scanner in a bottom sheet.
/// Returns a [ProductInfo] when a barcode is successfully decoded and
/// matched against Open Food Facts, or null if the user cancels.
Future<ProductInfo?> showBarcodeScanDialog(BuildContext context) {
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
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isLooking = false;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isLooking) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!;
    setState(() {
      _isLooking = true;
      _statusMessage = 'Looking up "$code"…';
    });

    await _controller.stop();

    final client = ref.read(openFoodFactsClientProvider);
    final info = await client.lookupBarcode(code);

    if (!mounted) return;

    if (info != null) {
      Navigator.of(context).pop(info);
    } else {
      // Product not found — show a message and allow re-scan
      setState(() {
        _isLooking = false;
        _statusMessage = 'Product not found in database. Try again.';
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scanning frame overlay
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
          // Status / instructions bar at the bottom
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
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
