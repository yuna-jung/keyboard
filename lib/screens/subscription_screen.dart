import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';

const _pink = Color(0xFFFF6B9D);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

enum _Plan { monthly, yearly, lifetime }

class _PlanInfo {
  const _PlanInfo({
    required this.title,
    required this.price,
    this.discountPrice,
    required this.discountNote,
  });
  final String title;
  final String price;
  final String? discountPrice;
  final String discountNote;
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  _Plan _selected = _Plan.monthly;
  bool _restoring = false;

  static const _features = [
    '47가지 유니코드 폰트',
    'AI 번역 (9개 언어)',
    '계산기',
    '이모티콘 모음',
    '특수문자 모음',
    '즐겨찾기',
  ];

  static const _plans = {
    _Plan.monthly: _PlanInfo(
      title: '월간',
      price: '₩9,900/월',
      discountPrice: '₩5,900/월',
      discountNote: '런칭 할인 · 3개월',
    ),
    _Plan.yearly: _PlanInfo(
      title: '연간',
      price: '₩118,800/년',
      discountPrice: '₩59,000/년',
      discountNote: '런칭 할인 · 3개월 · 월 ₩4,916',
    ),
    _Plan.lifetime: _PlanInfo(
      title: '평생',
      price: '₩24,900',
      discountNote: '한 번만 결제',
    ),
  };

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.tierListenable.addListener(_onTier);
  }

  @override
  void dispose() {
    SubscriptionService.instance.tierListenable.removeListener(_onTier);
    super.dispose();
  }

  void _onTier() {
    if (mounted) setState(() {});
  }

  Future<void> _openPaywall() async {
    if (SubscriptionService.instance.isPremiumNow) return;
    await PaywallScreen.show(context);
    if (mounted) setState(() {});
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final ok = await SubscriptionService.instance.restorePurchase();
    if (!mounted) return;
    setState(() => _restoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '복원 완료' : '복원할 구독이 없습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = SubscriptionService.instance.isPremiumNow;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8);
    final fg = isDark ? Colors.white : Colors.black87;
    final muted = isDark ? Colors.white60 : Colors.grey.shade600;
    final plan = _plans[_selected]!;

    return Container(
      color: isDark ? Colors.black : Colors.white,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Text(
                      '✨ Fonkii Premium',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '모든 기능을 무제한으로',
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _features.map((f) => _FeatureRow(text: f, fg: fg)).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: _Plan.values.map((p) {
                  final isFirst = p == _Plan.values.first;
                  return [
                    if (!isFirst) const SizedBox(width: 8),
                    Expanded(
                      child: _PlanTab(
                        title: _plans[p]!.title,
                        selected: _selected == p,
                        isDark: isDark,
                        onTap: () => setState(() => _selected = p),
                      ),
                    ),
                  ];
                }).expand((e) => e).toList(),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    if (plan.discountPrice != null)
                      Text(
                        plan.price,
                        style: TextStyle(
                          fontSize: 14,
                          color: muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      plan.discountPrice ?? plan.price,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _pink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.discountNote,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isPremium ? null : _openPaywall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    disabledForegroundColor:
                        isDark ? Colors.white60 : Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isPremium ? '✓ 현재 이용 중' : '✨ 프리미엄 시작하기',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  '이미 구독 중이라면?',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _restoring ? null : _restore,
                  child: Text(
                    _restoring ? '복원 중...' : '구매 복원하기',
                    style: TextStyle(
                      fontSize: 14,
                      color: _pink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text, required this.fg});
  final String text;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: _pink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.title,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _pink.withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _pink
                : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected
                  ? _pink
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
