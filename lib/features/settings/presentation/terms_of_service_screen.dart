import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTerms),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.termsSubtitle,
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
            icon: Icons.check_circle_outline,
            title: l10n.termsSection1Title,
            body: l10n.termsSection1Body,
          ),
          _Section(
            icon: Icons.build_outlined,
            title: l10n.termsSection2Title,
            body: l10n.termsSection2Body,
          ),
          _Section(
            icon: Icons.person_outline,
            title: l10n.termsSection3Title,
            body: l10n.termsSection3Body,
          ),
          _Section(
            icon: Icons.copyright_outlined,
            title: l10n.termsSection4Title,
            body: l10n.termsSection4Body,
          ),
          _Section(
            icon: Icons.shield_outlined,
            title: l10n.termsSection5Title,
            body: l10n.termsSection5Body,
          ),
          _Section(
            icon: Icons.update_outlined,
            title: l10n.termsSection6Title,
            body: l10n.termsSection6Body,
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
