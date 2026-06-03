import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/subscription_service.dart';

const _pink = Color(0xFF5BC8F5);

/// PaywallScreen: Adapty UI paywall (placementId: `fonkii_premium`) with a
/// native Dart fallback (monthly / yearly only).
class PaywallScreen {
  /// Show the Adapty paywall. Returns `true` if the user became premium during
  /// the session (purchase or restore succeeded).
  ///
  /// Falls back to a native Dart sheet only when the Adapty UI paywall could
  /// not be *created* (no paywall config, `createPaywallView` threw). Once a
  /// view object exists the user has already seen — or is about to see — the
  /// real paywall, so any error during presentation/dismissal is swallowed
  /// rather than triggering a second sheet on top.
  static Future<bool> show(BuildContext context) async {
    final sub = SubscriptionService.instance;
    final langCode = Localizations.localeOf(context).languageCode;
    final paywallLocale = langCode == 'ko' ? 'ko' : 'en';
    AdaptyPaywall? paywall;
    try {
      paywall = await Adapty().getPaywall(
        placementId: 'fonkii_premium',
        locale: paywallLocale,
      );
    } catch (e) {
      debugPrint('getPaywall error: $e');
    }

    AdaptyUIPaywallView? view;
    if (paywall != null && context.mounted) {
      try {
        view = await AdaptyUI().createPaywallView(paywall: paywall);
      } catch (e) {
        debugPrint('Adapty UI createPaywallView error, falling back: $e');
      }
    }

    if (view != null) {
      // ignore: use_build_context_synchronously
      final observer = _PaywallObserver(context);
      AdaptyUI().registerPaywallEventsListener(observer, view.id);
      try {
        await AdaptyUI().presentPaywallView(view);
        await observer.done.future;
      } catch (e) {
        debugPrint('Adapty UI present/dismiss error: $e');
      } finally {
        try {
          AdaptyUI().unregisterPaywallEventsListener(view.id);
        } catch (_) {}
      }
      // The user saw the Adapty UI paywall. Never show the Flutter fallback
      // on top, regardless of any transient errors above.
      return sub.isPremiumNow;
    }

    if (!context.mounted) return sub.isPremiumNow;
    // Fallback: native Dart bottom sheet — only reached when no Adapty view
    // could be constructed.
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
    _sub.loadProducts().then((_) {
      if (mounted) setState(() {});
    });
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
      final l = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _error = l.paywallErrorPurchase;
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
        final l = AppLocalizations.of(context)!;
        setState(() {
          _loading = false;
          _error = l.paywallErrorNoSub;
        });
      }
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _error = l.paywallErrorRestore;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
          Text(l.paywallUpgradeTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(l.paywallUpgradeSubtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          _FeatureRow(icon: Icons.text_fields, text: l.paywallFeatureFonts),
          const SizedBox(height: 8),
          _FeatureRow(icon: Icons.translate, text: l.paywallFeatureTranslate),
          const SizedBox(height: 8),
          _FeatureRow(icon: Icons.emoji_emotions, text: l.paywallFeatureEmoticon),
          const SizedBox(height: 8),
          _FeatureRow(icon: Icons.gif_box, text: l.paywallFeatureGif),
          const SizedBox(height: 8),
          _FeatureRow(icon: Icons.favorite, text: l.paywallFeatureFavorite),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _PlanCard(
                  title: l.paywallPlanWeekly,
                  price: '${_sub.weeklyProduct?.price.localizedString ?? '–'}${l.paywallPerWeek}',
                  badge: l.paywallLaunchBadge,
                  selected: _selectedPlan == 0,
                  onTap: () => setState(() => _selectedPlan = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanCard(
                  title: l.paywallPlanYearly,
                  price: '${_sub.yearlyProduct?.price.localizedString ?? '–'}${l.paywallPerYear}',
                  selected: _selectedPlan == 1,
                  onTap: () => setState(() => _selectedPlan = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  : Text(l.paywallStartTrial,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          Text(l.paywallTrialNote,
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
                child: Text(l.paywallRestore,
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ),
              Text('·', style: TextStyle(color: Colors.grey.shade400)),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.paywallLater,
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
    this.badge,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
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
