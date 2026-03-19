import 'package:flutter/material.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

/// Shows a consent dialog explaining AI data usage before the receipt scanner
/// is used for the first time.
///
/// Returns `true` if the user accepts, `null` if they decline or dismiss.
Future<bool?> showAiConsentDialog({required BuildContext context}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(child: Text(l10n.aiConsentTitle)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            l10n.aiConsentBody,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.aiConsentDecline),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.aiConsentAccept),
          ),
        ],
      );
    },
  );
}
