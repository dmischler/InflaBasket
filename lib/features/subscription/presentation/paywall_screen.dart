import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/widgets/state_illustrations.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/theme/app_colors.dart';
import 'package:inflabasket/core/widgets/shimmer_effect.dart';
import 'package:inflabasket/core/widgets/vault_card.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subscriptionsSupported = supportsSubscriptionsOnCurrentPlatform;
    final offeringsAsync = ref.watch(offeringsProvider);
    final debugPremium = debugPremiumOverrideEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paywallTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: debugPremium
          ? StateMessageCard(
              icon: Icons.bug_report_outlined,
              animationAsset: StateIllustrations.emptyGeneral,
              title: l10n.paywallDebugTitle,
              message: l10n.paywallDebugMessage,
              actionLabel: l10n.paywallBackToApp,
              onAction: () => context.pop(),
              accentColor: Theme.of(context).colorScheme.tertiary,
            )
          : !subscriptionsSupported
              ? StateMessageCard(
                  icon: Icons.phone_iphone,
                  animationAsset: StateIllustrations.emptyGeneral,
                  title: l10n.paywallMobileOnlyTitle,
                  message: l10n.paywallMobileOnlyMessage,
                )
              : offeringsAsync.when(
                  data: (offerings) {
                    if (offerings.isEmpty) {
                      return StateMessageCard(
                        icon: Icons.inventory_2_outlined,
                        animationAsset: StateIllustrations.emptyGeneral,
                        title: l10n.paywallNoOffersTitle,
                        message: l10n.paywallNoOffersMessage,
                      );
                    }

                    final packages = offerings.first.availablePackages;
                    final isLuxeMode =
                        Theme.of(context).scaffoldBackgroundColor ==
                            AppColors.bgVoid;

                    return Container(
                      decoration: isLuxeMode
                          ? BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.accentBtcMain
                                      .withValues(alpha: 0.1),
                                  AppColors.bgVoid,
                                ],
                              ),
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            ShimmerEffect(
                              baseColor: isLuxeMode
                                  ? AppColors.accentBtcMain
                                  : Colors.purple,
                              highlightColor: isLuxeMode
                                  ? Colors.white
                                  : Colors.purpleAccent,
                              child: Icon(Icons.diamond,
                                  size: 80,
                                  color: isLuxeMode
                                      ? AppColors.accentBtcMain
                                      : Colors.purple),
                            ),
                            const SizedBox(height: 32),
                            ShimmerEffect(
                              baseColor: isLuxeMode
                                  ? AppColors.textPrimary
                                  : Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.color ??
                                      Colors.black,
                              highlightColor: isLuxeMode
                                  ? AppColors.accentBtcMain
                                  : Colors.purple,
                              child: Text(
                                l10n.paywallProductTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (isLuxeMode)
                              VaultCard(
                                isActive: true,
                                child: Column(
                                  children: [
                                    _buildFeatureRow(
                                        context,
                                        'AI Receipt Scanning',
                                        Icons.document_scanner),
                                    _buildFeatureRow(context,
                                        'Advanced Data Export', Icons.download),
                                    _buildFeatureRow(context,
                                        'Unlimited Categories', Icons.category),
                                  ],
                                ),
                              )
                            else
                              Text(
                                l10n.paywallFeatures,
                                style:
                                    const TextStyle(fontSize: 18, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            const Spacer(),
                            ...packages.map((pkg) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: isLuxeMode
                                      ? Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accentBtcMain
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              )
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.all(16),
                                              backgroundColor:
                                                  AppColors.accentBtcMain,
                                              foregroundColor: AppColors.bgVoid,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () => _purchase(
                                                context, ref, pkg, l10n),
                                            child: Text(
                                              '${pkg.storeProduct.title} - ${pkg.storeProduct.priceString}',
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.all(16),
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                          ),
                                          onPressed: () => _purchase(
                                              context, ref, pkg, l10n),
                                          child: Text(
                                            '${pkg.storeProduct.title} - ${pkg.storeProduct.priceString}',
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                )),
                            TextButton(
                              onPressed: () => ref
                                  .read(subscriptionControllerProvider.notifier)
                                  .restorePurchases(),
                              child: Text(l10n.paywallRestorePurchases,
                                  style: TextStyle(
                                      color: isLuxeMode
                                          ? AppColors.textSecondary
                                          : null)),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => StateMessageCard(
                    icon: Icons.hourglass_top,
                    animationAsset: StateIllustrations.loadingMinimal,
                    title: l10n.paywallLoadingOffersTitle,
                    message: l10n.paywallLoadingOffersMessage,
                    isLoading: true,
                  ),
                  error: (e, st) => StateMessageCard(
                    icon: Icons.error_outline,
                    animationAsset: StateIllustrations.error,
                    loop: false,
                    title: l10n.paywallLoadOffersError,
                    message: e.toString(),
                    accentColor: Theme.of(context).colorScheme.error,
                  ),
                ),
    );
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, dynamic pkg,
      AppLocalizations l10n) async {
    final success = await ref
        .read(subscriptionControllerProvider.notifier)
        .purchasePremium(pkg);
    if (success && context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paywallWelcome)),
      );
    }
  }

  Widget _buildFeatureRow(BuildContext context, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBtcMain, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
