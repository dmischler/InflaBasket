import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class ModesComparisonCards extends StatelessWidget {
  const ModesComparisonCards({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.bgVault : const Color(0xFFF5F5F5);
    final borderColor =
        isDark ? AppColors.borderMetallic : AppColors.borderLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeCard(
          title: l10n.onboardingModesFiatTitle,
          description: l10n.onboardingModesFiatDesc,
          priceExample: 'CHF 1.50',
          changePercentage: '+12%',
          isPositive: false,
          accentColor: AppColors.accentFiatMain,
          glowColor: AppColors.accentFiatGlow,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _ModeCard(
          title: l10n.onboardingModesBitcoinTitle,
          description: l10n.onboardingModesBitcoinDesc,
          priceExample: '2,847 sats',
          changePercentage: '-34%',
          isPositive: true,
          accentColor: AppColors.accentBtcMain,
          glowColor: AppColors.accentBtcGlow,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.priceExample,
    required this.changePercentage,
    required this.isPositive,
    required this.accentColor,
    required this.glowColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final String title;
  final String description;
  final String priceExample;
  final String changePercentage;
  final bool isPositive;
  final Color accentColor;
  final Color glowColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondary
        : AppColors.textDarkSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : null,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            glowColor.withValues(alpha: 0.08),
            surfaceColor,
          ],
          stops: const [0.0, 0.5],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  priceExample,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      changePercentage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
