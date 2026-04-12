import 'package:flutter/material.dart';

/// Ensures financial numbers are perfectly aligned tabularly.
class TabularAmountText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const TabularAmountText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    // If no style provided, get the default bodyLarge from theme.
    final baseStyle =
        style ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();

    // Use JetBrains Mono if available, fallback to default monospace.
    // Ensure font features force tabular numbering ("tnum").
    final tabularStyle = baseStyle.copyWith(
      fontFamily: 'JetBrains Mono',
      fontFamilyFallback: ['monospace'],
      fontFeatures: [
        ...(baseStyle.fontFeatures ?? []),
        const FontFeature.tabularFigures(),
      ],
    );

    return Text(
      text,
      style: tabularStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
