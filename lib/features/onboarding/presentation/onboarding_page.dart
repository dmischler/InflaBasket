import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    this.animationAsset,
    this.icon,
    required this.title,
    required this.subtitle,
    this.content,
    this.iconBackgroundColor,
    this.iconColor,
  }) : assert(animationAsset != null || icon != null,
            'Either animationAsset or icon must be provided');

  final String? animationAsset;
  final IconData? icon;
  final String title;
  final String subtitle;
  final Widget? content;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedAnimationAsset = animationAsset != null
        ? StateIllustrations.resolve(animationAsset!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          if (resolvedAnimationAsset != null)
            Lottie.asset(
              resolvedAnimationAsset,
              height: 200,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(
                context,
                colorScheme,
              ),
            )
          else
            _buildFallbackIcon(context, colorScheme),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          if (content != null) ...[
            const SizedBox(height: 32),
            content!,
          ],
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = iconBackgroundColor ??
        (isDark
            ? AppColors.accentFiatGlow
            : colorScheme.primary.withValues(alpha: 0.1));
    final fgColor = iconColor ?? colorScheme.primary;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: (iconColor ?? AppColors.accentFiatMain)
                      .withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon!,
        size: 56,
        color: fgColor,
      ),
    );
  }
}
