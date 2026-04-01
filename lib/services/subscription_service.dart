import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:purchases_flutter/purchases_flutter.dart'; // 결제 구현 시 활성화

const _weeklyProductId = 'weekly_5000';
const _entitlementId = 'premium';

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  final _premiumNotifier = ValueNotifier<bool>(false);
  ValueListenable<bool> get premiumStatus => _premiumNotifier;
  bool get isPremiumNow => _premiumNotifier.value;

  // ── 초기화 (purchases_flutter 제거됨 — 스텁) ─────────────────────────
  Future<void> initialize(String apiKey) async {
    // TODO: purchases_flutter 복원 후 구현
    // await Purchases.setLogLevel(LogLevel.debug);
    // final config = PurchasesConfiguration(apiKey);
    // await Purchases.configure(config);
    // await _refreshStatus();
    // Purchases.addCustomerInfoUpdateListener((info) {
    //   _premiumNotifier.value = _checkEntitlement(info);
    // });
  }

  // ── 프리미엄 여부 확인 ────────────────────────────────────────────────
  Future<bool> isPremium() async {
    return _premiumNotifier.value;
  }

  // ── 주간 구독 구매 (스텁) ─────────────────────────────────────────────
  Future<bool> purchaseWeekly() async {
    // TODO: purchases_flutter 복원 후 구현
    return false;
  }

  // ── 구매 복원 (스텁) ──────────────────────────────────────────────────
  Future<bool> restorePurchase() async {
    // TODO: purchases_flutter 복원 후 구현
    return false;
  }
}
