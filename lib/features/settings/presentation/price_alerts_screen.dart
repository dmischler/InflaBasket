import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class PriceAlertsScreen extends ConsumerStatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  ConsumerState<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends ConsumerState<PriceAlertsScreen> {
  late Future<Map<int, PriceAlert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _loadAlerts();
  }

  Future<Map<int, PriceAlert>> _loadAlerts() async {
    final alerts = await ref.read(entryRepositoryProvider).getAllPriceAlerts();
    return {for (final alert in alerts) alert.productId: alert};
  }

  void _refreshAlerts() {
    setState(() {
      _alertsFuture = _loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final entriesAsync = ref.watch(entriesWithDetailsProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: settings.currency);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.priceAlerts)),
      body: entriesAsync.when(
        loading: () => StateMessageCard(
          icon: Icons.notifications_active_outlined,
          title: l10n.priceAlertLoadingAlerts,
          message: l10n.priceAlertLoadingAlertsMessage,
          isLoading: true,
        ),
        error: (error, _) => StateMessageCard(
          icon: Icons.error_outline,
          title: l10n.priceAlertLoadError,
          message: error.toString(),
          accentColor: Theme.of(context).colorScheme.error,
        ),
        data: (entries) {
          final products = _buildAlertProducts(entries);
          if (products.isEmpty) {
            return StateMessageCard(
              icon: Icons.price_change_outlined,
              title: l10n.priceAlertNoProducts,
              message: l10n.priceAlertNoProductsMessage,
            );
          }

          return FutureBuilder<Map<int, PriceAlert>>(
            future: _alertsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return StateMessageCard(
                  icon: Icons.tune,
                  title: l10n.priceAlertLoadingSettings,
                  message: l10n.priceAlertLoadingSettingsMessage,
                  isLoading: true,
                );
              }
              if (snapshot.hasError) {
                return StateMessageCard(
                  icon: Icons.error_outline,
                  title: l10n.priceAlertLoadSettingsError,
                  message: snapshot.error.toString(),
                  accentColor: Theme.of(context).colorScheme.error,
                );
              }

              final alertMap = snapshot.data ?? const <int, PriceAlert>{};
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = products[index];
                  final alert = alertMap[item.product.id];
                  final categoryName =
                      CategoryLocalization.displayNameForContext(
                    context,
                    item.category.name,
                  );
                  final subtitleParts = <String>[
                    categoryName,
                    l10n.priceAlertLatestPrice(
                        currencyFormat.format(item.latestEntry.price)),
                    if (alert != null)
                      alert.isEnabled
                          ? l10n.priceAlertAlertAt(
                              alert.thresholdPercent.toStringAsFixed(0))
                          : l10n.priceAlertDisabledStatus,
                  ];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(item.product.name.characters.first),
                      ),
                      title: Text(item.product.name),
                      subtitle: Text(subtitleParts.join(' - ')),
                      trailing: Switch.adaptive(
                        value: alert?.isEnabled ?? false,
                        onChanged: (_) => _showEditor(item, alert),
                      ),
                      onTap: () => _showEditor(item, alert),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<_AlertableProduct> _buildAlertProducts(List<EntryWithDetails> entries) {
    final byProductId = <int, _AlertableProduct>{};

    for (final detail in entries) {
      final existing = byProductId[detail.product.id];
      if (existing == null ||
          detail.entry.purchaseDate
              .isAfter(existing.latestEntry.purchaseDate)) {
        byProductId[detail.product.id] = _AlertableProduct(
          product: detail.product,
          category: detail.category,
          latestEntry: detail.entry,
        );
      }
    }

    final items = byProductId.values.toList()
      ..sort((a, b) => a.product.name.compareTo(b.product.name));
    return items;
  }

  Future<void> _showEditor(
    _AlertableProduct item,
    PriceAlert? alert,
  ) async {
    var isEnabled = alert?.isEnabled ?? false;
    var threshold = alert?.thresholdPercent ?? 10.0;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CategoryLocalization.displayNameForContext(
                      context,
                      item.category.name,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.priceAlertEnableAlert),
                    subtitle: Text(l10n.priceAlertNotifyMe),
                    value: isEnabled,
                    onChanged: (value) {
                      setModalState(() {
                        isEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.priceAlertThresholdLabel(threshold.toStringAsFixed(0)),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    min: 1,
                    max: 50,
                    divisions: 49,
                    value: threshold,
                    label: '${threshold.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setModalState(() {
                        threshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.priceAlertSaveAlert),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved != true) return;

    await ref.read(entryRepositoryProvider).setPriceAlert(
          productId: item.product.id,
          thresholdPercent: threshold,
          isEnabled: isEnabled,
        );

    if (!mounted) return;

    _refreshAlerts();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnabled
              ? l10n.priceAlertSaved(item.product.name)
              : l10n.priceAlertDisabled(item.product.name),
        ),
      ),
    );
  }
}

class _AlertableProduct {
  const _AlertableProduct({
    required this.product,
    required this.category,
    required this.latestEntry,
  });

  final Product product;
  final Category category;
  final PurchaseEntry latestEntry;
}
