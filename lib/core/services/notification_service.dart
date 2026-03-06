import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

/// Thin wrapper around [FlutterLocalNotificationsPlugin].
///
/// Call [initialize] once at app startup (before [runApp]).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialise the notifications plugin.
  /// Safe to call multiple times — only acts on the first call.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      // Some desktop platforms may not support this plugin
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Shows a price-alert notification.
  ///
  /// [productName] — the tracked product.
  /// [oldPrice] — the reference price.
  /// [newPrice] — the newly recorded price.
  /// [percentChange] — the signed percentage change (positive = increase).
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
}
