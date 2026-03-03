import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: offeringsAsync.when(
        data: (offerings) {
          if (offerings.isEmpty) {
            return const Center(
                child: Text('No subscriptions available right now.'));
          }

          final packages = offerings.first.availablePackages;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.diamond, size: 64, color: Colors.purple),
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        ),
                        onPressed: () async {
                          final success = await ref
                              .read(subscriptionControllerProvider.notifier)
                              .purchasePremium(pkg);
                          if (success && context.mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Welcome to Premium!')),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
