import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/settings/application/export_service.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> _languageLabels = <String, String>{
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Français',
    'it': 'Italiano',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subscriptionsSupported = supportsSubscriptionsOnCurrentPlatform;
    final premiumAsync = ref.watch(subscriptionControllerProvider);
    final isPremium = premiumAsync.valueOrNull ?? false;
    final settings = ref.watch(settingsControllerProvider);
    final exportState = ref.watch(exportServiceProvider);
    final versionAsync = ref.watch(appVersionProvider);
    final debugPremium = debugPremiumOverrideEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settingsSubscription,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                isPremium ? Icons.verified : Icons.lock_outline,
                color: isPremium ? Colors.green : Colors.orange,
              ),
              title: Text(
                isPremium ? l10n.settingsPremiumActive : l10n.settingsFreeTier,
              ),
              subtitle: Text(debugPremium
                  ? l10n.settingsDebugPremiumSubtitle
                  : !subscriptionsSupported
                      ? l10n.settingsMobileOnlySubtitle
                      : isPremium
                          ? l10n.settingsPremiumSubtitle
                          : l10n.settingsFreeSubtitle),
              trailing: !subscriptionsSupported
                  ? Chip(label: Text(l10n.settingsMobileOnly))
                  : debugPremium
                      ? Chip(label: Text(l10n.settingsDebugUnlock))
                      : isPremium
                          ? TextButton(
                              onPressed: () => ref
                                  .read(subscriptionControllerProvider.notifier)
                                  .restorePurchases(),
                              child: Text(l10n.settingsRestore),
                            )
                          : ElevatedButton(
                              onPressed: () => context.push('/paywall'),
                              child: Text(l10n.settingsUpgrade),
                            ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsPreferences,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: Text(l10n.settingsCurrency),
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
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.settingsLanguage),
                  trailing: DropdownButton<String>(
                    value: settings.locale,
                    underline: const SizedBox(),
                    items: SettingsController.supportedLocales
                        .map(
                          (locale) => DropdownMenuItem<String>(
                            value: locale,
                            child: Text(_languageLabels[locale] ?? locale),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setLocale(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.straighten),
                  title: Text(l10n.settingsMetricSystem),
                  subtitle: Text(l10n.settingsMetricSubtitle),
                  value: settings.isMetric,
                  onChanged: (val) => ref
                      .read(settingsControllerProvider.notifier)
                      .setMetric(val),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('App Theme'),
                  trailing: DropdownButton<AppThemeType>(
                    value: settings.themeType,
                    underline: const SizedBox(),
                    items: AppThemeType.values
                        .map(
                          (theme) => DropdownMenuItem<AppThemeType>(
                            value: theme,
                            child: Text(theme.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setThemeType(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsDataManagement,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.settingsManageCategories),
                  subtitle: Text(l10n.settingsManageCategoriesSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/categories'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.balance_outlined),
                  title: Text(l10n.settingsCategoryWeights),
                  subtitle: Text(l10n.settingsCategoryWeightsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/weights'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.repeat_outlined),
                  title: Text(l10n.settingsTemplates),
                  subtitle: Text(l10n.settingsTemplatesSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/templates'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.priceAlerts),
                  subtitle: Text(l10n.settingsPriceAlertsSubtitle),
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
                  title: Text(l10n.settingsExportData),
                  subtitle: Text(l10n.settingsExportSubtitle),
                  onTap: () {
                    ref.read(exportServiceProvider.notifier).exportData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsAbout,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.settingsVersion),
                  subtitle: Text(versionAsync.valueOrNull ?? '...'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.settingsPrivacyPolicy),
                  subtitle: Text(l10n.settingsComingSoon),
                  enabled: false,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text(l10n.settingsTerms),
                  subtitle: Text(l10n.settingsComingSoon),
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
