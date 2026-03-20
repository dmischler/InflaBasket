import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/api/cpi_client.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/shimmer/chart_skeleton.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/core/widgets/inflation_summary_card.dart';
import 'package:inflabasket/core/widgets/time_range_selector.dart';
import 'package:inflabasket/core/widgets/chart_header.dart';
import 'package:inflabasket/core/widgets/inflation_line_chart.dart';
import 'package:inflabasket/core/widgets/inflation_list_view.dart';
import 'package:inflabasket/features/dashboard/application/inflation_providers.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(entriesWithDetailsProvider);
    final settings = ref.watch(settingsControllerProvider);
    final isBitcoinMode = settings.isBitcoinMode;
    final entries = entriesAsync.valueOrNull ?? const <EntryWithDetails>[];
    final historySatsAsync = isBitcoinMode
        ? ref.watch(filteredDynamicIndexSatsProvider)
        : const AsyncData<List<MonthlyIndex>>(<MonthlyIndex>[]);
    final allHistorySatsAsync = isBitcoinMode
        ? ref.watch(dynamicLaspeyresIndexSatsProvider)
        : const AsyncData<List<MonthlyIndex>>(<MonthlyIndex>[]);
    final topInflatorsSatsAsync = isBitcoinMode
        ? ref.watch(overallItemInflationListSatsProvider)
        : const AsyncData<List<ItemInflationSats>>(<ItemInflationSats>[]);
    final yearlySummarySatsAsync = isBitcoinMode
        ? ref.watch(overallYearlyInflationSummarySatsProvider)
        : const AsyncData<YearlyInflationSummary>(
            YearlyInflationSummary.empty());
    final bitcoinHistory = historySatsAsync.valueOrNull;
    final bitcoinAllHistory = allHistorySatsAsync.valueOrNull;
    final bitcoinTopInflators = topInflatorsSatsAsync.valueOrNull;
    final bitcoinYearlySummary = yearlySummarySatsAsync.valueOrNull;

    final hasEntriesData = entriesAsync.valueOrNull != null;
    final isInitialLoading = !hasEntriesData && entriesAsync.isLoading;
    final bitcoinLoading = isBitcoinMode &&
        ((historySatsAsync.isLoading && bitcoinHistory == null) ||
            (allHistorySatsAsync.isLoading && bitcoinAllHistory == null) ||
            (topInflatorsSatsAsync.isLoading && bitcoinTopInflators == null) ||
            (yearlySummarySatsAsync.isLoading && bitcoinYearlySummary == null));

    final coreError = entriesAsync.hasError && !hasEntriesData
        ? entriesAsync.error
        : !isBitcoinMode || bitcoinLoading
            ? null
            : historySatsAsync.hasError && bitcoinHistory == null
                ? historySatsAsync.error
                : allHistorySatsAsync.hasError && bitcoinAllHistory == null
                    ? allHistorySatsAsync.error
                    : topInflatorsSatsAsync.hasError &&
                            bitcoinTopInflators == null
                        ? topInflatorsSatsAsync.error
                        : yearlySummarySatsAsync.hasError &&
                                bitcoinYearlySummary == null
                            ? yearlySummarySatsAsync.error
                            : null;

    final loadingChild = isInitialLoading
        ? const ChartSkeleton.overview(key: ValueKey('overview-loading'))
        : coreError != null
            ? StateMessageCard(
                key: const ValueKey('overview-error'),
                icon: Icons.error_outline,
                animationAsset: StateIllustrations.error,
                loop: false,
                title: l.errorGeneric,
                message: coreError.toString(),
              )
            : null;

    if (loadingChild != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: loadingChild,
      );
    }

    final fiatYearlySummary = ref.watch(overallYearlyInflationSummaryProvider);
    final fiatHistory = ref.watch(filteredDynamicIndexProvider);
    final fiatTopInflators = ref.watch(overallItemInflationListProvider);
    final displayBitcoinData =
        isBitcoinMode && !bitcoinLoading && coreError == null;

    final yearlySummary = displayBitcoinData
        ? bitcoinYearlySummary ?? const YearlyInflationSummary.empty()
        : fiatYearlySummary;

    final history = displayBitcoinData
        ? bitcoinHistory ?? const <MonthlyIndex>[]
        : fiatHistory;
    final showCpi = ref.watch(showCpiOverlayProvider);
    final overlayType = ref.watch(effectiveComparisonOverlayTypeProvider);
    final overlayAsync = ref.watch(comparisonOverlayDataProvider);
    final availableTypes = availableComparisonOverlayTypes(settings.currency);
    final hasOverlaySource = availableTypes.isNotEmpty;
    final overlayPoints =
        overlayAsync.valueOrNull ?? const <ComparisonDataPoint>[];
    final hasOverlayData = overlayPoints.isNotEmpty;
    final isLuxeMode = Theme.of(context).brightness == Brightness.dark;
    final timeFilter = ref.watch(chartTimeFilterControllerProvider);
    final firstDataPoint = entries.isNotEmpty
        ? entries
            .map<DateTime>((entry) => entry.entry.purchaseDate)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final availableTimeRangeOptions = availableTimeRanges(entries);
    final selectedRange = resolveTimeRangeSelection(
      timeFilter,
      availableTimeRangeOptions,
    );

    final topInflators = displayBitcoinData
        ? bitcoinTopInflators ?? const <ItemInflationSats>[]
        : fiatTopInflators;

    return SingleChildScrollView(
      key: const ValueKey('overview-content'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InflationSummaryCard(
            summary: yearlySummary,
            title: l.overviewTitle,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TimeRangeSelector(
                timeFilter: timeFilter,
                selectedRange: selectedRange,
                availableOptions: availableTimeRangeOptions,
                firstDataPoint: firstDataPoint,
                onRangeChanged: (range) => ref
                    .read(chartTimeFilterControllerProvider.notifier)
                    .setRange(range),
                onCustomRangeRequested: (start, end) => ref
                    .read(chartTimeFilterControllerProvider.notifier)
                    .setCustomRange(start, end),
              ),
              ChartHeader(
                availableTypes: availableTypes,
                overlayType: overlayType,
                showCpi: showCpi,
                isLoading: overlayAsync.isLoading,
                onOverlayTypeChanged: (type) => ref
                    .read(selectedComparisonOverlayTypeProvider.notifier)
                    .set(type),
                onToggleCpi: () =>
                    ref.read(showCpiOverlayProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InflationLineChart(
            history: history,
            showCpi: showCpi,
            overlayPoints: overlayPoints,
            timeRange: selectedRange,
          ),
          if (showCpi && hasOverlaySource) ...[
            const SizedBox(height: 8),
            _buildOverlayStatus(context, l, overlayAsync, hasOverlayData),
          ],
          if (showCpi && hasOverlayData && overlayType != null) ...[
            const SizedBox(height: 8),
            _buildChartLegend(context, l, overlayType, isLuxeMode),
          ],
          const SizedBox(height: 24),
          Text(l.overviewTopInflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          InflationListView(
            items: displayBitcoinData
                ? (topInflators as List<ItemInflationSats>).toInflationList()
                : (topInflators as List<ItemInflation>).toInflationList(),
            isBitcoinMode: displayBitcoinData,
            settings: settings,
            isInflatorsList: true,
          ),
          const SizedBox(height: 24),
          Text(l.overviewTopDeflators,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          InflationListView(
            items: displayBitcoinData
                ? (topInflators as List<ItemInflationSats>).toInflationList()
                : (topInflators as List<ItemInflation>).toInflationList(),
            isBitcoinMode: displayBitcoinData,
            settings: settings,
            isInflatorsList: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayStatus(BuildContext context, AppLocalizations l,
      AsyncValue<List<ComparisonDataPoint>> overlayAsync, bool hasOverlayData) {
    if (overlayAsync.isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l.loading,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
    if (!hasOverlayData) {
      return Text(
        l.comparisonLoadError,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      );
    }
    return const SizedBox.shrink();
  }

  void _showOverlaySourceInfo(
    BuildContext context,
    AppLocalizations l,
    ComparisonOverlayType overlayType,
    String currency,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overlayType == ComparisonOverlayType.snbCoreInflation
                    ? l.cpiSourceTitle
                    : l.moneySupplySourceTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                _overlaySourceDescription(l, overlayType, currency),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  String _overlaySourceDescription(
    AppLocalizations l,
    ComparisonOverlayType overlayType,
    String currency,
  ) {
    return switch (overlayType) {
      ComparisonOverlayType.moneySupply => switch (currency) {
          'CHF' => l.moneySupplySourceChfDescription,
          'EUR' => l.moneySupplySourceEurDescription,
          'USD' => l.moneySupplySourceUsdDescription,
          'GBP' => l.moneySupplySourceGbpDescription,
          _ => l.moneySupplySourceUnavailableDescription,
        },
      ComparisonOverlayType.snbCoreInflation => l.cpiSourceChfDescription,
    };
  }

  Widget _buildChartLegend(BuildContext context, AppLocalizations l,
      ComparisonOverlayType overlayType, bool isLuxeMode) {
    return Row(
      children: [
        _legendDot(Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(l.yourInflation, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 16),
        _legendDot(isLuxeMode
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Colors.orange),
        const SizedBox(width: 4),
        Text(_overlayLabel(l, overlayType),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _overlayLabel(AppLocalizations l, ComparisonOverlayType overlayType) {
    return switch (overlayType) {
      ComparisonOverlayType.moneySupply => l.moneySupplyM2,
      ComparisonOverlayType.snbCoreInflation => l.coreInflationSnb,
    };
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
