import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/ai_scanner/data/vision_client.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';

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
    final storeName = result['storeName'] ?? 'Unknown Store';
    final items = result['items'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Receipt: $storeName'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['productName'] ?? 'Unknown Product'),
                subtitle: Text(
                    'Category: ${item['suggestedCategory']} (Conf: ${item['confidence']})'),
                trailing: Text('\$${item['price']} x ${item['quantity']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              // Bulk save logic here (simplification for MVP: save each one)
              final entryController =
                  ref.read(addEntryControllerProvider.notifier);
              for (final item in items) {
                await entryController.submitEntry(
                  productName: item['productName'] ?? 'Unknown',
                  categoryName: item['suggestedCategory'] ?? 'Groceries',
                  storeName: storeName,
                  price: (item['price'] as num?)?.toDouble() ?? 0.0,
                  quantity: (item['quantity'] as num?)?.toDouble() ?? 1.0,
                  date: DateTime.now(), // Fallback parsing date
                );
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt saved successfully!')),
                );
                context.pop(); // Close scanner screen
              }
            },
            child: const Text('Save All'),
          )
        ],
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
