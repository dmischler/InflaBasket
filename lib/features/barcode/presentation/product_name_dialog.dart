import 'package:flutter/material.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';

class ProductNameDialog extends StatefulWidget {
  final ProductInfo productInfo;

  const ProductNameDialog({super.key, required this.productInfo});

  static Future<String?> show(BuildContext context, ProductInfo productInfo) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductNameDialog(productInfo: productInfo),
    );
  }

  @override
  State<ProductNameDialog> createState() => _ProductNameDialogState();
}

class _ProductNameDialogState extends State<ProductNameDialog> {
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.productInfo.name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Only show languages supported by the app (en, de)
    final variants = widget.productInfo.nameVariants
        .where((v) => v.locale == 'en' || v.locale == 'de')
        .toList();

    return AlertDialog(
      title: const Text('Select Product Name'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This product is available in multiple languages. Select the one you prefer:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ...variants.map((variant) => InkWell(
                  onTap: () => setState(() => _selectedName = variant.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _selectedName == variant.name
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _selectedName == variant.name
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant.label,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                variant.name ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            if (variants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No name variants available',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedName != null
              ? () => Navigator.of(context).pop(_selectedName)
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}
