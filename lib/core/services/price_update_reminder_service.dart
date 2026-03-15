import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inflabasket/core/services/notification_service.dart';
import 'package:inflabasket/core/services/price_history_service.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';
import 'package:inflabasket/l10n/app_localizations.dart';
import 'package:inflabasket/l10n/app_localizations_de.dart';
import 'package:inflabasket/l10n/app_localizations_en.dart';

part 'price_update_reminder_service.g.dart';

@riverpod
PriceUpdateReminderService priceUpdateReminderService(
    PriceUpdateReminderServiceRef ref) {
  return PriceUpdateReminderService(
    ref.watch(notificationServiceProvider),
    ref.watch(priceHistoryServiceProvider),
    ref.watch(settingsControllerProvider),
    ref.watch(sharedPreferencesProvider),
  );
}

class PriceUpdateReminderService {
  final NotificationService _notificationService;
  final PriceHistoryService _priceHistoryService;
  final AppSettings _settings;
  final SharedPreferences _prefs;

  static const String _keyPendingPopup = 'price_update_pending_popup';
  static const String _keyReminderScheduledAt =
      'price_update_reminder_scheduled_at';

  PriceUpdateReminderService(
    this._notificationService,
    this._priceHistoryService,
    this._settings,
    this._prefs,
  );

  bool get isReminderEnabled => _settings.priceUpdateReminderEnabled;
  int get reminderMonths => _settings.priceUpdateReminderMonths;

  AppLocalizations get _fallbackL10n {
    switch (_settings.locale) {
      case 'de':
        return AppLocalizationsDe();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  String get _defaultNotificationTitle =>
      _fallbackL10n.priceUpdateNotificationTitle;

  String get _defaultNotificationBody =>
      _fallbackL10n.priceUpdateNotificationBody;

  Future<void> syncReminderSchedule({
    String? notificationTitle,
    String? notificationBody,
  }) async {
    if (!isReminderEnabled) {
      await _notificationService.cancelPriceUpdateReminder();
      await _prefs.remove(_keyReminderScheduledAt);
      return;
    }

    final staleCount = await _priceHistoryService.getStaleProductCount(
      reminderMonths,
    );

    if (staleCount == 0) {
      await _notificationService.cancelPriceUpdateReminder();
      await _prefs.remove(_keyReminderScheduledAt);

      final nextDueDate = await _priceHistoryService.getNextProductDueDate(
        reminderMonths,
      );

      if (nextDueDate != null) {
        await _scheduleIfChanged(
          nextDueDate,
          notificationTitle: notificationTitle,
          notificationBody: notificationBody,
        );
      }
    } else {
      final scheduledAt = _getScheduledReminderAt();
      final shouldRescheduleImmediately = scheduledAt == null ||
          scheduledAt.isAfter(DateTime.now().add(const Duration(days: 7)));

      if (shouldRescheduleImmediately) {
        final firstFireAt = DateTime.now().add(const Duration(minutes: 1));
        await _scheduleIfChanged(
          firstFireAt,
          notificationTitle: notificationTitle,
          notificationBody: notificationBody,
        );
      }
    }
  }

  DateTime? _getScheduledReminderAt() {
    final storedValue = _prefs.getString(_keyReminderScheduledAt);
    if (storedValue == null || storedValue.isEmpty) {
      return null;
    }

    return DateTime.tryParse(storedValue);
  }

  Future<void> _scheduleIfChanged(
    DateTime firstFireAt, {
    String? notificationTitle,
    String? notificationBody,
  }) async {
    final scheduledAt = _getScheduledReminderAt();
    if (scheduledAt != null && scheduledAt.isAtSameMomentAs(firstFireAt)) {
      return;
    }

    final title = notificationTitle ?? _defaultNotificationTitle;
    final body = notificationBody ?? _defaultNotificationBody;

    await _notificationService.schedulePriceUpdateReminder(
      firstFireAt: firstFireAt,
      title: title,
      body: body,
    );
    await _prefs.setString(
      _keyReminderScheduledAt,
      firstFireAt.toIso8601String(),
    );
  }

  Future<void> handleNotificationTap() async {
    await setPendingPopup(true);
  }

  Future<void> setPendingPopup(bool value) async {
    await _prefs.setBool(_keyPendingPopup, value);
  }

  bool get hasPendingPopup => _prefs.getBool(_keyPendingPopup) ?? false;

  Future<void> clearPendingPopup() async {
    await _prefs.remove(_keyPendingPopup);
  }

  Future<int> getStaleProductCount() async {
    return _priceHistoryService.getStaleProductCount(reminderMonths);
  }

  Future<bool> requestPermissionAndSync() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final granted = await _notificationService.requestPermission();

    if (granted) {
      await syncReminderSchedule();
    }

    return granted;
  }
}
