import 'package:flutter/material.dart';
import 'package:inflabasket/core/api/cpi_provider.dart';
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overlayType != null)
          DropdownButtonHideUnderline(
            child: DropdownButton<ComparisonOverlayType>(
              value: overlayType,
              borderRadius: BorderRadius.circular(12),
              items: availableTypes
                  .map(
                    (type) => DropdownMenuItem<ComparisonOverlayType>(
                      value: type,
                      child: Text(_overlayLabel(l, type)),
                    ),
                  )
                  .toList(),
              onChanged: availableTypes.length < 2
                  ? null
                  : (value) {
                      if (value == null) return;
                      onOverlayTypeChanged(value);
                    },
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
