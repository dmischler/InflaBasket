import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/services/database_backup_service.dart';
import 'package:inflabasket/features/settings/application/export_service.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Map<String, String> _languageLabels = <String, String>{
    'en': 'English',
    'de': 'Deutsch',
  };

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    try {
      final filename = await ref
          .read(databaseBackupServiceProvider.notifier)
          .exportDatabase();
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.backupExportSuccess(filename))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.backupImportConfirmTitle),
        content: Text(AppLocalizations.of(context)!.backupImportConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.backupRestoreButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ref
          .read(databaseBackupServiceProvider.notifier)
          .importDatabase();
      if (result != null && context.mounted) {
        HapticFeedback.heavyImpact();
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(AppLocalizations.of(context)!.backupImportSuccess),
            content: Text(AppLocalizations.of(context)!.backupRestartRequired),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.backupInvalidFile)),
        );
      }
    }
  }

  Future<void> _handleExportJson(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(databaseBackupServiceProvider.notifier).exportAsJson();
      if (context.mounted) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.settingsManageCategories),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/categories'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.balance_outlined),
                  title: Text(l10n.settingsCategoryWeights),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/weights'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.repeat_outlined),
                  title: Text(l10n.settingsTemplates),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/templates'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.priceAlerts),
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
                  onTap: () {
                    ref.read(exportServiceProvider.notifier).exportData();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: Text(l10n.settingsFactoryReset),
                  onTap: () async {
                    final shouldReset = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.factoryResetConfirmTitle),
                        content: Text(l10n.factoryResetConfirmMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(MaterialLocalizations.of(context)
                                .cancelButtonLabel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(l10n.factoryResetButton),
                          ),
                        ],
                      ),
                    );
                    if (shouldReset == true && context.mounted) {
                      final repo = ref.read(entryRepositoryProvider);
                      final database = repo.database;
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .factoryReset(database);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Factory reset completed')),
                        );
                        context.go('/home');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.settingsBackupRestore,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: Text(l10n.settingsExportDatabase),
                  onTap: () => _handleExport(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.settingsImportDatabase),
                  onTap: () => _handleImport(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: Text(l10n.settingsExportJson),
                  onTap: () => _handleExportJson(context, ref),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
