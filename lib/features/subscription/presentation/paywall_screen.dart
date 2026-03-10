import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

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
              title: l10n.paywallDebugTitle,
              message: l10n.paywallDebugMessage,
              actionLabel: l10n.paywallBackToApp,
              onAction: () => context.pop(),
              accentColor: Theme.of(context).colorScheme.tertiary,
            )
          : !subscriptionsSupported
              ? StateMessageCard(
                  icon: Icons.phone_iphone,
                  title: l10n.paywallMobileOnlyTitle,
                  message: l10n.paywallMobileOnlyMessage,
                )
              : offeringsAsync.when(
                  data: (offerings) {
                    if (offerings.isEmpty) {
                      return StateMessageCard(
                        icon: Icons.inventory_2_outlined,
                        title: l10n.paywallNoOffersTitle,
                        message: l10n.paywallNoOffersMessage,
                      );
                    }

                    final packages = offerings.first.availablePackages;

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.diamond,
                              size: 64, color: Colors.purple),
                          const SizedBox(height: 24),
                          Text(
                            l10n.paywallProductTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.paywallFeatures,
                            style: const TextStyle(fontSize: 18, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                          ...packages.map((pkg) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ),
                                  onPressed: () async {
                                    final success = await ref
                                        .read(subscriptionControllerProvider
                                            .notifier)
                                        .purchasePremium(pkg);
                                    if (success && context.mounted) {
                                      context.pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(l10n.paywallWelcome)),
                                      );
                                    }
                                  },
                                  child: Text(
                                    '${pkg.storeProduct.title} - ${pkg.storeProduct.priceString}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              )),
                          TextButton(
                            onPressed: () => ref
                                .read(subscriptionControllerProvider.notifier)
                                .restorePurchases(),
                            child: Text(l10n.paywallRestorePurchases),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                  loading: () => StateMessageCard(
                    icon: Icons.hourglass_top,
                    title: l10n.paywallLoadingOffersTitle,
                    message: l10n.paywallLoadingOffersMessage,
                    isLoading: true,
                  ),
                  error: (e, st) => StateMessageCard(
                    icon: Icons.error_outline,
                    title: l10n.paywallLoadOffersError,
                    message: e.toString(),
                    accentColor: Theme.of(context).colorScheme.error,
                  ),
                ),
    );
  }
}
