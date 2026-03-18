import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/core/mixins/chart_touch_state.dart';
import 'package:inflabasket/core/models/unit.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/theme/chart_animations.dart';
import 'package:inflabasket/core/utils/sats_converter.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/widgets/tabular_amount_text.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/dashboard/application/product_detail_provider.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/entry_management/presentation/autocomplete_field.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with ChartTouchState {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _categoryFocusNode = FocusNode();
  final _storeController = TextEditingController();

  bool _isEditingDetails = false;
  bool _isEditingCategorySearch = false;
  String? _selectedCategoryName;
  ProductDetailRange _range = ProductDetailRange.all;

  @override
  void initState() {
    super.initState();
    _categoryFocusNode.addListener(() {
      if (_categoryFocusNode.hasFocus) return;
      if (!_isEditingCategorySearch || _selectedCategoryName == null) return;
      setState(() {
        _isEditingCategorySearch = false;
        _categoryController.text = CategoryLocalization.displayNameForContext(
          context,
          _selectedCategoryName!,
        );
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _categoryFocusNode.dispose();
    _storeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final productAsync =
        ref.watch(productWithCategoryProvider(widget.productId));
    final entriesAsync = ref.watch(productEntriesProvider(widget.productId));
    final actionState =
        ref.watch(productDetailControllerProvider(widget.productId));
    final categoriesAsync = ref.watch(categoriesProvider);
    final btcCacheAsync = settings.isBitcoinMode
        ? ref.watch(btcPriceCacheProvider)
        : const AsyncData<Map<String, double>>(<String, double>{});

    final isBusy = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: productAsync.when(
          data: (productData) => Text(
            productData?.product.name ?? l10n.productDetailTitle,
          ),
          loading: () => Text(l10n.productDetailTitle),
          error: (_, __) => Text(l10n.productDetailTitle),
        ),
        actions: [
          IconButton(
            tooltip: _isEditingDetails ? l10n.save : l10n.edit,
            onPressed: isBusy
                ? null
                : () async {
                    if (_isEditingDetails) {
                      await _saveProductDetails(
                        context,
                        l10n,
                        categoriesAsync.valueOrNull ?? const [],
                      );
                    } else {
                      setState(() => _isEditingDetails = true);
                    }
                  },
            icon: Icon(_isEditingDetails ? Icons.check : Icons.settings),
          ),
          IconButton(
            tooltip: l10n.productDetailDeleteProduct,
            onPressed: isBusy
                ? null
                : () => _confirmDeleteProduct(context, l10n, entriesAsync),
            color: Colors.red,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => StateMessageCard(
          icon: Icons.inventory_2_outlined,
          animationAsset: StateIllustrations.loadingMinimal,
          title: l10n.loading,
          message: l10n.loading,
          isLoading: true,
        ),
        error: (error, _) => StateMessageCard(
          icon: Icons.error_outline,
          animationAsset: StateIllustrations.error,
          loop: false,
          title: l10n.errorGeneric,
          message: error.toString(),
        ),
        data: (productData) {
          if (productData == null) {
            return StateMessageCard(
              icon: Icons.inventory_2_outlined,
              animationAsset: StateIllustrations.emptyGeneral,
              title: l10n.productDetailMissingTitle,
              message: l10n.productDetailMissingMessage,
            );
          }

          _seedControllers(
            productData,
            facts: buildProductDetailFacts(
              entriesAsync.valueOrNull ?? const <EntryWithDetails>[],
              productData.product,
            ),
            context: context,
          );

          return entriesAsync.when(
            loading: () => StateMessageCard(
              icon: Icons.receipt_long,
              animationAsset: StateIllustrations.loadingMinimal,
              title: l10n.loading,
              message: l10n.loading,
              isLoading: true,
            ),
            error: (error, _) => StateMessageCard(
              icon: Icons.error_outline,
              animationAsset: StateIllustrations.error,
              loop: false,
              title: l10n.errorGeneric,
              message: error.toString(),
            ),
            data: (entries) {
              final btcCache =
                  btcCacheAsync.valueOrNull ?? const <String, double>{};
              final facts =
                  buildProductDetailFacts(entries, productData.product);
              final inflation = buildProductInflation(
                entries: entries,
                product: productData.product,
                range: _range,
                isBitcoinMode: settings.isBitcoinMode,
                btcPriceCache: btcCache,
              );
              final points = buildProductPricePoints(
                entries: entries,
                product: productData.product,
                range: _range,
                isBitcoinMode: settings.isBitcoinMode,
                btcPriceCache: btcCache,
              );
              final availableRanges = _availableRanges(entries);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProductMetaCard(
                    context,
                    l10n,
                    productData,
                    facts,
                  ),
                  const SizedBox(height: 16),
                  _buildFactsCard(context, l10n, facts),
                  const SizedBox(height: 16),
                  _buildInflationCard(
                      context, l10n, inflation, settings.isBitcoinMode),
                  const SizedBox(height: 16),
                  _buildRangeSelector(context, l10n, availableRanges),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    context,
                    l10n,
                    points,
                    settings,
                    _range,
                  ),
                  const SizedBox(height: 16),
                  _buildHistorySection(
                    context,
                    l10n,
                    entries,
                    settings,
                    btcCache,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _seedControllers(
    ProductWithCategory productData, {
    required ProductDetailFacts facts,
    required BuildContext context,
  }) {
    if (_isEditingDetails) return;
    if (_nameController.text == productData.product.name &&
        _selectedCategoryName == productData.category.name &&
        _storeController.text == facts.canonicalStore) {
      return;
    }

    _nameController.text = productData.product.name;
    _selectedCategoryName = productData.category.name;
    _categoryController.text = CategoryLocalization.displayNameForContext(
      context,
      productData.category.name,
    );
    _storeController.text = facts.canonicalStore;
  }

  List<ProductDetailRange> _availableRanges(List<EntryWithDetails> entries) {
    if (entries.isEmpty) return ProductDetailRange.values;
    final oldest = entries
        .map((e) => e.entry.purchaseDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();
    final difference = now.difference(oldest).inDays;

    final ranges = <ProductDetailRange>[];
    if (difference >= 30) ranges.add(ProductDetailRange.oneMonth);
    if (difference >= 90) ranges.add(ProductDetailRange.threeMonths);
    if (difference >= 180) ranges.add(ProductDetailRange.sixMonths);
    if (difference >= 365) ranges.add(ProductDetailRange.oneYear);
    ranges.add(ProductDetailRange.all);

    if (!ranges.contains(_range)) {
      _range = ProductDetailRange.all;
    }

    return ranges;
  }

  Widget _buildProductMetaCard(
    BuildContext context,
    AppLocalizations l10n,
    ProductWithCategory productData,
    ProductDetailFacts facts,
  ) {
    final theme = Theme.of(context);
    final isLuxeMode = theme.scaffoldBackgroundColor == AppColors.bgVoid;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableField(
          context: context,
          label: l10n.product,
          child: _isEditingDetails
              ? TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  textInputAction: TextInputAction.done,
                )
              : Text(
                  _nameController.text,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          context: context,
          label: l10n.category,
          child: _isEditingDetails
              ? TypeAheadField<String>(
                  controller: _categoryController,
                  focusNode: _categoryFocusNode,
                  suggestionsCallback: (search) => ref
                      .read(entryRepositoryProvider)
                      .searchCategoryNames(search),
                  builder: (context, controller, focusNode) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onTap: _beginCategorySearch,
                    );
                  },
                  itemBuilder: (context, itemData) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        CategoryLocalization.displayNameForContext(
                          context,
                          itemData,
                        ),
                      ),
                    );
                  },
                  onSelected: (selection) {
                    _categoryController.text =
                        CategoryLocalization.displayNameForContext(
                      context,
                      selection,
                    );
                    setState(() {
                      _selectedCategoryName = selection;
                      _isEditingCategorySearch = false;
                    });
                  },
                )
              : Text(
                  CategoryLocalization.displayNameForContext(
                    context,
                    _selectedCategoryName ?? productData.category.name,
                  ),
                  style: theme.textTheme.titleMedium,
                ),
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          context: context,
          label: l10n.store,
          child: _isEditingDetails
              ? AsyncAutocompleteField(
                  labelText: l10n.store,
                  controller: _storeController,
                  suggestionsCallback:
                      ref.read(entryRepositoryProvider).searchStoreNames,
                )
              : Text(
                  facts.canonicalStore.isEmpty
                      ? l10n.unknownStore
                      : facts.canonicalStore,
                  style: theme.textTheme.titleMedium,
                ),
        ),
      ],
    );

    return isLuxeMode
        ? VaultCard(child: content)
        : Card(
            child: Padding(padding: const EdgeInsets.all(16), child: content));
  }

  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildFactsCard(
    BuildContext context,
    AppLocalizations l10n,
    ProductDetailFacts facts,
  ) {
    final dateFormat = DateFormat.yMMMd();
    final values = [
      _FactTile(label: l10n.productDetailEntries, value: '${facts.entryCount}'),
      _FactTile(
        label: l10n.productDetailFirstPurchase,
        value: facts.firstPurchase == null
            ? '-'
            : dateFormat.format(facts.firstPurchase!),
      ),
      _FactTile(
        label: l10n.productDetailLatestPurchase,
        value: facts.latestPurchase == null
            ? '-'
            : dateFormat.format(facts.latestPurchase!),
      ),
    ];

    final body = Row(
      children: values
          .map(
            (tile) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tile.label,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(tile.value,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );

    return _wrapCard(context, body);
  }

  Widget _buildInflationCard(
    BuildContext context,
    AppLocalizations l10n,
    ProductInflationResult? inflation,
    bool isBitcoinMode,
  ) {
    final value = inflation?.inflationPercent ?? 0.0;
    final color = value >= 0 ? Colors.red : Colors.green;
    final title =
        isBitcoinMode ? l10n.satsInflation : l10n.productDetailInflation;
    final body = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (inflation?.isPartialPeriod == true)
              Text(
                l10n.productDetailPartialPeriod,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        Icon(
          value >= 0 ? Icons.trending_up : Icons.trending_down,
          color: color,
          size: 40,
        ),
      ],
    );

    return _wrapCard(context, body);
  }

  Widget _buildRangeSelector(
    BuildContext context,
    AppLocalizations l10n,
    List<ProductDetailRange> ranges,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ranges
          .map(
            (range) => ChoiceChip(
              label: Text(_rangeLabel(l10n, range)),
              selected: _range == range,
              onSelected: (_) => setState(() => _range = range),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    AppLocalizations l10n,
    List<ProductPricePoint> points,
    AppSettings settings,
    ProductDetailRange range,
  ) {
    if (points.length < 2) {
      return _wrapCard(
        context,
        SizedBox(
          height: 200,
          child: Center(
            child: Text(l10n.categoryNoChartData),
          ),
        ),
      );
    }

    final spots = points
        .map(
          (point) => FlSpot(
            point.date.millisecondsSinceEpoch.toDouble(),
            point.value,
          ),
        )
        .toList();
    final minY = spots.map((spot) => spot.y).reduce(min);
    final maxY = spots.map((spot) => spot.y).reduce(max);
    final chartMinY = minY == maxY ? minY * 0.9 : minY;
    final chartMaxY = minY == maxY ? maxY * 1.1 : maxY;
    final color = Theme.of(context).colorScheme.primary;
    final shouldAnimate = animationsEnabled(
      context,
      pointCount: points.length,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowOpacity = isDark ? 0.6 : 0.35;

    final chart = SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.18),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                maxIncluded: false,
                minIncluded: false,
                getTitlesWidget: (value, meta) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return SideTitleWidget(
                    meta: meta,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(
                      meta,
                      distanceFromEdge: 8,
                      enabled: true,
                    ),
                    child: Text(
                      DateFormat(_dateFormat(range)).format(date),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                  );
                },
                interval: _dynamicTickInterval(points),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent || response?.lineBarSpots == null) {
                return;
              }
              if (!handleTouchDebounce()) return;
              HapticFeedback.lightImpact();
            },
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                final indicatorColor = barData.color ?? color;
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: indicatorColor.withValues(alpha: 0.6),
                    strokeWidth: 2,
                    dashArray: [4, 3],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, spotIndex) {
                      return GlowDotPainter(
                        color: indicatorColor,
                        radius: 8,
                        glowColor:
                            indicatorColor.withValues(alpha: glowOpacity),
                        glowRadius: 12,
                      );
                    },
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final point = points.reduce((a, b) {
                    final da =
                        (a.date.millisecondsSinceEpoch.toDouble() - spot.x)
                            .abs();
                    final db =
                        (b.date.millisecondsSinceEpoch.toDouble() - spot.x)
                            .abs();
                    return da <= db ? a : b;
                  });
                  return LineTooltipItem(
                    '${DateFormat.yMMMd().format(point.date)}\n${_formatChartValue(point, settings)}',
                    TextStyle(
                      color: spot.bar.color,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: shouldAnimate
            ? ChartAnimations.entranceDurationFor(points.length)
            : Duration.zero,
        curve: ChartAnimations.entranceCurve,
      ),
    );

    return _wrapCard(context, chart);
  }

  Widget _buildHistorySection(
    BuildContext context,
    AppLocalizations l10n,
    List<EntryWithDetails> entries,
    AppSettings settings,
    Map<String, double> btcCache,
  ) {
    final sorted = List<EntryWithDetails>.from(entries)
      ..sort((a, b) => b.entry.purchaseDate.compareTo(a.entry.purchaseDate));

    if (sorted.isEmpty) {
      return _wrapCard(
        context,
        StateMessageCard(
          icon: Icons.receipt_long,
          animationAsset: StateIllustrations.emptyGeneral,
          title: l10n.productDetailNoEntriesTitle,
          message: l10n.productDetailNoEntriesMessage,
        ),
      );
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.productDetailPriceHistory,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final entryDetails = sorted[index];
            final entry = entryDetails.entry;
            return Dismissible(
              key: ValueKey('product-detail-entry-${entry.id}'),
              direction: DismissDirection.horizontal,
              background: Container(
                color: Theme.of(context).colorScheme.primary,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  context.push(
                    '/home/add',
                    extra: EntryEditRequest(
                      entry: entryDetails,
                      lockSharedFields: true,
                    ),
                  );
                  return false;
                }

                return await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.deleteEntryConfirm),
                        content: Text(l10n.deleteEntryMessage),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(
                              l10n.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ) ??
                    false;
              },
              onDismissed: (_) async {
                await ref
                    .read(productDetailControllerProvider(widget.productId)
                        .notifier)
                    .deleteEntry(entry.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.entryDeleted)),
                );
              },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat.yMMMd().format(entry.purchaseDate)),
                subtitle: Text(
                  '${entry.storeName} • ${_unitLabel(entry, settings, btcCache, entryDetails)}',
                ),
                trailing: _buildTrailingPrice(
                  context,
                  entryDetails,
                  settings,
                  btcCache,
                ),
              ),
            );
          },
        ),
      ],
    );

    return _wrapCard(context, body);
  }

  Widget _buildTrailingPrice(
    BuildContext context,
    EntryWithDetails entryDetails,
    AppSettings settings,
    Map<String, double> btcCache,
  ) {
    final text = settings.isBitcoinMode
        ? () {
            final sats = normalizedSatsValueForEntry(entryDetails, btcCache);
            if (sats == null) return '-';
            return SatsConverter.formatSats(sats);
          }()
        : NumberFormat.simpleCurrency(name: settings.currency)
            .format(entryDetails.entry.price);
    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;

    return isLuxeMode
        ? TabularAmountText(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
        : Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
  }

  Widget _wrapCard(BuildContext context, Widget child) {
    final isLuxeMode =
        Theme.of(context).scaffoldBackgroundColor == AppColors.bgVoid;
    if (isLuxeMode) {
      return VaultCard(child: child);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  void _beginCategorySearch() {
    if (_selectedCategoryName == null || _isEditingCategorySearch) return;
    final displayName = CategoryLocalization.displayNameForContext(
      context,
      _selectedCategoryName!,
    );
    if (_categoryController.text == displayName) {
      setState(() {
        _isEditingCategorySearch = true;
        _categoryController.clear();
      });
    }
  }

  Future<void> _saveProductDetails(
    BuildContext context,
    AppLocalizations l10n,
    List<Category> categories,
  ) async {
    final name = _nameController.text.trim();
    final store = _storeController.text.trim();
    final categoryName = _selectedCategoryName;

    if (name.isEmpty || store.isEmpty || categoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fieldRequired)),
      );
      return;
    }

    final category =
        categories.where((c) => c.name == categoryName).firstOrNull;
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fieldRequired)),
      );
      return;
    }

    final repo = ref.read(entryRepositoryProvider);
    final hasConflict = await repo.hasOtherProductWithName(
      name: name,
      excludedProductId: widget.productId,
    );
    if (hasConflict && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productDetailDuplicateNameMessage)),
      );
      return;
    }

    try {
      await ref
          .read(productDetailControllerProvider(widget.productId).notifier)
          .saveDetails(
            productName: name,
            categoryId: category.id,
            storeName: store,
          );
      if (!context.mounted) return;
      setState(() => _isEditingDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.entrySaved)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.entrySaveError(error.toString()))),
      );
    }
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<EntryWithDetails>> entriesAsync,
  ) async {
    final entries = entriesAsync.valueOrNull ?? const <EntryWithDetails>[];
    final productData =
        ref.read(productWithCategoryProvider(widget.productId)).valueOrNull;
    if (productData == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.productDetailDeleteProduct),
            content: Text(
              l10n.productDetailDeleteProductMessage(
                productData.product.name,
                entries.length,
              ),
            ),
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

    if (!confirmed) return;

    await ref
        .read(productDetailControllerProvider(widget.productId).notifier)
        .deleteProduct();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.productDetailDeleted)),
    );
    context.pop();
  }

  String _formatChartValue(ProductPricePoint point, AppSettings settings) {
    return unitTypeFromString(point.entry.entry.unit)
        .formattedUnitPriceFromNormalized(
      point.value,
      settings.isBitcoinMode ? 'sats' : settings.currency,
    );
  }

  String _unitLabel(
    PurchaseEntry entry,
    AppSettings settings,
    Map<String, double> btcCache,
    EntryWithDetails details,
  ) {
    final unit = unitTypeFromString(entry.unit);
    if (settings.isBitcoinMode) {
      final sats = normalizedSatsValueForEntry(details, btcCache);
      if (sats == null) return '-';
      return unit.formattedUnitPriceFromNormalized(
        sats.toDouble(),
        'sats',
      );
    }
    return unit.formattedUnitPrice(
        entry.price, entry.quantity, settings.currency);
  }

  String _rangeLabel(AppLocalizations l10n, ProductDetailRange range) {
    return switch (range) {
      ProductDetailRange.oneMonth => l10n.productDetailRange1m,
      ProductDetailRange.threeMonths => l10n.productDetailRange3m,
      ProductDetailRange.sixMonths => l10n.productDetailRange6m,
      ProductDetailRange.oneYear => l10n.timeRange1y,
      ProductDetailRange.all => l10n.timeRangeAll,
    };
  }

  String _dateFormat(ProductDetailRange range) {
    return switch (range) {
      ProductDetailRange.oneMonth => 'dd MMM',
      ProductDetailRange.threeMonths => 'MMM',
      ProductDetailRange.sixMonths => 'MMM',
      ProductDetailRange.oneYear => 'MMM',
      ProductDetailRange.all => 'MMM yy',
    };
  }

  // Helper to calculate dynamic interval based on actual data
  double _dynamicTickInterval(List<ProductPricePoint> points) {
    if (points.length < 2) {
      return const Duration(days: 30).inMilliseconds.toDouble();
    }

    final firstDate = points.first.date;
    final lastDate = points.last.date;
    final rangeDays = lastDate.difference(firstDate).inDays;
    if (rangeDays <= 0) {
      return const Duration(days: 30).inMilliseconds.toDouble();
    }

    // Aim for 4-6 labels max
    const targetLabels = 5;
    final intervalDays = (rangeDays / targetLabels).ceil();

    // Round to nice intervals (never less than 7 days)
    final niceDays = [7, 14, 21, 28, 56, 84, 112, 168, 252, 365]
        .firstWhere((d) => d >= intervalDays, orElse: () => 365);

    return Duration(days: niceDays).inMilliseconds.toDouble();
  }
}

class _FactTile {
  const _FactTile({required this.label, required this.value});

  final String label;
  final String value;
}
