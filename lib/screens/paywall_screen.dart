import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';

const _pink = Color(0xFF5BC8F5);

/// PaywallScreen: Adapty UI paywall (placementId: `fonkii_premium`) with a
/// native Dart fallback. Handles the `show_lifetime_plan` custom action by
/// opening the "View more plans" popup.
class PaywallScreen {
  /// Show the Adapty paywall. Returns `true` if the user became premium during
  /// the session (purchase or restore succeeded).
  static Future<bool> show(BuildContext context) async {
    final sub = SubscriptionService.instance;
    // Force Korean locale for the Adapty paywall presentation.
    AdaptyPaywall? paywall;
    try {
      paywall = await Adapty().getPaywall(
        placementId: 'fonkii_premium',
        locale: 'ko',
      );
    } catch (e) {
      debugPrint('getPaywall error: $e');
    }

    if (paywall != null && context.mounted) {
      try {
        final view = await AdaptyUI().createPaywallView(paywall: paywall);
        // ignore: use_build_context_synchronously
        final observer = _PaywallObserver(context);
        AdaptyUI().registerPaywallEventsListener(observer, view.id);
        await AdaptyUI().presentPaywallView(view);
        await observer.done.future;
        AdaptyUI().unregisterPaywallEventsListener(view.id);
        return sub.isPremiumNow;
      } catch (e) {
        debugPrint('Adapty UI paywall error, falling back: $e');
      }
    }

    if (!context.mounted) return sub.isPremiumNow;
    // Fallback: native Dart bottom sheet
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NativePaywallSheet(),
    );
    return result ?? false;
  }

  /// Show the "View more plans" lifetime popup directly (triggered by the
  /// `show_lifetime_plan` custom action, or manually).
  static Future<void> showLifetimePopup(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _LifetimePlanSheet(),
    );
  }
}

class _PaywallObserver extends AdaptyUIPaywallsEventsObserver {
  _PaywallObserver(this.context);
  final BuildContext context;
  final done = Completer<void>();

  void _complete() {
    if (!done.isCompleted) done.complete();
  }

  @override
  void paywallViewDidAppear(AdaptyUIPaywallView view) {}

  @override
  void paywallViewDidDisappear(AdaptyUIPaywallView view) {
    _complete();
  }

  @override
  Future<void> paywallViewDidPerformAction(
      AdaptyUIPaywallView view, AdaptyUIAction action) async {
    if (action is CustomAction && action.action == 'show_lifetime_plan') {
      PaywallScreen.showLifetimePopup(context);
      return;
    }
    // Terms / Privacy / external link buttons
    if (action is OpenUrlAction) {
      final uri = Uri.tryParse(action.url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    // Default: close/androidBack dismiss
    switch (action) {
      case const CloseAction():
      case const AndroidSystemBackAction():
        view.dismiss();
        break;
      default:
        break;
    }
  }

  @override
  void paywallViewDidFinishPurchase(
    AdaptyUIPaywallView view,
    AdaptyPaywallProduct product,
    AdaptyPurchaseResult purchaseResult,
  ) {
    view.dismiss();
    SubscriptionService.instance.refreshStatus();
  }

  @override
  void paywallViewDidFailPurchase(
      AdaptyUIPaywallView view, AdaptyPaywallProduct product, AdaptyError error) {}

  @override
  void paywallViewDidFinishRestore(
      AdaptyUIPaywallView view, AdaptyProfile profile) {
    view.dismiss();
    SubscriptionService.instance.refreshStatus();
  }

  @override
  void paywallViewDidFailRestore(AdaptyUIPaywallView view, AdaptyError error) {}

  @override
  void paywallViewDidFailRendering(AdaptyUIPaywallView view, AdaptyError error) {
    _complete();
  }

  @override
  void paywallViewDidFailLoadingProducts(
      AdaptyUIPaywallView view, AdaptyError error) {}

  @override
  void paywallViewDidSelectProduct(
      AdaptyUIPaywallView view, String productId) {}

  @override
  void paywallViewDidStartPurchase(
      AdaptyUIPaywallView view, AdaptyPaywallProduct product) {}

  @override
  void paywallViewDidStartRestore(AdaptyUIPaywallView view) {}
}

// Completer import via dart:async
// ignore: directives_ordering

// ══════════════════════════════════════════════════════════════════════════
// Native fallback paywall (weekly / yearly)
// ══════════════════════════════════════════════════════════════════════════

class _NativePaywallSheet extends StatefulWidget {
  const _NativePaywallSheet();

  @override
  State<_NativePaywallSheet> createState() => _NativePaywallSheetState();
}

class _NativePaywallSheetState extends State<_NativePaywallSheet> {
  final _sub = SubscriptionService.instance;
  bool _loading = false;
  String? _error;
  int _selectedPlan = 0; // 0 = weekly, 1 = yearly

  @override
  void initState() {
    super.initState();
    _sub.loadProducts();
  }

  Future<void> _purchase() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final success = _selectedPlan == 0
          ? await _sub.purchaseWeekly()
          : await _sub.purchaseYearly();
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '구매 처리 중 오류가 발생했습니다';
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final success = await _sub.restorePurchase();
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _loading = false;
          _error = '복원할 구독이 없습니다';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '복원 중 오류가 발생했습니다';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewPadding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                size: 36, color: _pink),
          )
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 16),
          const Text('프리미엄으로 업그레이드',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('모든 기능을 제한 없이 사용하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          const _FeatureRow(icon: Icons.text_fields, text: '모든 폰트 스타일'),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.translate, text: '번역 무제한'),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.emoji_emotions, text: '이모티콘/특수문자 전체'),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.gif_box, text: 'GIF 무제한'),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.favorite, text: '즐겨찾기'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _PlanCard(
                  title: '주간',
                  price: '₩4,900/주',
                  originalPrice: '₩6,900',
                  badge: '출시 이벤트',
                  selected: _selectedPlan == 0,
                  onTap: () => setState(() => _selectedPlan = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanCard(
                  title: '연간',
                  price: '₩59,900/년',
                  selected: _selectedPlan == 1,
                  onTap: () => setState(() => _selectedPlan = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading
                ? null
                : () => PaywallScreen.showLifetimePopup(context),
            child: Text('평생 이용권 보기',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _purchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _pink.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('1주 무료체험 시작',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          Text('무료체험 후 자동 결제 · 언제든 해지 가능',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _loading ? null : _restore,
                child: Text('구매 복원',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ),
              Text('·', style: TextStyle(color: Colors.grey.shade400)),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('나중에',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Lifetime plan popup (from custom action "show_lifetime_plan")
// ══════════════════════════════════════════════════════════════════════════

class _LifetimePlanSheet extends StatefulWidget {
  const _LifetimePlanSheet();

  @override
  State<_LifetimePlanSheet> createState() => _LifetimePlanSheetState();
}

class _LifetimePlanSheetState extends State<_LifetimePlanSheet> {
  final _sub = SubscriptionService.instance;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub.loadProducts();
  }

  Future<void> _purchase() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final success = await _sub.purchaseLifetime();
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '구매 처리 중 오류가 발생했습니다';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewPadding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.all_inclusive, size: 36, color: _pink),
          ),
          const SizedBox(height: 16),
          const Text('평생 이용권',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('한 번 결제하고 평생 사용하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '평생 이용권은 번역 기능을 제외한 모든 기능을 제공합니다.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _FeatureRow(icon: Icons.text_fields, text: '모든 폰트 스타일'),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.emoji_emotions, text: '이모티콘/특수문자 전체'),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.gif_box, text: 'GIF 무제한'),
          const SizedBox(height: 8),
          const _FeatureRow(icon: Icons.favorite, text: '즐겨찾기'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _purchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _pink.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('평생 이용권 구매',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: Text('닫기',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════════════════

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _pink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _pink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        const Icon(Icons.check_circle, size: 20, color: _pink),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    this.originalPrice,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
  final String? originalPrice;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _pink : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? _pink.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: _pink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? _pink : Colors.black87)),
            const SizedBox(height: 4),
            if (originalPrice != null)
              Text(originalPrice!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough)),
            Text(price,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? _pink : Colors.black54)),
          ],
        ),
      ),
    );
  }
}
