import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumAsync = ref.watch(subscriptionControllerProvider);
    final isPremium = premiumAsync.valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Subscription', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                isPremium ? Icons.verified : Icons.lock_outline,
                color: isPremium ? Colors.green : Colors.orange,
              ),
              title: Text(isPremium ? 'Premium Active' : 'Free Tier'),
              subtitle: Text(isPremium
                  ? 'Enjoy AI receipt scanning and auto-categorization.'
                  : 'Upgrade to unlock AI receipt scanning.'),
              trailing: isPremium
                  ? TextButton(
                      onPressed: () => ref
                          .read(subscriptionControllerProvider.notifier)
                          .restorePurchases(),
                      child: const Text('Restore'),
                    )
                  : ElevatedButton(
                      onPressed: () => context.push('/paywall'),
                      child: const Text('Upgrade'),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Data Management',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Manage Categories'),
                  subtitle: const Text('Add or remove custom categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/categories'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export Data (CSV)'),
                  subtitle: const Text('Coming soon'),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy Policy'),
                  subtitle: Text('Coming soon'),
                  enabled: false,
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Terms of Service'),
                  subtitle: Text('Coming soon'),
                  enabled: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
