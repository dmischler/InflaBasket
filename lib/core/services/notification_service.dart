import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

part 'notification_service.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _priceUpdateReminderId = 999;

  static Function()? onPriceUpdateNotificationTap;
  static bool _launchedFromPriceUpdateNotification = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final timezoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneName));
      } catch (e) {
        debugPrint('NotificationService timezone fallback: $e');
      }

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final response = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        if (response?.id == _priceUpdateReminderId) {
          _launchedFromPriceUpdateNotification = true;
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.id == _priceUpdateReminderId) {
      _launchedFromPriceUpdateNotification = true;
      onPriceUpdateNotificationTap?.call();
    }
  }

  static bool consumeDidLaunchFromPriceUpdateNotification() {
    final launched = _launchedFromPriceUpdateNotification;
    _launchedFromPriceUpdateNotification = false;
    return launched;
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final result = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final result = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return result ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService.requestPermission error: $e');
      return false;
    }
  }

  Future<void> showPriceAlert({
    required String productName,
    required double oldPrice,
    required double newPrice,
    required double percentChange,
  }) async {
    if (!_initialized) return;
    try {
      final direction = percentChange >= 0 ? 'up' : 'down';
      final pct = percentChange.abs().toStringAsFixed(1);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'price_alerts',
          'Price Alerts',
          channelDescription: 'Notifications when a product price changes',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        productName.hashCode & 0x7FFFFFFF,
        'Price alert: $productName',
        'Price went $direction by $pct% '
            '(${oldPrice.toStringAsFixed(2)} → ${newPrice.toStringAsFixed(2)})',
        details,
      );
    } catch (e) {
      debugPrint('NotificationService.showPriceAlert error: $e');
    }
  }

  Future<void> schedulePriceUpdateReminder({
    required DateTime firstFireAt,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    try {
      await _plugin.zonedSchedule(
        _priceUpdateReminderId,
        title,
        body,
        tz.TZDateTime.from(firstFireAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'price_update_reminders',
            'Price Update Reminders',
            channelDescription:
                'Weekly reminders to update stale product prices',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
          'NotificationService: Scheduled weekly reminder starting at $firstFireAt');
    } catch (e) {
      debugPrint('NotificationService.schedulePriceUpdateReminder error: $e');
    }
  }

  Future<void> scheduleImmediateReminder({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    try {
      final now = DateTime.now();
      final firstFire = now.add(const Duration(minutes: 1));

      await schedulePriceUpdateReminder(
        firstFireAt: firstFire,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleImmediateReminder error: $e');
    }
  }

  Future<void> cancelPriceUpdateReminder() async {
    if (!_initialized) return;

    try {
      await _plugin.cancel(_priceUpdateReminderId);
      debugPrint('NotificationService: Cancelled price update reminder');
    } catch (e) {
      debugPrint('NotificationService.cancelPriceUpdateReminder error: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();
      debugPrint('NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('NotificationService.cancelAllReminders error: $e');
    }
  }
}
