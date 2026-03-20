import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/widgets/ai_consent_dialog.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class ReceiptScanButton extends ConsumerWidget {
  final bool isPremium;

  const ReceiptScanButton({
    super.key,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: () async {
        if (isPremium) {
          final hasConsent = ref
              .read(settingsControllerProvider.notifier)
              .hasAcceptedAiConsent;
          if (!hasConsent) {
            final accepted = await showAiConsentDialog(context: context);
            if (accepted != true) return;
            await ref
                .read(settingsControllerProvider.notifier)
                .acceptAiConsent();
          }
          if (!context.mounted) return;
          context.push('/scanner');
        } else {
          context.push('/paywall');
        }
      },
      icon: const Icon(Icons.document_scanner, color: Colors.purple),
      label: Text(l10n.scanReceipt),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }
}
