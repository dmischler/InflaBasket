import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/widgets/state_message_card.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsSupported = supportsSubscriptionsOnCurrentPlatform;
    final offeringsAsync = ref.watch(offeringsProvider);
    final debugPremium = debugPremiumOverrideEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: debugPremium
          ? StateMessageCard(
              icon: Icons.bug_report_outlined,
              title: 'Premium Enabled In Debug',
              message:
                  'Debug mode unlocks premium flows so you can test receipt scanning and alerts without an active subscription.',
              actionLabel: 'Back To App',
              onAction: () => context.pop(),
              accentColor: Theme.of(context).colorScheme.tertiary,
            )
          : !subscriptionsSupported
              ? const StateMessageCard(
                  icon: Icons.phone_iphone,
                  title: 'Mobile Purchases Only',
                  message:
                      'Subscriptions are currently available on iOS and Android only.',
                )
              : offeringsAsync.when(
                  data: (offerings) {
                    if (offerings.isEmpty) {
                      return const StateMessageCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'No Offers Available',
                        message: 'No subscriptions are available right now.',
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
                            'InflaBasket Premium',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '• AI Receipt Scanning\n• Auto Categorization\n• Unlimited History',
                            style: TextStyle(fontSize: 18, height: 1.5),
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
                                        const SnackBar(
                                            content:
                                                Text('Welcome to Premium!')),
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
                            child: const Text('Restore Purchases'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                  loading: () => const StateMessageCard(
                    icon: Icons.hourglass_top,
                    title: 'Loading Offers',
                    message: 'Fetching the latest premium packages.',
                    isLoading: true,
                  ),
                  error: (e, st) => StateMessageCard(
                    icon: Icons.error_outline,
                    title: 'Could Not Load Offers',
                    message: e.toString(),
                    accentColor: Theme.of(context).colorScheme.error,
                  ),
                ),
    );
  }
}
