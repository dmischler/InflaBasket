import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

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
    final settings = ref.watch(settingsControllerProvider);
    final entriesAsync = ref.watch(entriesWithDetailsProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: settings.currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Price Alerts')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (entries) {
          final products = _buildAlertProducts(entries);
          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add a few purchases first, then enable alerts for the products you want to track.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return FutureBuilder<Map<int, PriceAlert>>(
            future: _alertsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final alertMap = snapshot.data ?? const <int, PriceAlert>{};
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = products[index];
                  final alert = alertMap[item.product.id];
                  final subtitleParts = <String>[
                    item.category.name,
                    'Latest: ${currencyFormat.format(item.latestEntry.price)}',
                    if (alert != null)
                      alert.isEnabled
                          ? 'Alert at ${alert.thresholdPercent.toStringAsFixed(0)}%'
                          : 'Alert saved but disabled',
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
                  Text(item.category.name),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable alert'),
                    subtitle: const Text(
                      'Notify me when the next logged price changes beyond this threshold.',
                    ),
                    value: isEnabled,
                    onChanged: (value) {
                      setModalState(() {
                        isEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Threshold: ${threshold.toStringAsFixed(0)}%',
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
                      child: const Text('Save Alert'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnabled
              ? 'Alert saved for ${item.product.name}.'
              : 'Alert disabled for ${item.product.name}.',
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
