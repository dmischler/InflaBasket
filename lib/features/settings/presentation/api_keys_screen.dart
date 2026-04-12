import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/widgets/confirm_dialog.dart';
import 'package:inflabasket/core/widgets/settings_section.dart';
import 'package:inflabasket/features/settings/data/api_keys_repository.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

part 'api_keys_screen.g.dart';

const _providers = ['gemini', 'openai'];

class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final keysAsync = ref.watch(allApiKeysProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.apiKeysTitle)),
      body: keysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (keys) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsSection(
                title: l10n.apiKeysTitle,
                children: [
                  if (keys.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.vpn_key_outlined,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.apiKeyNoKeysYet,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.apiKeyNoKeysYetDesc,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...keys.map((key) => _ApiKeyTile(apiKeyEntry: key)),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.settingsApiKeyPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddKeyDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.apiKeyAdd),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddKeyDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddKeyDialog(l10n: l10n),
    );
  }
}

class _ApiKeyTile extends ConsumerWidget {
  final ApiKey apiKeyEntry;

  const _ApiKeyTile({required this.apiKeyEntry});

  String _maskKey(String apiKey) {
    if (apiKey.length <= 8) return '****';
    return '${apiKey.substring(0, 4)}${'*' * (apiKey.length - 8)}${apiKey.substring(apiKey.length - 4)}';
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'gemini':
        return 'Google Gemini';
      case 'openai':
        return 'OpenAI';
      default:
        return provider;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        apiKeyEntry.isActive
            ? Icons.check_circle
            : Icons.radio_button_unchecked,
        color: apiKeyEntry.isActive
            ? Colors.green
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Expanded(
              child: Text(apiKeyEntry.name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _providerLabel(apiKeyEntry.provider),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        _maskKey(apiKeyEntry.key),
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => _showKeyActions(context, ref),
    );
  }

  void _showKeyActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!apiKeyEntry.isActive)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(l10n.apiKeySetActive),
                onTap: () async {
                  await ref
                      .read(apiKeysRepositoryProvider)
                      .setActiveKey(apiKeyEntry.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(l10n.apiKeyView),
              onTap: () {
                Navigator.pop(context);
                _showViewKeyDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.apiKeyCopy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: apiKeyEntry.key));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.apiKeyCopied)),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text(l10n.apiKeyDelete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: l10n.apiKeyDeleteConfirmTitle,
                  message: l10n.apiKeyDeleteConfirmMessage,
                  confirmLabel: l10n.delete,
                  isDestructive: true,
                );
                if (confirmed == true) {
                  await ref
                      .read(apiKeysRepositoryProvider)
                      .deleteKey(apiKeyEntry.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showViewKeyDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(apiKeyEntry.name),
        content: SelectableText(
          apiKeyEntry.key,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

class _AddKeyDialog extends ConsumerStatefulWidget {
  final AppLocalizations l10n;

  const _AddKeyDialog({required this.l10n});

  @override
  ConsumerState<_AddKeyDialog> createState() => _AddKeyDialogState();
}

class _AddKeyDialogState extends ConsumerState<_AddKeyDialog> {
  late String _selectedProvider;
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(l10n.apiKeyAddTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: InputDecoration(
                labelText: l10n.apiKeyProvider,
                border: const OutlineInputBorder(),
              ),
              items: _providers
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p == 'gemini' ? 'Google Gemini' : 'OpenAI'),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedProvider = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.apiKeyNameLabel,
                hintText: l10n.apiKeyNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: l10n.settingsApiKey,
                hintText: _selectedProvider == 'gemini'
                    ? l10n.settingsApiKeyHintGemini
                    : l10n.settingsApiKeyHintOpenai,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _keyController.text.trim().isEmpty
              ? null
              : () async {
                  final name = _nameController.text.trim().isEmpty
                      ? (_selectedProvider == 'gemini' ? 'Gemini' : 'OpenAI')
                      : _nameController.text.trim();
                  await ref.read(apiKeysRepositoryProvider).addKey(
                        provider: _selectedProvider,
                        name: name,
                        key: _keyController.text.trim(),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

@riverpod
Stream<List<ApiKey>> allApiKeys(AllApiKeysRef ref) {
  final repo = ref.watch(apiKeysRepositoryProvider);
  return repo.watchAllKeys();
}
