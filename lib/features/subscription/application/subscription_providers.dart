import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_providers.g.dart';

@riverpod
class SubscriptionController extends _$SubscriptionController {
  @override
  FutureOr<bool> build() async {
    await _initRevenueCat();
    return _checkPremiumStatus();
  }

  Future<void> _initRevenueCat() async {
    if (kIsWeb) return;
    try {
      final configuration = PurchasesConfiguration(
        Platform.isIOS ? 'appl_apiKey' : 'goog_apiKey',
      );
      await Purchases.configure(configuration);
    } catch (e) {
      debugPrint('RevenueCat init failed (expected on desktop): $e');
    }
  }

  Future<bool> _checkPremiumStatus() async {
    if (kIsWeb) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchasePremium(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      final customerInfo = await Purchases.getCustomerInfo();
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
  if (kIsWeb) return [];
  try {
    final offerings = await Purchases.getOfferings();
    return offerings.all.values.toList();
  } catch (e) {
    debugPrint('Failed to get offerings (expected on desktop): $e');
    return [];
  }
}
