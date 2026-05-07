import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:adapty_flutter/adapty_flutter.dart';

const _premiumAccess = 'premium';   // weekly/yearly (unlocks everything incl. translation)
const _lifetimeAccess = 'lifetime'; // one-time (unlocks everything except translation)
// Product identifiers used for matching within the Adapty paywall.
// Matching is case-insensitive and substring-based, so both vendor product IDs
// and Adapty reference names (e.g., "WEEKLY", "ANNUAL", "LIFETIME") work.
const _weeklyMatchKeys = ['weekly', 'WEEKLY'];
const _yearlyMatchKeys = ['yearly', 'annual', 'ANNUAL'];
const _lifetimeMatchKeys = ['lifetime', 'LIFETIME'];
const _paywallPlacementId = 'fonkii_premium';

enum SubscriptionTier { free, premium, lifetime }

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  final _tierNotifier = ValueNotifier<SubscriptionTier>(SubscriptionTier.free);
  ValueListenable<SubscriptionTier> get tierListenable => _tierNotifier;

  /// Effective tier used for gating. In DEBUG builds we force `premium` to
  /// unlock all features for development/testing; release builds honor the
  /// real Adapty profile.
  SubscriptionTier get currentTier {
    if (kDebugMode) return SubscriptionTier.premium;
    return _tierNotifier.value;
  }

  // Back-compat getters
  bool get isPremiumNow => currentTier != SubscriptionTier.free;
  ValueListenable<bool> get premiumStatus {
    final n = ValueNotifier<bool>(isPremiumNow);
    _tierNotifier.addListener(() {
      n.value = isPremiumNow;
    });
    return n;
  }

  // Translation gating: only paid weekly/yearly subscribers translate
  // unlimited. Free tier is blocked at the keyboard level, lifetime is
  // blocked, and free-trial premium users are throttled to 10/day.
  bool get canTranslateUnlimited =>
      currentTier == SubscriptionTier.premium && !_isInTrialNow;

  /// Cached view of `_isInFreeTrial(lastProfile)` for synchronous getters.
  /// Updated on every `_applyProfile` call. DEBUG forces it to false to keep
  /// development unthrottled.
  bool _isInTrialNow = false;

  AdaptyPaywall? _paywall;
  List<AdaptyPaywallProduct>? _products;

  // ── 초기화 ─────────────────────────────────────────────────────────────
  Future<void> initialize(String apiKey) async {
    try {
      await Adapty().activate(
        configuration: AdaptyConfiguration(apiKey: apiKey),
      );
      await refreshStatus();
      Adapty().didUpdateProfileStream.listen((profile) {
        _applyProfile(profile);
      });
    } catch (e) {
      debugPrint('Adapty init error: $e');
    }
  }

  // ── 프리미엄 여부 확인 ────────────────────────────────────────────────
  Future<bool> isPremium() async {
    await refreshStatus();
    return isPremiumNow;
  }

  SubscriptionTier _computeTier(AdaptyProfile profile) {
    if (profile.accessLevels[_premiumAccess]?.isActive == true) {
      return SubscriptionTier.premium;
    }
    if (profile.accessLevels[_lifetimeAccess]?.isActive == true) {
      return SubscriptionTier.lifetime;
    }
    return SubscriptionTier.free;
  }

  /// Whether the user's currently-active premium subscription is still in its
  /// introductory free trial. Trial users keep premium-tier gating (so they
  /// can open the translate tab) but are *not* `canTranslateUnlimited` — the
  /// keyboard's 10/day counter applies. Once the trial converts to a paid
  /// renewal, `activeIntroductoryOfferType` clears and translation becomes
  /// unlimited.
  ///
  /// Adapty exposes the offer kind on both subscriptions and access levels.
  /// We check the active subscription so paid intro offers (`pay_as_you_go`,
  /// `pay_up_front`) don't get throttled — only literal `free_trial` does.
  bool _isInFreeTrial(AdaptyProfile profile) {
    for (final sub in profile.subscriptions.values) {
      if (sub.isActive && sub.activeIntroductoryOfferType == 'free_trial') {
        return true;
      }
    }
    return false;
  }

  void _applyProfile(AdaptyProfile profile) {
    final realTier = _computeTier(profile);
    _tierNotifier.value = realTier;
    final inTrial = _isInFreeTrial(profile);
    // In DEBUG, sync as premium to keyboard extension so it unlocks too.
    // DEBUG also force-clears the trial flag so testers get unlimited
    // translation without touching their real Adapty profile.
    final effective = kDebugMode ? SubscriptionTier.premium : realTier;
    final effectiveTrial = kDebugMode ? false : inTrial;
    _isInTrialNow = effectiveTrial;
    _syncTierToAppGroup(effective, isInTrial: effectiveTrial);
  }

  Future<void> refreshStatus() async {
    try {
      final profile = await Adapty().getProfile();
      _applyProfile(profile);
    } catch (_) {}
  }

  void _syncTierToAppGroup(SubscriptionTier tier, {bool isInTrial = false}) {
    try {
      const channel = MethodChannel('com.yunajung.fonki/appgroup');
      channel.invokeMethod('syncPremium', {
        'is_premium': tier != SubscriptionTier.free,
        'tier': tier.name,
        // Trial users keep tier=premium (so the lock screen + translate tab
        // open up) but lose unlimited translation, which routes them through
        // the keyboard's 10/day daily counter.
        'can_translate_unlimited':
            tier == SubscriptionTier.premium && !isInTrial,
      });
    } catch (_) {}
  }

  // ── Paywall ───────────────────────────────────────────────────────────
  Future<AdaptyPaywall?> getPremiumPaywall() async {
    try {
      return await Adapty().getPaywall(placementId: _paywallPlacementId);
    } catch (e) {
      debugPrint('getPaywall error: $e');
      return null;
    }
  }

  // ── 상품 로드 (native fallback용) ────────────────────────────────────
  Future<void> loadProducts() async {
    try {
      _paywall = await Adapty().getPaywall(placementId: _paywallPlacementId);
      if (_paywall != null) {
        _products = await Adapty().getPaywallProducts(paywall: _paywall!);
      }
    } catch (e) {
      debugPrint('Adapty loadProducts error: $e');
    }
  }

  AdaptyPaywallProduct? _findProduct(List<String> keys) {
    final list = _products;
    if (list == null || list.isEmpty) return null;
    final lowerKeys = keys.map((k) => k.toLowerCase()).toList();
    for (final p in list) {
      final id = p.vendorProductId.toLowerCase();
      if (lowerKeys.any((k) => id.contains(k))) return p;
    }
    return null;
  }

  AdaptyPaywallProduct? get weeklyProduct =>
      _findProduct(_weeklyMatchKeys) ?? _products?.first;
  AdaptyPaywallProduct? get yearlyProduct =>
      _findProduct(_yearlyMatchKeys) ??
      (_products != null && _products!.length >= 2 ? _products![1] : null);
  AdaptyPaywallProduct? get lifetimeProduct =>
      _findProduct(_lifetimeMatchKeys) ?? _products?.last;

  // ── 주간 구독 구매 ────────────────────────────────────────────────────
  Future<bool> purchaseWeekly() async {
    try {
      final product = weeklyProduct;
      if (product == null) return false;
      await Adapty().makePurchase(product: product);
      await refreshStatus();
      return isPremiumNow;
    } catch (e) {
      if (e is AdaptyError && e.code == AdaptyErrorCode.paymentCancelled) {
        return false;
      }
      rethrow;
    }
  }

  // ── 평생 구매 ─────────────────────────────────────────────────────────
  Future<bool> purchaseLifetime() async {
    try {
      final product = lifetimeProduct;
      if (product == null) return false;
      await Adapty().makePurchase(product: product);
      await refreshStatus();
      return isPremiumNow;
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
      await refreshStatus();
      return isPremiumNow;
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
      _applyProfile(profile);
      return isPremiumNow;
    } catch (_) {
      return false;
    }
  }
}
