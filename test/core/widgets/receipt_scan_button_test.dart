import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflabasket/core/widgets/receipt_scan_button.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

void main() {
  testWidgets('navigates to settings tab when API key is missing',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            return Scaffold(
              body: Column(
                children: [
                  Text(state.uri.toString(), key: const Key('route_text')),
                  const ReceiptScanButton(),
                ],
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith(_TestSettingsController.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final buttonFinder = find.byType(OutlinedButton);
    expect(buttonFinder, findsOneWidget);

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('/home?tab=3'), findsOneWidget);
  });
}

class _TestSettingsController extends SettingsController {
  @override
  AppSettings build() {
    return const AppSettings(
      aiProvider: AiProvider.gemini,
      geminiApiKey: '',
      openaiApiKey: '',
    );
  }
}
