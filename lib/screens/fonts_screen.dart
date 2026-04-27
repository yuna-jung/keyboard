import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/font_style_model.dart';
import '../services/unicode_converter.dart';
import '../services/favorites_service.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';

const _pink = Color(0xFF5BC8F5);

class FontsScreen extends StatefulWidget {
  const FontsScreen({super.key});

  @override
  State<FontsScreen> createState() => FontsScreenState();
}

class FontsScreenState extends State<FontsScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _converter = UnicodeConverter.instance;
  final _favoritesService = FavoritesService();
  final _sub = SubscriptionService.instance;
  Set<String> _favoriteSet = {};
  VoidCallback? onFavoritesChanged;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _focusNode.addListener(() => setState(() {}));
    _sub.premiumStatus.addListener(_onPremiumChanged);
  }

  void _onPremiumChanged() => setState(() {});

  Future<void> _loadFavorites() async {
    final items = await _favoritesService.getFavorites();
    setState(() => _favoriteSet = items.map((e) => e.text).toSet());
  }

  Future<void> reloadFavorites() => _loadFavorites();

  @override
  void dispose() {
    _sub.premiumStatus.removeListener(_onPremiumChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('복사되었습니다 ✨'),
          backgroundColor: _pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Future<void> _toggleFavorite(String converted, String styleName) async {
    if (_favoriteSet.contains(converted)) {
      await _favoritesService.removeFavorite(converted);
      _favoriteSet.remove(converted);
    } else {
      await _favoritesService.addFavorite(converted, styleName);
      _favoriteSet.add(converted);
    }
    setState(() {});
    onFavoritesChanged?.call();
  }

  void _showPaywall() {
    PaywallScreen.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final input = _controller.text;
    final styles = _converter.styles;

    return Column(
      children: [
        // ── 입력창 ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '텍스트를 입력하세요...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixIcon: input.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _pink, width: 2),
              ),
            ),
          ),
        ),

        // ── 변환 목록 ────────────────────────────────────────────
        Expanded(
          child: input.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_alt_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        '변환할 텍스트를 입력해보세요',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: styles.length,
                  itemBuilder: (context, index) {
                    final style = styles[index];
                    final converted = style.convert(input);
                    final isFav = _favoriteSet.contains(converted);

                    return _StyleCard(
                      style: style,
                      converted: converted,
                      isFavorite: isFav,
                      onCopy: () => _copyToClipboard(converted),
                      onToggleFavorite: () => _toggleFavorite(converted, style.name),
                      onLockedTap: _showPaywall,
                    )
                        .animate()
                        .fadeIn(
                          duration: 300.ms,
                          delay: (30 * index).ms,
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 300.ms,
                          delay: (30 * index).ms,
                          curve: Curves.easeOut,
                        );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Style Card
// ══════════════════════════════════════════════════════════════════════════════

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.converted,
    required this.isFavorite,
    required this.onCopy,
    required this.onToggleFavorite,
    required this.onLockedTap,
  });

  final FontStyleModel style;
  final String converted;
  final bool isFavorite;
  final VoidCallback onCopy;
  final VoidCallback onToggleFavorite;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final locked = style.isPremium && !SubscriptionService.instance.isPremiumNow;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: locked ? onLockedTap : onCopy,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── 텍스트 영역 ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          style.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 4),
                          const Text('🔒', style: TextStyle(fontSize: 11)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locked ? _mask(converted) : converted,
                      style: const TextStyle(fontSize: 18, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── 액션 버튼 ─────────────────────────────────────
              if (!locked) ...[
                _ActionButton(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? _pink : Colors.grey.shade400,
                  onTap: onToggleFavorite,
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.copy_rounded,
                  color: Colors.grey.shade400,
                  onTap: onCopy,
                ),
              ] else
                Icon(Icons.chevron_right, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  /// 프리미엄 잠금 시 앞 3글자만 보여주고 나머지 블러 처리 느낌
  String _mask(String text) {
    if (text.length <= 3) return text;
    return '${text.substring(0, 3)}••••';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Small action button
// ══════════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

