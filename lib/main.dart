import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:inflabasket/core/router/app_router.dart';
import 'package:inflabasket/core/services/notification_service.dart';
import 'package:inflabasket/core/theme/app_theme.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // === OpenFoodFacts Configuration ===
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'InflaBasket',
    version: '1.9.1',
    url: 'https://github.com/anomalyco/InflaBasket',
  );

  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.SWITZERLAND;
  OpenFoodAPIConfiguration.globalLanguages = [
    OpenFoodFactsLanguage.ENGLISH,
    OpenFoodFactsLanguage.GERMAN,
    OpenFoodFactsLanguage.FRENCH,
  ];

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file may not exist in some environments (e.g., production builds)
    // Ignore error - env vars will just be null
  }
  await NotificationService.initialize();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Check for pending database restore
  final pendingPath = sharedPreferences.getString('pending_restore_path');
  if (pendingPath != null) {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'db.sqlite');
      await File(pendingPath).copy(dbPath);
      await sharedPreferences.remove('pending_restore_path');
    } catch (e) {
      // If restore fails, just continue with existing database
      await sharedPreferences.remove('pending_restore_path');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const InflaBasketApp(),
    ),
  );
}

class InflaBasketApp extends ConsumerWidget {
  const InflaBasketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'InflaBasket',
      theme: AppTheme.getTheme(settings.themeType),
      themeMode: ThemeMode.light, // Let AppTheme control everything
      locale: Locale(settings.locale),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
