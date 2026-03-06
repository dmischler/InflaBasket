import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/settings/application/export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsSupported = supportsSubscriptionsOnCurrentPlatform;
    final premiumAsync = ref.watch(subscriptionControllerProvider);
    final isPremium = premiumAsync.valueOrNull ?? false;
    final settings = ref.watch(settingsControllerProvider);
    final exportState = ref.watch(exportServiceProvider);
    final versionAsync = ref.watch(appVersionProvider);

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
              subtitle: Text(!subscriptionsSupported
                  ? 'Purchases are available on iOS and Android only.'
                  : isPremium
                      ? 'Enjoy AI receipt scanning and auto-categorization.'
                      : 'Upgrade to unlock AI receipt scanning.'),
              trailing: !subscriptionsSupported
                  ? const Chip(label: Text('Mobile only'))
                  : isPremium
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
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: settings.currency,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'CHF', child: Text('CHF')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setCurrency(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.straighten),
                  title: const Text('Use Metric System'),
                  subtitle: const Text('For quantities and unit prices'),
                  value: settings.isMetric,
                  onChanged: (val) => ref
                      .read(settingsControllerProvider.notifier)
                      .setMetric(val),
                ),
              ],
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
                  leading: const Icon(Icons.balance_outlined),
                  title: const Text('Category Weights'),
                  subtitle: const Text('Customise inflation basket weights'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/weights'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.repeat_outlined),
                  title: const Text('Recurring Purchases'),
                  subtitle: const Text('Manage saved purchase templates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/templates'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Price Alerts'),
                  subtitle: const Text(
                      'Enable notifications for product price changes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/price-alerts'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: exportState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  title: const Text('Export Data (CSV)'),
                  subtitle: const Text('Download your purchase history'),
                  onTap: () {
                    ref.read(exportServiceProvider.notifier).exportData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: Text(versionAsync.valueOrNull ?? '...'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy Policy'),
                  subtitle: Text('Coming soon'),
                  enabled: false,
                ),
                const Divider(height: 1),
                const ListTile(
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
