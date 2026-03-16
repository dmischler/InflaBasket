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
import 'package:inflabasket/core/services/price_update_reminder_service.dart';
import 'package:inflabasket/core/theme/app_theme.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/features/settings/presentation/price_update_reminder_dialog.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class InflaBasketApp extends ConsumerStatefulWidget {
  const InflaBasketApp({super.key});

  @override
  ConsumerState<InflaBasketApp> createState() => _InflaBasketAppState();
}

class _InflaBasketAppState extends ConsumerState<InflaBasketApp>
    with WidgetsBindingObserver {
  bool _didRunInitialReminderSync = false;
  bool _didRunInitialSatsRepair = false;
  bool _didRunInitialDuplicateCleanup = false;
  bool _isShowingReminderPopup = false;
  int _duplicateCleanupCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    NotificationService.onPriceUpdateNotificationTap = () {
      _handleNotificationTap();
    };

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          _didRunInitialReminderSync ||
          _didRunInitialSatsRepair ||
          _didRunInitialDuplicateCleanup) {
        return;
      }
      _didRunInitialSatsRepair = true;
      _didRunInitialReminderSync = true;
      _didRunInitialDuplicateCleanup = true;
      await Future.wait([
        _repairMissingEntrySats(),
        _syncReminderSchedule(),
        _cleanupDuplicateEntries(),
      ]);

      if (NotificationService.consumeDidLaunchFromPriceUpdateNotification()) {
        await ref
            .read(priceUpdateReminderServiceProvider)
            .handleNotificationTap();
      }

      _checkPendingPopup();
      _showDuplicateCleanupNotification();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _syncReminderSchedule();
        _checkPendingPopup();
      });
    }
  }

  Future<void> _handleNotificationTap() async {
    final reminderService = ref.read(priceUpdateReminderServiceProvider);
    await reminderService.handleNotificationTap();
    _checkPendingPopup();
  }

  Future<void> _syncReminderSchedule() async {
    final reminderService = ref.read(priceUpdateReminderServiceProvider);
    await reminderService.syncReminderSchedule();
  }

  Future<void> _repairMissingEntrySats() async {
    try {
      final repo = ref.read(entryRepositoryProvider);
      await repo.updateMissingPriceSats();
    } catch (error, stackTrace) {
      debugPrint('Failed to repair missing sats values: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _cleanupDuplicateEntries() async {
    try {
      final repo = ref.read(entryRepositoryProvider);
      final count = await repo.cleanupDuplicateEntries();
      if (count > 0) {
        _duplicateCleanupCount = count;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to cleanup duplicate entries: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _showDuplicateCleanupNotification() {
    if (!mounted || _duplicateCleanupCount == 0) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(l10n.duplicateCleanupNotification(_duplicateCleanupCount)),
        duration: const Duration(seconds: 4),
      ),
    );
    _duplicateCleanupCount = 0;
  }

  void _checkPendingPopup() {
    if (!mounted) return;
    final reminderService = ref.read(priceUpdateReminderServiceProvider);
    if (_isShowingReminderPopup || !reminderService.hasPendingPopup) {
      return;
    }

    _isShowingReminderPopup = true;
    showPriceUpdateReminderDialogIfNeeded(context, ref).whenComplete(() {
      _isShowingReminderPopup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'InflaBasket',
      theme: AppTheme.getLuxeDarkTheme(isBitcoinMode: settings.isBitcoinMode),
      themeMode: ThemeMode.light, // Let AppTheme control everything
      locale: Locale(settings.locale),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
