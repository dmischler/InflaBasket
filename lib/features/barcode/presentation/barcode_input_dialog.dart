import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> showBarcodeInputDialog(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _BarcodeInputSheet(),
  );
}

class _BarcodeInputSheet extends StatefulWidget {
  const _BarcodeInputSheet();

  @override
  State<_BarcodeInputSheet> createState() => _BarcodeInputSheetState();
}

class _BarcodeInputSheetState extends State<_BarcodeInputSheet> {
  final _controller = TextEditingController();
  MobileScannerController? _scannerController;
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      _initScanner();
    } else {
      _showScanner = false;
    }
  }

  void _initScanner() {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      _showScanner = true;
    } catch (e) {
      _showScanner = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Barcode eingeben',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_showScanner && _scannerController != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: MobileScanner(
                    controller: _scannerController!,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull?.rawValue;
                      if (barcode != null) {
                        Navigator.of(context).pop(barcode);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showScanner = false),
                child: const Text('Manuell eingeben'),
              ),
            ] else ...[
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  hintText: 'z.B. 7613034626844',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                maxLength: 14,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final barcode = _controller.text.trim();
                  if (barcode.isNotEmpty) {
                    Navigator.of(context).pop(barcode);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Bestätigen'),
              ),
              if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showScanner = true),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Jetzt scannen'),
                ),
              ],
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      ),
    );
  }
}
