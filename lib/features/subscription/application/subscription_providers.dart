import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_providers.g.dart';

bool isSubscriptionPlatformSupported({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

bool get supportsSubscriptionsOnCurrentPlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

bool get debugPremiumOverrideEnabled => kDebugMode;

@riverpod
class SubscriptionController extends _$SubscriptionController {
  @override
  FutureOr<bool> build() async {
    if (debugPremiumOverrideEnabled) {
      return true;
    }
    if (!supportsSubscriptionsOnCurrentPlatform) {
      return false;
    }
    await _initRevenueCat();
    return _checkPremiumStatus();
  }

  Future<void> _initRevenueCat() async {
    if (debugPremiumOverrideEnabled) return;
    if (!supportsSubscriptionsOnCurrentPlatform) return;

    try {
      final configuration = PurchasesConfiguration(
        Platform.isIOS ? 'appl_apiKey' : 'goog_apiKey',
      );
      await Purchases.configure(configuration);
    } catch (e) {
      debugPrint('RevenueCat init failed: $e');
    }
  }

  Future<bool> _checkPremiumStatus() async {
    if (debugPremiumOverrideEnabled) return true;
    if (!supportsSubscriptionsOnCurrentPlatform) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchasePremium(Package package) async {
    if (debugPremiumOverrideEnabled) {
      state = const AsyncData(true);
      return true;
    }
    if (!supportsSubscriptionsOnCurrentPlatform) {
      state = const AsyncData(false);
      return false;
    }

    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final customerInfo = purchaseResult.customerInfo;
      final isPremium =
          customerInfo.entitlements.all['premium']?.isActive ?? false;
      state = AsyncData(isPremium);
      return isPremium;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (debugPremiumOverrideEnabled) {
      state = const AsyncData(true);
      return;
    }
    if (!supportsSubscriptionsOnCurrentPlatform) {
      state = const AsyncData(false);
      return;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium =
          customerInfo.entitlements.all['premium']?.isActive ?? false;
      state = AsyncData(isPremium);
    } catch (e) {
      debugPrint('Restore failed: $e');
    }
  }
}

@riverpod
Future<List<Offering>> offerings(OfferingsRef ref) async {
  if (debugPremiumOverrideEnabled) return [];
  if (!supportsSubscriptionsOnCurrentPlatform) return [];

  try {
    final offerings = await Purchases.getOfferings();
    return offerings.all.values.toList();
  } catch (e) {
    debugPrint('Failed to get offerings: $e');
    return [];
  }
}
