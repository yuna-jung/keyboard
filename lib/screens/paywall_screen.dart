import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/subscription_service.dart';

const _pink = Color(0xFFFF6B9D);

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PaywallScreen(),
    );
    return result ?? false;
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _sub = SubscriptionService.instance;
  bool _loading = false;
  String? _error;

  Future<void> _purchase() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final success = await _sub.purchaseWeekly();
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
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
          // ── Handle bar ──────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Icon ────────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
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
          const SizedBox(height: 20),

          // ── Title ───────────────────────────────────────────────
          const Text(
            'Premium 잠금 해제',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '모든 기능을 제한 없이 사용하세요',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // ── Feature list ────────────────────────────────────────
          const _FeatureRow(icon: Icons.text_fields, text: '16가지 프리미엄 폰트 스타일'),
          const SizedBox(height: 10),
          const _FeatureRow(icon: Icons.emoji_emotions, text: '카테고리별 모든 이모티콘'),
          const SizedBox(height: 10),
          const _FeatureRow(icon: Icons.keyboard, text: 'iOS 커스텀 키보드 전체 기능'),
          const SizedBox(height: 10),
          const _FeatureRow(icon: Icons.update, text: '새로운 스타일 업데이트 무료 제공'),
          const SizedBox(height: 28),

          // ── CTA button ──────────────────────────────────────────
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
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      '1주 무료 후 ₩5,000/주',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Free trial note ─────────────────────────────────────
          Text(
            '1주 무료체험 후 자동 결제 · 언제든 해지 가능',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),

          // ── Error ───────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
          ],

          const SizedBox(height: 12),

          // ── Restore + Later ─────────────────────────────────────
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _pink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _pink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        Icon(Icons.check_circle, size: 20, color: _pink),
      ],
    );
  }
}
