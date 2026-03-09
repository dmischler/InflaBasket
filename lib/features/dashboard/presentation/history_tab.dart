import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(filteredEntriesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final filter = ref.watch(historyFilterControllerProvider);
    final settings = ref.watch(settingsControllerProvider);

    if (entries.isEmpty) {
      final hasActiveFilter =
          filter.range != HistoryDateRange.allTime || filter.categoryId != null;
      return StateMessageCard(
        icon: hasActiveFilter ? Icons.filter_alt_off : Icons.receipt_long,
        title: hasActiveFilter ? 'No Matching Entries' : 'No Entries Yet',
        message: hasActiveFilter
            ? 'Try clearing your history filters or broaden the date range.'
            : 'Add your first purchase to start tracking your personal inflation rate.',
      );
    }

    // Sort entries by date descending
    final sortedEntries = List.of(entries)
      ..sort((a, b) => b.entry.purchaseDate.compareTo(a.entry.purchaseDate));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Filter',
                icon: const Icon(Icons.filter_list),
                onPressed: () =>
                    _showFilterSheet(context, ref, categoriesAsync, filter),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entryDetails = sortedEntries[index];
              final entry = entryDetails.entry;
              final product = entryDetails.product;
              final category = entryDetails.category;

              final dateFormat = DateFormat.yMMMd();
              final currencyFormat =
                  NumberFormat.simpleCurrency(name: settings.currency);
              final categoryName = CategoryLocalization.displayNameForContext(
                context,
                category.name,
              );
              final locationText =
                  entry.location == null || entry.location!.isEmpty
                      ? ''
                      : ' (${entry.location})';

              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Entry?'),
                      content: const Text(
                          'Are you sure you want to delete this purchase entry?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref
                      .read(entryRepositoryProvider)
                      .deletePurchaseEntry(entry.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry deleted')),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      categoryName.isNotEmpty
                          ? categoryName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${entry.storeName}$locationText • ${dateFormat.format(entry.purchaseDate)}'),
                      if (entry.notes != null && entry.notes!.isNotEmpty)
                        Text(
                          entry.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  isThreeLine: entry.notes != null && entry.notes!.isNotEmpty,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit entry',
                        onPressed: () {
                          context.push('/home/add', extra: entryDetails);
                        },
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(entry.price),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          _buildUnitPriceLabel(entry, settings.currency),
                        ],
                      ),
                    ],
                  ),
                  onLongPress: null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Shows a small per-unit price label below the total price.
  /// For count units with qty = 1, nothing is shown (no useful extra info).
  Widget _buildUnitPriceLabel(PurchaseEntry entry, String currency) {
    final unit = unitTypeFromString(entry.unit);
    // Hide label when it's trivially 'same as price' (count, qty=1)
    if (unit == UnitType.count && entry.quantity == 1.0) {
      return const SizedBox.shrink();
    }
    final label =
        unit.formattedUnitPrice(entry.price, entry.quantity, currency);
    return Text(
      label,
      style: const TextStyle(fontSize: 11, color: Colors.grey),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Category>> categoriesAsync,
    HistoryFilter filter,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter History',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Date Range',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Last 30 days'),
                    selected: filter.range == HistoryDateRange.last30Days,
                    onSelected: (_) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setRange(HistoryDateRange.last30Days),
                  ),
                  ChoiceChip(
                    label: const Text('Last 6 months'),
                    selected: filter.range == HistoryDateRange.last6Months,
                    onSelected: (_) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setRange(HistoryDateRange.last6Months),
                  ),
                  ChoiceChip(
                    label: const Text('All time'),
                    selected: filter.range == HistoryDateRange.allTime,
                    onSelected: (_) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setRange(HistoryDateRange.allTime),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<int?>(
                    initialValue: filter.categoryId,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              CategoryLocalization.displayNameForContext(
                                context,
                                c.name,
                              ),
                            ),
                          )),
                    ],
                    onChanged: (value) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setCategory(value),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading categories: $e'),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
