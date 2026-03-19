import 'package:flutter/material.dart';
import 'package:inflabasket/core/theme/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBitcoinMode = theme.primaryColor == AppColors.accentBtcMain;
    final accentColor =
        isBitcoinMode ? AppColors.accentBtcMain : AppColors.accentFiatMain;

    return AlertDialog(
      backgroundColor: AppColors.bgVault,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.borderMetallic, width: 1),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red : accentColor,
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class ConfirmDialogHelpers {
  static Future<bool?> showDelete(
    BuildContext context, {
    required String itemName,
    String? customMessage,
  }) {
    return ConfirmDialog.show(
      context,
      title: 'Delete',
      message: customMessage ?? 'Are you sure you want to delete "$itemName"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
  }

  static Future<bool?> showDiscardChanges(BuildContext context) {
    return ConfirmDialog.show(
      context,
      title: 'Discard Changes',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
  }
}
