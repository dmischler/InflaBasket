import 'package:flutter/material.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/core/widgets/chart_overlay_filter_sheet.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class ChartHeader extends StatelessWidget {
  final List<ComparisonOverlayType> availableTypes;
  final ComparisonOverlayType? overlayType;
  final bool showCpi;
  final bool isLoading;
  final ValueChanged<ComparisonOverlayType> onOverlayTypeChanged;
  final VoidCallback onToggleCpi;

  const ChartHeader({
    super.key,
    required this.availableTypes,
    required this.overlayType,
    required this.showCpi,
    required this.isLoading,
    required this.onOverlayTypeChanged,
    required this.onToggleCpi,
  });

  String _overlayLabel(AppLocalizations l, ComparisonOverlayType overlayType) {
    return switch (overlayType) {
      ComparisonOverlayType.moneySupply => l.moneySupplyM2,
      ComparisonOverlayType.snbCoreInflation => l.coreInflationSnb,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (availableTypes.isEmpty) return const SizedBox.shrink();
    final displayType = availableTypes.contains(overlayType)
        ? overlayType!
        : availableTypes.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => ChartOverlayFilterSheet.show(
            context: context,
            availableTypes: availableTypes,
            selectedType: overlayType,
            showCpi: showCpi,
            isLoading: isLoading,
            onTypeSelected: onOverlayTypeChanged,
            onToggleCpi: onToggleCpi,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_overlayLabel(l, displayType)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Switch.adaptive(
          value: showCpi,
          onChanged: isLoading ? null : (_) => onToggleCpi(),
        ),
      ],
    );
  }
}
