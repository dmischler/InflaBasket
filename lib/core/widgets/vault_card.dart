import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

/// VaultCard represents the new Premium Dark Luxe Data Cards.
/// Uses the Vault Surface background and adds a metallic border or
/// active gradient border based on the current context theme.
class VaultCard extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const VaultCard({
    super.key,
    required this.child,
    this.isActive = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the active accent color based on the Theme context.
    // If the theme primary is True Gold, it's Bitcoin mode. Else, Fiat mode.
    final primaryColor = Theme.of(context).primaryColor;
    final isBitcoinMode = primaryColor == AppColors.accentBtcMain;

    // Choose the appropriate glow color based on the current mode
    final glowColor =
        isBitcoinMode ? AppColors.accentBtcGlow : AppColors.accentFiatGlow;

    final baseBorder = Border.all(color: AppColors.borderMetallic, width: 1);
    final activeBorder = Border.all(color: primaryColor, width: 2);

    final decoration = BoxDecoration(
      color: AppColors.bgVault,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: isActive ? activeBorder : baseBorder,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 4),
        )
      ],
      // If active, show the subtle gradient from the top based on the mode.
      gradient: isActive
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                glowColor,
                AppColors.bgVault,
              ],
              stops: const [0.0, 1.0],
            )
          : null,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
