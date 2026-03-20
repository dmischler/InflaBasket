import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

class LuxuryDropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? labelText;
  final String? hintText;
  final bool isExpanded;
  final Widget? prefixIcon;
  final int? selectedItemBuilderIndex;

  const LuxuryDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.isExpanded = true,
    this.prefixIcon,
    this.selectedItemBuilderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBitcoinMode =
        Theme.of(context).primaryColor == AppColors.accentBtcMain;
    final accentColor =
        isBitcoinMode ? AppColors.accentBtcMain : AppColors.accentFiatMain;

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: isExpanded,
      selectedItemBuilder: selectedItemBuilderIndex != null
          ? (context) => items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: item.child,
                  ))
              .toList()
          : null,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      dropdownColor: colorScheme.surfaceContainerHighest,
      iconEnabledColor: colorScheme.onSurfaceVariant,
      iconDisabledColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }
}

class LuxuryDropdownButton<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final bool isExpanded;
  final String? underline;

  const LuxuryDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
    this.underline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButton<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: isExpanded,
      underline: underline != null
          ? Text(underline!, style: TextStyle(color: colorScheme.onSurface))
          : const SizedBox(),
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      dropdownColor: colorScheme.surfaceContainerHighest,
      iconEnabledColor: colorScheme.onSurfaceVariant,
    );
  }
}
