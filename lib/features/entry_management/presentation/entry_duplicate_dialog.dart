import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

enum EntryDuplicateAction {
  dontSave,
  saveAnyway,
}

Future<EntryDuplicateAction?> showEntryDuplicateDialog({
  required BuildContext context,
  required PurchaseEntryWithProduct existingEntry,
}) {
  return showDialog<EntryDuplicateAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final dateFormat =
          DateFormat.yMd(Localizations.localeOf(ctx).languageCode);

      return AlertDialog(
        title: Text(l10n.entryDuplicateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.entryDuplicateMessage),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingEntry.productName,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${existingEntry.price.toStringAsFixed(2)} CHF'),
                  Text(existingEntry.storeName),
                  Text(dateFormat.format(existingEntry.purchaseDate)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(EntryDuplicateAction.saveAnyway),
            child: Text(l10n.entryDuplicateSaveAnyway),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(EntryDuplicateAction.dontSave),
            child: Text(l10n.entryDuplicateDontSave),
          ),
        ],
      );
    },
  );
}
