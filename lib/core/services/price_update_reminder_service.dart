import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inflabasket/core/services/notification_service.dart';
import 'package:inflabasket/core/services/price_history_service.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

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

  static const String _keyTitleEn = 'Price Update Reminder';
  static const String _keyBodyEn =
      'Some of your product prices may be outdated. Tap to check.';
  static const String _keyPendingPopup = 'price_update_pending_popup';

  PriceUpdateReminderService(
    this._notificationService,
    this._priceHistoryService,
    this._settings,
    this._prefs,
  );

  bool get isReminderEnabled => _settings.priceUpdateReminderEnabled;
  int get reminderMonths => _settings.priceUpdateReminderMonths;

  Future<void> syncReminderSchedule() async {
    if (!isReminderEnabled) {
      await _notificationService.cancelPriceUpdateReminder();
      return;
    }

    final staleCount = await _priceHistoryService.getStaleProductCount(
      reminderMonths,
    );

    if (staleCount == 0) {
      await _notificationService.cancelPriceUpdateReminder();

      final nextDueDate = await _priceHistoryService.getNextProductDueDate(
        reminderMonths,
      );

      if (nextDueDate != null) {
        await _notificationService.schedulePriceUpdateReminder(
          firstFireAt: nextDueDate,
          title: _keyTitleEn,
          body: _keyBodyEn,
        );
      }
    } else {
      await _notificationService.scheduleImmediateReminder(
        title: _keyTitleEn,
        body: _keyBodyEn,
      );
    }
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
