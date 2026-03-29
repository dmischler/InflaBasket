import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/widgets/action_row.dart';
import 'package:inflabasket/core/widgets/confirm_dialog.dart';
import 'package:inflabasket/core/widgets/settings_section.dart';
import 'package:inflabasket/core/services/database_backup_service.dart';
import 'package:inflabasket/features/settings/application/export_service.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/subscription/application/subscription_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

enum ExportFormat { sqlite, csv, json }

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

  Future<void> _showExportFormatDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.exportFormatTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ExportFormat.sqlite),
            child: ListTile(
              leading: const Icon(Icons.storage),
              title: Text(l10n.exportFormatSqlite),
              subtitle: Text(l10n.exportFormatSqliteDesc),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ExportFormat.csv),
            child: ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(l10n.exportFormatCsv),
              subtitle: Text(l10n.exportFormatCsvDesc),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ExportFormat.json),
            child: ListTile(
              leading: const Icon(Icons.code),
              title: Text(l10n.exportFormatJson),
              subtitle: Text(l10n.exportFormatJsonDesc),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result != null) {
      switch (result) {
        case ExportFormat.sqlite:
          await _handleExport(context, ref);
          break;
        case ExportFormat.csv:
          ref.read(exportServiceProvider.notifier).exportData();
          break;
        case ExportFormat.json:
          await _handleExportJson(context, ref);
          break;
      }
    }
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final filename = await ref
          .read(databaseBackupServiceProvider.notifier)
          .exportDatabase();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupExportSuccess(filename))),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.backupImportConfirmTitle,
      message: l10n.backupImportConfirmMessage,
      confirmLabel: l10n.backupRestoreButton,
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      final result = await ref
          .read(databaseBackupServiceProvider.notifier)
          .importDatabase();
      if (!mounted || result == null) return;
      HapticFeedback.heavyImpact();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.backupImportSuccess),
          content: Text(l10n.backupRestartRequired),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupInvalidFile)));
    }
  }

  Future<void> _handleExportJson(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(databaseBackupServiceProvider.notifier).exportAsJson();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  Future<void> _handleFactoryReset() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldReset = await ConfirmDialog.show(
      context,
      title: l10n.factoryResetConfirmTitle,
      message: l10n.factoryResetConfirmMessage,
      confirmLabel: l10n.factoryResetButton,
      isDestructive: true,
    );

    if (shouldReset == true && mounted) {
      final repo = ref.read(entryRepositoryProvider);
      final database = repo.database;
      await ref
          .read(settingsControllerProvider.notifier)
          .factoryReset(database);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.factoryResetCompleted)),
        );
        context.go('/home');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.settingsSubscription,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    isPremium ? Icons.verified : Icons.lock_outline,
                    color: isPremium ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    isPremium
                        ? l10n.settingsPremiumActive
                        : l10n.settingsFreeTier,
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
                                      .read(subscriptionControllerProvider
                                          .notifier)
                                      .restorePurchases(),
                                  child: Text(l10n.settingsRestore),
                                )
                              : ElevatedButton(
                                  onPressed: () => context.push('/paywall'),
                                  child: Text(l10n.settingsUpgrade),
                                ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SettingsSection(
            title: l10n.settingsAppearance,
            children: [
              ActionRow(
                variant: ActionRowVariant.toggle,
                icon: Icons.dark_mode,
                title: l10n.settingsDarkMode,
                subtitle: l10n.settingsDarkModeDesc,
                toggleValue: settings.isDarkMode,
                onToggleChanged: (val) => ref
                    .read(settingsControllerProvider.notifier)
                    .setDarkMode(val),
              ),
              const Divider(height: 1),
              ActionRow(
                variant: ActionRowVariant.dropdown,
                icon: Icons.language,
                title: l10n.settingsLanguage,
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
              ActionRow(
                variant: ActionRowVariant.dropdown,
                icon: Icons.currency_exchange,
                title: l10n.settingsCurrency,
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
              ActionRow(
                variant: ActionRowVariant.toggle,
                icon: Icons.straighten,
                title: l10n.settingsMetricSystem,
                toggleValue: settings.isMetric,
                onToggleChanged: (val) => ref
                    .read(settingsControllerProvider.notifier)
                    .setMetric(val),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsSection(
            title: l10n.settingsDataOptions,
            children: [
              ActionRow(
                variant: ActionRowVariant.navigation,
                icon: Icons.category_outlined,
                title: l10n.settingsManageCategories,
                onTap: () => context.push('/settings/categories'),
              ),
              const Divider(height: 1),
              ActionRow(
                variant: ActionRowVariant.navigation,
                icon: Icons.notifications_active_outlined,
                title: l10n.priceAlerts,
                onTap: () => context.push('/settings/price-alerts'),
              ),
              const Divider(height: 1),
              ActionRow(
                variant: ActionRowVariant.navigation,
                icon: Icons.update,
                title: l10n.settingsPriceUpdateReminder,
                onTap: () => context.push('/settings/price-updates/settings'),
              ),
              if (settings.priceUpdateReminderEnabled) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/settings/price-updates'),
                      icon: const Icon(Icons.list_alt),
                      label: Text(l10n.settingsShowPriceUpdateList),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 1),
              ActionRow(
                variant: ActionRowVariant.navigation,
                icon: Icons.save_alt,
                title: l10n.settingsAutoSaveBackup,
                onTap: () => context.push('/settings/auto-save'),
              ),
              const Divider(height: 1),
              ActionRow(
                variant: ActionRowVariant.action,
                icon: Icons.upload_outlined,
                iconBackgroundColor: exportState.isLoading
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                title: l10n.settingsExportData,
                trailing: exportState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: exportState.isLoading ? null : _showExportFormatDialog,
              ),
              const Divider(height: 1),
              ActionRow(
                variant: ActionRowVariant.action,
                icon: Icons.download_outlined,
                title: l10n.settingsImportDatabase,
                onTap: () => _handleImport(context, ref),
              ),
              const Divider(height: 1),
              ActionRow(
                variant: ActionRowVariant.action,
                icon: Icons.restart_alt,
                title: l10n.settingsFactoryReset,
                onTap: _handleFactoryReset,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.settingsAbout,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.settingsVersion),
                  subtitle: Text(versionAsync.valueOrNull ?? '...'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.settingsPrivacyPolicy),
                  onTap: () => context.push('/settings/privacy-policy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.settingsTerms),
                  onTap: () => context.push('/settings/terms-of-service'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
