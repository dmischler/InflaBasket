import 'package:flutter/material.dart';

enum ActionRowVariant { navigation, action, toggle, dropdown }

class ActionRow extends StatelessWidget {
  final ActionRowVariant variant;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final VoidCallback? onTap;

  const ActionRow({
    super.key,
    required this.variant,
    required this.title,
    this.icon,
    this.iconBackgroundColor,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.toggleValue,
    this.onToggleChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget leadingIcon;
    if (icon != null) {
      leadingIcon = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBackgroundColor ?? colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? colorScheme.onSurfaceVariant,
          size: 20,
        ),
      );
    } else {
      leadingIcon = const SizedBox.shrink();
    }

    switch (variant) {
      case ActionRowVariant.navigation:
        return ListTile(
          leading: leadingIcon,
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: trailing ??
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
          onTap: onTap,
        );

      case ActionRowVariant.action:
        return ListTile(
          leading: leadingIcon,
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: trailing,
          onTap: onTap,
        );

      case ActionRowVariant.toggle:
        return SwitchListTile.adaptive(
          secondary: leadingIcon,
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          value: toggleValue ?? false,
          onChanged: onToggleChanged,
        );

      case ActionRowVariant.dropdown:
        return ListTile(
          leading: leadingIcon,
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: trailing,
          onTap: onTap,
        );
    }
  }
}
