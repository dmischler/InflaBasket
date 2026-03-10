import 'package:flutter/material.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

/// Result returned by [showDuplicateDialog].
enum DuplicateAction {
  /// User wants to link the new entry to the existing product.
  linkToExisting,

  /// User wants to create a brand-new product with the typed name.
  createNew,
}

/// Shows an alert dialog informing the user that a possibly duplicate product
/// name was detected.
///
/// [newName] is the name the user typed.
/// [existingName] is the best-matching name already in the database.
///
/// Returns a [DuplicateAction] or null if the dialog was dismissed.
Future<DuplicateAction?> showDuplicateDialog({
  required BuildContext context,
  required String newName,
  required String existingName,
}) {
  return showDialog<DuplicateAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return AlertDialog(
        title: Text(l10n.duplicateDetectionTitle),
        content: Text(
          l10n.duplicateDetectionMessage(newName, existingName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(DuplicateAction.createNew),
            child: Text(l10n.duplicateDetectionCreateNew),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(DuplicateAction.linkToExisting),
            child: Text(l10n.duplicateDetectionLinkExisting),
          ),
        ],
      );
    },
  );
}
