import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPrivacyPolicy),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.privacyPolicySubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          _Section(
            icon: Icons.business_outlined,
            title: l10n.privacyPolicySection1Title,
            body: l10n.privacyPolicySection1Body,
          ),
          _Section(
            icon: Icons.data_usage_outlined,
            title: l10n.privacyPolicySection2Title,
            body: l10n.privacyPolicySection2Body,
          ),
          _Section(
            icon: Icons.storage_outlined,
            title: l10n.privacyPolicySection3Title,
            body: l10n.privacyPolicySection3Body,
          ),
          _Section(
            icon: Icons.share_outlined,
            title: l10n.privacyPolicySection4Title,
            body: l10n.privacyPolicySection4Body,
          ),
          _Section(
            icon: Icons.gavel_outlined,
            title: l10n.privacyPolicySection5Title,
            body: l10n.privacyPolicySection5Body,
          ),
          _Section(
            icon: Icons.contact_support_outlined,
            title: l10n.privacyPolicySection6Title,
            body: l10n.privacyPolicySection6Body,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
