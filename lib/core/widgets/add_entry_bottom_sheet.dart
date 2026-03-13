import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inflabasket/features/entry_management/presentation/add_entry_screen.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class AddEntryBottomSheet extends StatelessWidget {
  const AddEntryBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const AddEntryBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop =
        !Platform.isAndroid && !Platform.isIOS && !Platform.isFuchsia;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _OptionRow(
              icon: Icons.edit,
              iconBackgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: l10n.manual,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEntryScreen(),
                  ),
                );
              },
            ),
            Divider(height: 1, indent: 72),
            _OptionRow(
              icon: Icons.qr_code,
              iconBackgroundColor: colorScheme.secondaryContainer,
              iconColor: colorScheme.onSecondaryContainer,
              title: l10n.barcode,
              isDisabled: isDesktop,
              onTap: isDesktop
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      GoRouter.of(context).push('/barcode');
                    },
            ),
            Divider(height: 1, indent: 72),
            _OptionRow(
              icon: Icons.qr_code_scanner,
              iconBackgroundColor: colorScheme.tertiaryContainer,
              iconColor: colorScheme.onTertiaryContainer,
              title: l10n.scannerOption,
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                _showScannerChoice(context);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l10n.cancel.toUpperCase()),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showScannerChoice(BuildContext context) {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              context.push('/scanner', extra: ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              context.push('/scanner', extra: ImageSource.gallery);
            },
            child: const Text('Photo Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _OptionRow({
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color:
              isDisabled ? colorScheme.onSurface.withValues(alpha: 0.5) : null,
        ),
      ),
      trailing: trailing ??
          (isDisabled
              ? Icon(
                  Icons.computer,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                )
              : Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                )),
      enabled: !isDisabled,
      onTap: onTap,
    );
  }
}
