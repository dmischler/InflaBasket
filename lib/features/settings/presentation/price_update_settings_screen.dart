import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class PriceUpdateSettingsScreen extends ConsumerWidget {
  const PriceUpdateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPriceUpdateReminder),
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
                    l10n.settingsPriceUpdateReminder,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.update),
                  title: Text(l10n.settingsReminder),
                  value: settings.priceUpdateReminderEnabled,
                  onChanged: (val) async {
                    final enabled = await ref
                        .read(settingsControllerProvider.notifier)
                        .setPriceUpdateReminder(val);

                    if (!enabled && val && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.priceUpdatePermissionDenied),
                        ),
                      );
                    }
                  },
                ),
                if (settings.priceUpdateReminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.settingsReminderAfter),
                    trailing: DropdownButton<int>(
                      value: settings.priceUpdateReminderMonths,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 6, child: Text('6')),
                        DropdownMenuItem(value: 9, child: Text('9')),
                        DropdownMenuItem(value: 12, child: Text('12')),
                        DropdownMenuItem(value: 18, child: Text('18')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setPriceUpdateReminderMonths(val);
                        }
                      },
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      l10n.settingsPriceUpdateReminderDisabled,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (settings.priceUpdateReminderEnabled) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/settings/price-updates');
                    },
                    icon: const Icon(Icons.list_alt),
                    label: Text(l10n.settingsShowPriceUpdateList),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
