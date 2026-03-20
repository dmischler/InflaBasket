import 'package:flutter/material.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class ChartOverlayFilterSheet extends StatelessWidget {
  final List<ComparisonOverlayType> availableTypes;
  final ComparisonOverlayType? selectedType;
  final bool showCpi;
  final bool isLoading;
  final ValueChanged<ComparisonOverlayType> onTypeSelected;
  final VoidCallback onToggleCpi;

  const ChartOverlayFilterSheet({
    super.key,
    required this.availableTypes,
    required this.selectedType,
    required this.showCpi,
    required this.isLoading,
    required this.onTypeSelected,
    required this.onToggleCpi,
  });

  static Future<void> show({
    required BuildContext context,
    required List<ComparisonOverlayType> availableTypes,
    required ComparisonOverlayType? selectedType,
    required bool showCpi,
    required bool isLoading,
    required ValueChanged<ComparisonOverlayType> onTypeSelected,
    required VoidCallback onToggleCpi,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => ChartOverlayFilterSheet(
        availableTypes: availableTypes,
        selectedType: selectedType,
        showCpi: showCpi,
        isLoading: isLoading,
        onTypeSelected: onTypeSelected,
        onToggleCpi: onToggleCpi,
      ),
    );
  }

  String _overlayLabel(AppLocalizations l, ComparisonOverlayType type) {
    return switch (type) {
      ComparisonOverlayType.moneySupply => l.moneySupplyM2,
      ComparisonOverlayType.snbCoreInflation => l.coreInflationSnb,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.chartOverlayType,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (availableTypes.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTypes.map((type) {
                  return ChoiceChip(
                    label: Text(_overlayLabel(l, type)),
                    selected: type == selectedType,
                    onSelected: availableTypes.length < 2
                        ? null
                        : (_) {
                            onTypeSelected(type);
                            Navigator.pop(context);
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.showNationalAverage,
                    style: Theme.of(context).textTheme.bodyLarge),
                Switch.adaptive(
                  value: showCpi,
                  onChanged: isLoading ? null : (_) => onToggleCpi(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
