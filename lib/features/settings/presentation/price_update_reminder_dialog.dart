import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/services/price_update_reminder_service.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class PriceUpdateReminderDialog extends ConsumerWidget {
  const PriceUpdateReminderDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reminderService = ref.watch(priceUpdateReminderServiceProvider);

    return FutureBuilder<int>(
      future: reminderService.getStaleProductCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return AlertDialog(
          title: Text(l10n.priceUpdatePopupTitle),
          content: Text(l10n.priceUpdatePopupMessage(count)),
          actions: [
            TextButton(
              onPressed: () async {
                await reminderService.clearPendingPopup();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(l10n.priceUpdatePopupDismiss),
            ),
            FilledButton(
              onPressed: () async {
                await reminderService.clearPendingPopup();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  context.push('/settings/price-updates');
                }
              },
              child: Text(l10n.priceUpdatePopupAction),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showPriceUpdateReminderDialogIfNeeded(
    BuildContext context, WidgetRef ref) async {
  final reminderService = ref.read(priceUpdateReminderServiceProvider);

  if (!reminderService.hasPendingPopup) {
    return;
  }

  final settings = ref.read(settingsControllerProvider);
  if (!settings.priceUpdateReminderEnabled) {
    await reminderService.clearPendingPopup();
    return;
  }

  final count = await reminderService.getStaleProductCount();
  if (count == 0) {
    await reminderService.clearPendingPopup();
    return;
  }

  if (context.mounted) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PriceUpdateReminderDialog(),
    );
  }
}
