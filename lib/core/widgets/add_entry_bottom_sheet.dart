import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inflabasket/features/entry_management/presentation/add_entry_screen.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class AddEntryBottomSheet extends ConsumerWidget {
  const AddEntryBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPremiumAsync = ref.watch(subscriptionControllerProvider);
    final isPremium = isPremiumAsync.valueOrNull ?? false;

    final isDesktop =
        !Platform.isAndroid && !Platform.isIOS && !Platform.isFuchsia;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.addEntryTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _ActionTile(
                      icon: Icons.receipt_long,
                      title: l10n.scanReceipt,
                      isPremium: true,
                      showPremiumBadge: !isPremium,
                      isDesktop: isDesktop,
                      isDesktopDisabled: isDesktop,
                      onTap: () {
                        Navigator.pop(context);
                        if (isPremium) {
                          context.push('/scanner', extra: ImageSource.camera);
                        } else {
                          context.push('/paywall');
                        }
                      },
                    ),
                    _ActionTile(
                      icon: Icons.photo_library,
                      title: l10n.selectFromPhotos,
                      isPremium: true,
                      showPremiumBadge: !isPremium,
                      isDesktop: isDesktop,
                      isDesktopDisabled: false,
                      onTap: () {
                        Navigator.pop(context);
                        if (isPremium) {
                          context.push('/scanner', extra: ImageSource.gallery);
                        } else {
                          context.push('/paywall');
                        }
                      },
                    ),
                    const Divider(height: 32),
                    _ActionTile(
                      icon: Icons.edit,
                      title: l10n.addManually,
                      isPremium: false,
                      showPremiumBadge: false,
                      isDesktop: isDesktop,
                      isDesktopDisabled: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEntryScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isPremium;
  final bool showPremiumBadge;
  final bool isDesktop;
  final bool isDesktopDisabled;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.isPremium,
    required this.showPremiumBadge,
    required this.isDesktop,
    required this.isDesktopDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDisabled = isDesktopDisabled || (isPremium && showPremiumBadge);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDisabled
                  ? Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)
                  : null,
            ),
      ),
      trailing: showPremiumBadge
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.premiumFeature,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
              ),
            )
          : isDesktopDisabled
              ? Icon(
                  Icons.computer,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                )
              : Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
      enabled: !isDisabled,
      onTap: isDisabled
          ? () {
              if (isDesktopDisabled && isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.notAvailableDesktop)),
                );
              }
            }
          : onTap,
    );
  }
}
