import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/services/price_history_service.dart';
import 'package:inflabasket/features/barcode/presentation/price_prompt_dialog.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

final productsNeedingUpdateProvider =
    FutureProvider<Map<String, Map<String, List<ProductNeedingUpdate>>>>(
        (ref) async {
  final service = ref.watch(priceHistoryServiceProvider);
  final settings = ref.watch(settingsControllerProvider);
  return service.getProductsNeedingUpdate(settings.priceUpdateReminderMonths);
});

final productsWithoutPriceProvider =
    FutureProvider<Map<String, Map<String, List<ProductNeedingUpdate>>>>(
        (ref) async {
  final service = ref.watch(priceHistoryServiceProvider);
  return service.getProductsWithoutPrice();
});

class PriceUpdatesScreen extends ConsumerWidget {
  const PriceUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(productsNeedingUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.priceUpdatesTitle),
      ),
      body: productsAsync.when(
        data: (productsWithPrice) {
          if (productsWithPrice.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(productsNeedingUpdateProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productsWithPrice.length,
              itemBuilder: (context, storeIndex) {
                final storeName = productsWithPrice.keys.elementAt(storeIndex);
                final categories = productsWithPrice[storeName]!;

                return _StoreSection(
                  storeName: storeName,
                  categories: categories,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StoreSection extends StatefulWidget {
  final String storeName;
  final Map<String, List<ProductNeedingUpdate>> categories;

  const _StoreSection({
    required this.storeName,
    required this.categories,
  });

  @override
  State<_StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<_StoreSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.store,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.storeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_totalProducts()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Column(
              children: widget.categories.entries.map((entry) {
                return _CategorySection(
                  categoryName: entry.key,
                  products: entry.value,
                );
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  int _totalProducts() {
    return widget.categories.values.fold(0, (sum, list) => sum + list.length);
  }
}

class _CategorySection extends StatelessWidget {
  final String categoryName;
  final List<ProductNeedingUpdate> products;

  const _CategorySection({
    required this.categoryName,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            categoryName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...products.map((product) => _ProductTile(product: product)),
        const Divider(height: 1),
      ],
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final ProductNeedingUpdate product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(settingsControllerProvider).currency;

    final hasPrice = product.lastMonthYear.isNotEmpty;
    final priceText = hasPrice
        ? '$currency ${product.lastPrice.toStringAsFixed(2)}'
        : l10n.priceUpdatesNoPriceYet;
    final dateText = hasPrice
        ? PriceHistoryService.formatGermanMonth(product.lastMonthYear)
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          product.productName.isNotEmpty
              ? product.productName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        product.productName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        hasPrice ? '$priceText – $dateText' : l10n.priceUpdatesNoPriceYet,
        style: TextStyle(
          color: hasPrice
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.error,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => _showPricePrompt(context, ref),
    );
  }

  Future<void> _showPricePrompt(BuildContext context, WidgetRef ref) async {
    final price = await showPricePromptDialog(
      context: context,
      productName: product.productName,
      productId: product.productId,
    );

    if (price != null && price > 0) {
      final service = ref.read(priceHistoryServiceProvider);
      await service.addPrice(
        productId: product.productId,
        price: price,
      );

      HapticFeedback.mediumImpact();

      ref.invalidate(productsNeedingUpdateProvider);
      ref.invalidate(productsWithoutPriceProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.priceUpdatesSaved),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.priceUpdatesAllCurrent,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.priceUpdatesAllCurrentDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
