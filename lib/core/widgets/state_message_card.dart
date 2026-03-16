import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class StateMessageCard extends StatelessWidget {
  const StateMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
    this.accentColor,
    this.animationAsset,
    this.animationHeight = 180,
    this.loop = true,
    this.autoplay = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;
  final Color? accentColor;
  final String? animationAsset;
  final double animationHeight;
  final bool loop;
  final bool autoplay;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final effectiveAnimationAsset = animationAsset ??
        (isLoading ? StateIllustrations.loadingMinimal : null);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (effectiveAnimationAsset != null)
                  _buildAnimation(
                    context,
                    color,
                    effectiveAnimationAsset,
                  )
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, color: color, size: 28),
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimation(
    BuildContext context,
    Color color,
    String assetPath,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedAsset = StateIllustrations.resolve(assetPath);
    final shouldRepeat = resolvedAsset.contains('error') ? false : loop;

    return Semantics(
      label: l10n.emptyStateAnimationDescription,
      child: SizedBox(
        height: animationHeight,
        child: Lottie.asset(
          resolvedAsset,
          height: animationHeight,
          fit: BoxFit.contain,
          repeat: shouldRepeat,
          animate: autoplay,
          errorBuilder: (context, error, stackTrace) => CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}
