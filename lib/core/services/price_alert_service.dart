import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/services/notification_service.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'price_alert_service.g.dart';

@Riverpod(keepAlive: true)
PriceAlertService priceAlertService(PriceAlertServiceRef ref) {
  return PriceAlertService(
    ref.watch(entryRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
}

/// Checks whether a newly recorded price should trigger an alert, and if so
/// fires a local notification.
///
/// Should be called from [AddEntryController.submitEntry] after a successful
/// insert, but only when [isPremium] is true.
class PriceAlertService {
  final EntryRepository _repo;
  final NotificationService _notifications;

  PriceAlertService(this._repo, this._notifications);

  /// Fetches the alert config and most recent historic price for [productId].
  /// If all conditions are met, fires a notification and returns true.
  Future<bool> checkAndNotify({
    required int productId,
    required String productName,
    required double newPrice,
    required bool isPremium,
    double? previousPrice,
  }) async {
    if (!isPremium) return false;

    try {
      final alert = await _repo.getPriceAlert(productId);
      if (alert == null || !alert.isEnabled) return false;

      final oldPrice = previousPrice ??
          (await _repo.getLatestEntryForProduct(productId))?.price;
      if (oldPrice == null) return false;
      if (oldPrice == 0) return false;

      final percentChange = ((newPrice - oldPrice) / oldPrice) * 100;
      final threshold = alert.thresholdPercent;

      if (percentChange.abs() >= threshold) {
        await _notifications.showPriceAlert(
          productName: productName,
          oldPrice: oldPrice,
          newPrice: newPrice,
          percentChange: percentChange,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('PriceAlertService.checkAndNotify error: $e');
      return false;
    }
  }
}
