import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:inflabasket/core/router/navigation_extras.dart';
import 'package:inflabasket/core/widgets/ai_consent_dialog.dart';
import 'package:inflabasket/features/entry_management/presentation/add_entry_screen.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class AddEntryBottomSheet extends ConsumerWidget {
  const AddEntryBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const AddEntryBottomSheet(),
    );
  }

  Future<void> _navigateToScanner(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final hasConsent =
        ref.read(settingsControllerProvider.notifier).hasAcceptedAiConsent;

    if (!hasConsent) {
      if (!context.mounted) return;
      final accepted = await showAiConsentDialog(context: context);
      if (accepted != true) return;
      await ref.read(settingsControllerProvider.notifier).acceptAiConsent();
    }

    if (!context.mounted) return;
    final router = GoRouter.of(context);
    final extras = ScannerExtras.source(source);
    Navigator.of(context).pop();
    router.push('/scanner', extra: extras);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              iconBackgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: l10n.barcode,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                GoRouter.of(context).push('/barcode');
              },
            ),
            Divider(height: 1, indent: 72),
            _OptionRow(
              icon: Icons.camera_alt,
              iconBackgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: l10n.scannerTakePhoto,
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                _navigateToScanner(context, ref, ImageSource.camera);
              },
            ),
            Divider(height: 1, indent: 72),
            _OptionRow(
              icon: Icons.photo_library,
              iconBackgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: l10n.scannerChooseFromGallery,
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                _navigateToScanner(context, ref, ImageSource.gallery);
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
}

@Deprecated('Use ActionRow from core/widgets/action_row.dart instead')
class _OptionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _OptionRow({
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
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
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
      enabled: true,
      onTap: onTap,
    );
  }
}
