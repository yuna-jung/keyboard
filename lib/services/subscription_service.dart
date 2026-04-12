import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:adapty_flutter/adapty_flutter.dart';

const _entitlementId = 'premium';
const _weeklyProductId = 'weekly_4900';
const _yearlyProductId = 'yearly_59900';

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  final _premiumNotifier = ValueNotifier<bool>(false);
  ValueListenable<bool> get premiumStatus => _premiumNotifier;
  bool get isPremiumNow => _premiumNotifier.value;

  AdaptyPaywall? _paywall;
  List<AdaptyPaywallProduct>? _products;

  // ── 초기화 ─────────────────────────────────────────────────────────────
  Future<void> initialize(String apiKey) async {
    try {
      await Adapty().activate(
        configuration: AdaptyConfiguration(apiKey: apiKey),
      );
      await _refreshStatus();

      // 구독 상태 변경 리스너
      Adapty().didUpdateProfileStream.listen((profile) {
        _premiumNotifier.value = _checkEntitlement(profile);
      });
    } catch (e) {
      debugPrint('Adapty init error: $e');
    }
  }

  // ── 프리미엄 여부 확인 ────────────────────────────────────────────────
  Future<bool> isPremium() async {
    await _refreshStatus();
    return _premiumNotifier.value;
  }

  bool _checkEntitlement(AdaptyProfile profile) {
    return profile.accessLevels[_entitlementId]?.isActive == true;
  }

  Future<void> _refreshStatus() async {
    try {
      final profile = await Adapty().getProfile();
      _premiumNotifier.value = _checkEntitlement(profile);
      _syncPremiumToAppGroup(_premiumNotifier.value);
    } catch (_) {}
  }

  void _syncPremiumToAppGroup(bool isPremium) {
    // Sync premium status to App Group for keyboard extension
    try {
      const channel = MethodChannel('com.yourapp.fontkeyboard/appgroup');
      channel.invokeMethod('syncPremium', {'is_premium': isPremium});
    } catch (_) {}
  }

  // ── 상품 로드 ─────────────────────────────────────────────────────────
  Future<void> loadProducts() async {
    try {
      _paywall = await Adapty().getPaywall(placementId: 'default');
      if (_paywall != null) {
        _products = await Adapty().getPaywallProducts(paywall: _paywall!);
      }
    } catch (e) {
      debugPrint('Adapty loadProducts error: $e');
    }
  }

  AdaptyPaywallProduct? get weeklyProduct {
    return _products?.firstWhere(
      (p) => p.vendorProductId == _weeklyProductId,
      orElse: () => _products!.first,
    );
  }

  AdaptyPaywallProduct? get yearlyProduct {
    return _products?.firstWhere(
      (p) => p.vendorProductId == _yearlyProductId,
      orElse: () => _products!.last,
    );
  }

  // ── 주간 구독 구매 ────────────────────────────────────────────────────
  Future<bool> purchaseWeekly() async {
    try {
      final product = weeklyProduct;
      if (product == null) return false;
      await Adapty().makePurchase(product: product);
      await _refreshStatus();
      return _premiumNotifier.value;
    } catch (e) {
      if (e is AdaptyError && e.code == AdaptyErrorCode.paymentCancelled) {
        return false;
      }
      rethrow;
    }
  }

  // ── 연간 구독 구매 ────────────────────────────────────────────────────
  Future<bool> purchaseYearly() async {
    try {
      final product = yearlyProduct;
      if (product == null) return false;
      await Adapty().makePurchase(product: product);
      await _refreshStatus();
      return _premiumNotifier.value;
    } catch (e) {
      if (e is AdaptyError && e.code == AdaptyErrorCode.paymentCancelled) {
        return false;
      }
      rethrow;
    }
  }

  // ── 구매 복원 ─────────────────────────────────────────────────────────
  Future<bool> restorePurchase() async {
    try {
      final profile = await Adapty().restorePurchases();
      final active = _checkEntitlement(profile);
      _premiumNotifier.value = active;
      return active;
    } catch (_) {
      return false;
    }
  }
}
