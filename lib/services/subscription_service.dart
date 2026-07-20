import 'dart:async';
import 'package:flutter/foundation.dart';
// widgets.dart additionally provides WidgetsBinding / WidgetsBindingObserver /
// AppLifecycleState needed for the resume-time refresh below.
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:adapty_flutter/adapty_flutter.dart';

import 'trial_notification_service.dart';

const _premiumAccess = 'premium';
// Product identifiers used for matching within the Adapty paywall.
// Matching is case-insensitive and substring-based, so both vendor product IDs
// and Adapty reference names (e.g., "WEEKLY", "ANNUAL") work.
const _weeklyMatchKeys = ['weekly', 'WEEKLY'];
const _yearlyMatchKeys = ['yearly', 'annual', 'ANNUAL'];
const _paywallPlacementId = 'fonkii_premium';

enum SubscriptionTier { free, premium }

class SubscriptionService with WidgetsBindingObserver {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  static const bool debugForceFree = false; // TODO: REMOVE
  static const bool debugForcePremium = false; // TODO: REMOVE - 테스트용 프리미엄 강제

  final _tierNotifier = ValueNotifier<SubscriptionTier>(SubscriptionTier.free);
  ValueListenable<SubscriptionTier> get tierListenable => _tierNotifier;

  SubscriptionTier get currentTier => _tierNotifier.value;

  // Back-compat getters
  bool get isPremiumNow =>
      !debugForceFree && currentTier != SubscriptionTier.free;
  ValueListenable<bool> get premiumStatus {
    final n = ValueNotifier<bool>(isPremiumNow);
    _tierNotifier.addListener(() {
      n.value = isPremiumNow;
    });
    return n;
  }

  // Translation gating: only paid weekly/yearly subscribers translate
  // unlimited. Free tier is blocked at the keyboard level, and
  // free-trial premium users are throttled to 5/day.
  bool get canTranslateUnlimited =>
      !debugForceFree && currentTier == SubscriptionTier.premium && !_isInTrialNow;

  /// Cached view of `_activeTrialSubscription(lastProfile) != null` for
  /// synchronous getters. Updated on every `_applyProfile` call. DEBUG
  /// forces it to false to keep development unthrottled.
  bool _isInTrialNow = false;

  AdaptyPaywall? _paywall;
  List<AdaptyPaywallProduct>? _products;

  // ── 초기화 ─────────────────────────────────────────────────────────────
  Future<void> initialize(String apiKey) async {
    // Observe app lifecycle so a subscription that lapsed while the app was
    // backgrounded gets re-fetched the moment the user returns — without
    // this, the App Group (and therefore the keyboard extension) could keep
    // serving a stale `is_premium=true` until the next cold launch.
    WidgetsBinding.instance.addObserver(this);
    try {
      await Adapty().activate(
        configuration: AdaptyConfiguration(apiKey: apiKey),
      );
      await refreshStatus();
      Adapty().didUpdateProfileStream.listen((profile) {
        _applyProfile(profile);
      });
      // Fire-and-forget: reinstalls / new devices / fresh Xcode installs
      // get a brand new anonymous Adapty profile with no purchase history
      // synced yet, even when the same Apple ID has an active subscription
      // or has already used its introductory offer. `refreshStatus()` alone
      // only reads the (empty) profile Adapty already has server-side, so
      // without this, a returning subscriber's paywall wrongly shows the
      // trial-eligible offer right up until they tap "restore" themselves.
      // Deliberately not awaited — must never delay app startup.
      unawaited(_maybeSilentRestore());
    } catch (e) {
      debugPrint('Adapty init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget: pulls the latest Adapty profile and pushes the
      // result to the App Group via _applyProfile → _syncTierToAppGroup.
      refreshStatus();
    }
  }

  // ── 프리미엄 여부 확인 ────────────────────────────────────────────────
  Future<bool> isPremium() async {
    await refreshStatus();
    return isPremiumNow;
  }

  SubscriptionTier _computeTier(AdaptyProfile profile) {
    if (debugForcePremium) return SubscriptionTier.premium; // TODO: REMOVE - 테스트용
    if (profile.accessLevels[_premiumAccess]?.isActive == true) {
      return SubscriptionTier.premium;
    }
    return SubscriptionTier.free;
  }

  /// The active subscription still in its introductory free trial, if any.
  /// Trial users keep premium-tier gating (so they can open the translate
  /// tab) but are *not* `canTranslateUnlimited` — the keyboard's 10/day
  /// counter applies. Once the trial converts to a paid renewal,
  /// `activeIntroductoryOfferType` clears and translation becomes
  /// unlimited. `expiresAt` on the returned subscription also drives the
  /// trial-ending local notification (see `_applyProfile`).
  ///
  /// Adapty exposes the offer kind on both subscriptions and access levels.
  /// We check the active subscription so paid intro offers (`pay_as_you_go`,
  /// `pay_up_front`) don't get throttled — only literal `free_trial` does.
  AdaptySubscription? _activeTrialSubscription(AdaptyProfile profile) {
    for (final sub in profile.subscriptions.values) {
      if (sub.isActive && sub.activeIntroductoryOfferType == 'free_trial') {
        return sub;
      }
    }
    return null;
  }

  void _applyProfile(AdaptyProfile profile) {
    final realTier = _computeTier(profile);
    _tierNotifier.value = realTier;
    final trialSub = _activeTrialSubscription(profile);
    final inTrial = trialSub != null;
    _isInTrialNow = inTrial;
    _syncTierToAppGroup(realTier, isInTrial: inTrial);

    // Re-evaluated on every profile apply (resume, restore, purchase, live
    // profile updates) rather than only on a trial→non-trial transition:
    // still in trial → schedule if nothing is pending yet (no-op if already
    // scheduled); no longer in trial (cancelled, converted to paid, or was
    // never in one) → cancel any pending reminder. Both calls are fire-and-
    // forget and fail silently, so they can never block tier syncing.
    final expiresAt = trialSub?.expiresAt;
    if (inTrial && expiresAt != null) {
      unawaited(
        TrialNotificationService.instance.scheduleTrialExpiryIfNeeded(
          expiresAt,
        ),
      );
    } else {
      unawaited(TrialNotificationService.instance.cancelTrialExpiry());
    }
  }

  Future<void> refreshStatus() async {
    try {
      final profile = await Adapty().getProfile();
      _applyProfile(profile);
    } catch (_) {}
  }

  /// Silent, best-effort startup restore — runs on every cold launch. See
  /// the call site in `initialize()` for why this exists.
  ///
  /// Entirely invisible to the user by design: no loading indicator, no
  /// error surfaced on failure (a fresh/never-purchased profile is expected
  /// to "fail" here — that's not an error condition), and it never blocks
  /// app startup since the caller never awaits it. The explicit "복원"
  /// button / `restorePurchase()` and `paywallViewDidFailRestore` remain
  /// unchanged as the user-facing manual fallback.
  ///
  /// Deliberately NOT gated to "once per profile" — an earlier version
  /// persisted a `SharedPreferences` flag to skip repeat attempts, but that
  /// flag lives in the app's own sandboxed container, and there turned out
  /// to be no reliable way to guarantee it's wiped exactly when (and only
  /// when) the Adapty profile itself is fresh — e.g. reinstalling over an
  /// existing container (rather than a true delete) or a device/iCloud
  /// backup restore can bring the old flag back even though the app
  /// genuinely has purchase history that needs restoring. When that
  /// happens the flag silently disables restore forever, which is exactly
  /// the wrong failure mode (a returning subscriber keeps seeing the
  /// trial-eligible paywall). `restorePurchases()` costs nothing and shows
  /// nothing on screen, so just retrying it every launch is cheap
  /// insurance against that.
  Future<void> _maybeSilentRestore() async {
    final tierBefore = currentTier;
    final premiumBefore = isPremiumNow;
    var success = false;
    Object? error;
    // Tier computed directly from the profile `restorePurchases()` handed
    // back, BEFORE it goes through `_applyProfile`/`_tierNotifier` — lets
    // the log below tell apart "Adapty/Apple says this account has no
    // purchase to restore" from "the restore call worked but something
    // between `_applyProfile` and this log clobbered the notifier"
    // (e.g. `didUpdateProfileStream` firing concurrently with a stale
    // profile and racing the assignment).
    SubscriptionTier? restoredProfileTier;

    if (kDebugMode) {
      debugPrint(
        '🔥 [SubscriptionService] silent restore starting, '
        'tierBefore=$tierBefore isPremiumBefore=$premiumBefore',
      );
    }

    try {
      final profile = await Adapty().restorePurchases();
      restoredProfileTier = _computeTier(profile);
      _applyProfile(profile);
      success = true;
    } catch (e) {
      error = e;
    }

    if (kDebugMode) {
      debugPrint(
        '🔥 [SubscriptionService] silent restore attempted, success=$success '
        'tierBefore=$tierBefore restoredProfileTier=$restoredProfileTier '
        'tierAfter=$currentTier isPremiumAfter=$isPremiumNow'
        '${error != null ? ' error=$error' : ''}',
      );
    }
  }

  void _syncTierToAppGroup(SubscriptionTier tier, {bool isInTrial = false}) {
    try {
      const channel = MethodChannel('com.yunajung.fonki/appgroup');
      channel.invokeMethod('syncPremium', {
        'is_premium': debugForcePremium || tier != SubscriptionTier.free, // TODO: REMOVE - 테스트용
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
