import 'package:flutter/material.dart';
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

enum ProductMatchAction {
  useExisting,
  createNew,
  cancel,
}

Future<ProductMatchAction?> showProductMatchDialog({
  required BuildContext context,
  required ProductInfo newProduct,
  required Product existingProduct,
  required double similarityScore,
}) {
  return showModalBottomSheet<ProductMatchAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final theme = Theme.of(ctx);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.duplicateDetectionTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(similarityScore * 100).toInt()}% ${l10n.similarity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ProductCard(
                      label: l10n.scannedProduct,
                      name: newProduct.name,
                      brand: newProduct.brand,
                      imageUrl: newProduct.imageUrl,
                      theme: theme,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.compare_arrows,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _ProductCard(
                      label: l10n.existingProduct,
                      name: existingProduct.name,
                      brand: existingProduct.brand,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.duplicateDetectionMessage(
                    newProduct.name, existingProduct.name),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(ProductMatchAction.cancel),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(ProductMatchAction.createNew),
                      child: Text(l10n.duplicateDetectionCreateNew),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(ProductMatchAction.useExisting),
                      child: Text(l10n.duplicateDetectionLinkExisting),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ProductCard extends StatelessWidget {
  final String label;
  final String name;
  final String? brand;
  final String? imageUrl;
  final ThemeData theme;

  const _ProductCard({
    required this.label,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  height: 50,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (brand != null && brand!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              brand!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
