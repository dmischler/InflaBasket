import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/models/auto_save_config.dart';
import 'package:inflabasket/core/services/auto_backup_service.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class AutoSaveBackupScreen extends ConsumerWidget {
  const AutoSaveBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);
    final autoBackupService = ref.watch(autoBackupServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsAutoSaveBackup),
      ),
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
                    l10n.settingsAutoSaveBackup,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.save_alt),
                  title: Text(l10n.autoSaveEnable),
                  value: settings.autoSaveEnabled,
                  onChanged: (val) async {
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .setAutoSaveEnabled(val);
                  },
                ),
                if (settings.autoSaveEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(l10n.autoSaveStorageType),
                    trailing: SegmentedButton<AutoSaveStorageType>(
                      segments: [
                        ButtonSegment(
                          value: AutoSaveStorageType.local,
                          label: Text(l10n.autoSaveStorageLocal),
                        ),
                        ButtonSegment(
                          value: AutoSaveStorageType.cloud,
                          label: Text(l10n.autoSaveStorageCloud),
                        ),
                      ],
                      selected: {settings.autoSaveStorageType},
                      onSelectionChanged: (Set<AutoSaveStorageType> selection) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setAutoSaveStorageType(selection.first);
                      },
                    ),
                  ),
                  if (settings.autoSaveStorageType == AutoSaveStorageType.local)
                    ListTile(
                      leading: const Icon(Icons.drive_folder_upload),
                      title: Text(l10n.autoSaveSelectFolder),
                      subtitle: Text(
                        settings.autoSavePath ?? l10n.autoSavePathNotSet,
                        style: TextStyle(
                          color: settings.autoSavePath == null
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await autoBackupService.pickStorageLocation();
                      },
                    ),
                ],
                if (!settings.autoSaveEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      l10n.autoSaveEnablePrompt,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.autoSaveManualBackup,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                if (settings.lastBackupAt != null)
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(l10n.autoSaveLastBackup),
                    subtitle: Text(
                      _formatDateTime(settings.lastBackupAt!),
                    ),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(l10n.autoSaveLastBackup),
                    subtitle: Text(l10n.autoSaveNoBackup),
                  ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final success = await autoBackupService.performBackup();
                        if (context.mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? l10n.autoSaveSuccess
                                    : l10n.autoSaveError(''),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.backup),
                      label: Text(l10n.autoSaveBackupNow),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
