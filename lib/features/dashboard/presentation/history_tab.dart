import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/widgets/tabular_amount_text.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entries = ref.watch(filteredEntriesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final filter = ref.watch(historyFilterControllerProvider);
    final settings = ref.watch(settingsControllerProvider);

    if (entries.isEmpty) {
      final hasActiveFilter =
          filter.range != HistoryDateRange.allTime || filter.categoryId != null;
      return StateMessageCard(
        icon: hasActiveFilter ? Icons.filter_alt_off : Icons.receipt_long,
        title:
            hasActiveFilter ? l10n.historyNoMatchingTitle : l10n.noEntriesYet,
        message: hasActiveFilter
            ? l10n.historyNoMatchingMessage
            : l10n.historyNoEntriesMessage,
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
                l10n.navHistory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.filter,
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(
                    context, l10n, ref, categoriesAsync, filter),
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
              final category = entryDetails.category;

              final dateFormat = DateFormat.yMMMd();
              final currencyFormat =
                  NumberFormat.simpleCurrency(name: settings.currency);
              final categoryName = CategoryLocalization.displayNameForContext(
                context,
                category.name,
              );

              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: Theme.of(context).colorScheme.primary,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Icon(Icons.edit,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    context.push('/home/add', extra: entryDetails);
                    return false;
                  } else {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        final dl10n = AppLocalizations.of(ctx)!;
                        return AlertDialog(
                          title: Text(dl10n.deleteEntryConfirm),
                          content: Text(dl10n.deleteEntryMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(dl10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(dl10n.delete,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                onDismissed: (direction) {
                  ref
                      .read(entryRepositoryProvider)
                      .deletePurchaseEntry(entry.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.entryDeleted)),
                  );
                },
                child: _buildReceiptStrip(
                  context: context,
                  entryDetails: entryDetails,
                  l10n: l10n,
                  settings: settings,
                  dateFormat: dateFormat,
                  currencyFormat: currencyFormat,
                  categoryName: categoryName,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptStrip({
    required BuildContext context,
    required EntryWithDetails entryDetails,
    required AppLocalizations l10n,
    required AppSettings settings,
    required DateFormat dateFormat,
    required NumberFormat currencyFormat,
    required String categoryName,
  }) {
    final entry = entryDetails.entry;
    final product = entryDetails.product;
    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

    final content = ListTile(
      leading: CircleAvatar(
        backgroundColor: isLuxeMode ? AppColors.bgElevated : null,
        foregroundColor: isLuxeMode ? AppColors.textPrimary : null,
        child: Text(
          categoryName.isNotEmpty ? categoryName[0].toUpperCase() : '?',
        ),
      ),
      title: Text(product.name,
          style:
              isLuxeMode ? const TextStyle(fontWeight: FontWeight.w600) : null),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${entry.storeName} • ${dateFormat.format(entry.purchaseDate)}'),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            Text(
              entry.notes!,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            tooltip: l10n.historyEditEntryTooltip,
            onPressed: () {
              context.push('/home/add', extra: entryDetails);
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isLuxeMode)
                TabularAmountText(
                  _formatPrice(entry, settings),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                )
              else
                Text(
                  _formatPrice(entry, settings),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              _buildUnitPriceLabel(entry, settings.currency),
            ],
          ),
        ],
      ),
    );

    if (isLuxeMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: VaultCard(
          padding: EdgeInsets.zero,
          child: content,
        ),
      );
    }

    return content;
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

  String _formatPrice(PurchaseEntry entry, AppSettings settings) {
    if (settings.isBitcoinMode && entry.priceSats != null) {
      return SatsConverter.formatSats(entry.priceSats!);
    }
    final currencyFormat = NumberFormat.simpleCurrency(name: settings.currency);
    return currencyFormat.format(entry.price);
  }

  void _showFilterSheet(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    AsyncValue<List<Category>> categoriesAsync,
    HistoryFilter filter,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final sheetL10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sheetL10n.filterTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(sheetL10n.filterDateRange,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(sheetL10n.filterLast30Days),
                    selected: filter.range == HistoryDateRange.last30Days,
                    onSelected: (_) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setRange(HistoryDateRange.last30Days),
                  ),
                  ChoiceChip(
                    label: Text(sheetL10n.filterLast6Months),
                    selected: filter.range == HistoryDateRange.last6Months,
                    onSelected: (_) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setRange(HistoryDateRange.last6Months),
                  ),
                  ChoiceChip(
                    label: Text(sheetL10n.filterAllTime),
                    selected: filter.range == HistoryDateRange.allTime,
                    onSelected: (_) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setRange(HistoryDateRange.allTime),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(sheetL10n.filterCategory,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<int?>(
                    initialValue: filter.categoryId,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(sheetL10n.filterAllCategories),
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
                error: (e, st) =>
                    Text(sheetL10n.errorLoadingCategories(e.toString())),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(sheetL10n.close),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
