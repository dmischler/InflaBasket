import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool collapsible;
  final bool initiallyExpanded;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (collapsible) {
      return Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              childrenPadding: EdgeInsets.zero,
              initiallyExpanded: initiallyExpanded,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              trailing: Icon(
                Icons.expand_more,
                color: colorScheme.onSurfaceVariant,
              ),
              children: [
                const Divider(height: 1),
                ...children,
              ],
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const Divider(height: 1),
          ...children,
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
