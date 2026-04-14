import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/router/navigation_extensions.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/widgets/store_logo_widget.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart'
    hide allStoresProvider;
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/widgets/tabular_amount_text.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  bool _isSearchExpanded = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(historyFilterControllerProvider.notifier).setSearchQuery(
        _searchController.text.isEmpty ? null : _searchController.text);
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        ref.read(historyFilterControllerProvider.notifier).setSearchQuery(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = ref.watch(filteredEntriesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final storesAsync = ref.watch(allStoresProvider);
    final filter = ref.watch(historyFilterControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final btcCacheAsync = settings.isBitcoinMode
        ? ref.watch(btcPriceCacheProvider)
        : const AsyncData<Map<String, double>>(<String, double>{});

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _isSearchExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    l10n.navHistory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  secondChild: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: l10n.searchHint,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: l10n.searchClear,
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: l10n.close,
                          onPressed: _toggleSearch,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isSearchExpanded)
                IconButton(
                  tooltip: l10n.search,
                  icon: const Icon(Icons.search),
                  onPressed: _toggleSearch,
                ),
              IconButton(
                tooltip: l10n.filter,
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(
                    context, l10n, ref, categoriesAsync, storesAsync, filter),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildEntryList(
            context,
            entries,
            l10n,
            settings,
            btcCacheAsync.valueOrNull ?? const {},
          ),
        ),
      ],
    );
  }

  Widget _buildEntryList(
    BuildContext context,
    List<EntryWithDetails> entries,
    AppLocalizations l10n,
    AppSettings settings,
    Map<String, double> btcCache,
  ) {
    if (entries.isEmpty) {
      final filter = ref.watch(historyFilterControllerProvider);
      final hasActiveFilter = filter.range != HistoryDateRange.allTime ||
          filter.categoryId != null ||
          filter.storeName != null ||
          (filter.searchQuery != null && filter.searchQuery!.isNotEmpty);
      return StateMessageCard(
        icon: hasActiveFilter ? Icons.filter_alt_off : Icons.receipt_long,
        animationAsset: hasActiveFilter
            ? StateIllustrations.emptySearch
            : StateIllustrations.emptyGeneral,
        title:
            hasActiveFilter ? l10n.historyNoMatchingTitle : l10n.noEntriesYet,
        message: hasActiveFilter
            ? l10n.historyNoMatchingMessage
            : l10n.historyNoEntriesMessage,
      );
    }

    final sortedEntries = List.of(entries)
      ..sort((a, b) => b.entry.purchaseDate.compareTo(a.entry.purchaseDate));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(entriesWithDetailsProvider);
        imageCache.clear();
      },
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entryDetails = sortedEntries[index];
            final entry = entryDetails.entry;
            final category = entryDetails.category;

            final dateFormat = DateFormat('d.M.yy');
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
                  context.pushAddEntry(entryToEdit: entryDetails);
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
                ref.read(entryRepositoryProvider).deletePurchaseEntry(entry.id);
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
                btcCache: btcCache,
              ),
            );
          },
        ),
      ),
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
    required Map<String, double> btcCache,
  }) {
    final entry = entryDetails.entry;
    final product = entryDetails.product;
    final isLuxeMode = Theme.of(context).brightness == Brightness.dark;

    final content = ListTile(
      onTap: () => context.push('/home/product/${product.id}'),
      onLongPress: () => _showEntryActions(context, entryDetails, l10n),
      leading: StoreLogoWidget(
        storeName: entry.storeName,
        fallbackLetter: categoryName,
      ),
      title: Text(product.name,
          style:
              isLuxeMode ? const TextStyle(fontWeight: FontWeight.w600) : null),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(entry.purchaseDate)),
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
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isLuxeMode)
            TabularAmountText(
              _formatPrice(entry, settings),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            )
          else
            Text(
              _formatPrice(entry, settings),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          _buildUnitPriceLabel(entry, settings, btcCache),
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

  Future<void> _showEntryActions(
    BuildContext context,
    EntryWithDetails entryDetails,
    AppLocalizations l10n,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(l10n.productDetailViewAction),
                onTap: () => Navigator.of(sheetContext).pop('view'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.edit),
                onTap: () => Navigator.of(sheetContext).pop('edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.of(sheetContext).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'view':
        context.push('/home/product/${entryDetails.product.id}');
        break;
      case 'edit':
        context.pushAddEntry(entryToEdit: entryDetails);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.deleteEntryConfirm),
                content: Text(l10n.deleteEntryMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      l10n.delete,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (!confirmed || !context.mounted) return;
        await ref
            .read(entryRepositoryProvider)
            .deletePurchaseEntry(entryDetails.entry.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.entryDeleted)),
        );
        break;
    }
  }

  Widget _buildUnitPriceLabel(
    PurchaseEntry entry,
    AppSettings settings,
    Map<String, double> btcCache,
  ) {
    final unit = unitTypeFromString(entry.unit);
    if (unit == UnitType.count && entry.quantity == 1.0) {
      return const SizedBox.shrink();
    }
    String label;
    if (settings.isBitcoinMode) {
      final btcPrice =
          btcCache['${entry.purchaseDate.year}-${entry.purchaseDate.month}'];
      if (btcPrice != null && btcPrice > 0) {
        final normalizedFiat =
            unit.normalizedPrice(entry.price, entry.quantity);
        final sats = SatsConverter.fiatToSats(normalizedFiat, btcPrice);
        final displayUnit = unit.baseUnitLabel == 'g' ? 'kg' : 'l';
        label =
            '${NumberFormat('#,###').format(sats * 1000)} sats/$displayUnit';
      } else {
        label = '-';
      }
    } else {
      label = unit.formattedUnitPrice(
          entry.price, entry.quantity, settings.currency);
    }
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
    AsyncValue<List<String>> storesAsync,
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
              Text(sheetL10n.filterStore,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              storesAsync.when(
                data: (stores) {
                  return DropdownButtonFormField<String?>(
                    initialValue: filter.storeName,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(sheetL10n.filterAllStores),
                      ),
                      ...stores.map((s) => DropdownMenuItem<String?>(
                            value: s,
                            child: Text(s),
                          )),
                    ],
                    onChanged: (value) => ref
                        .read(historyFilterControllerProvider.notifier)
                        .setStore(value),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text(e.toString()),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(sheetL10n.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
