import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/favorite_item.dart';
import '../services/favorites_service.dart';

const _pink = Color(0xFF5BC8F5);

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  final _service = FavoritesService();
  List<FavoriteItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final items = await _service.getFavorites();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('복사되었습니다 ✨'),
          backgroundColor: _pink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Future<void> _delete(FavoriteItem item) async {
    await _service.removeFavorite(item.text);
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _pink));
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '아직 즐겨찾기가 없어요',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fonts 탭에서 하트를 눌러 추가해보세요',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

        return Dismissible(
          key: ValueKey(item.text),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _delete(item),
          child: _FavoriteCard(
            item: item,
            onCopy: () => _copy(item.text),
            onDelete: () => _delete(item),
          )
              .animate()
              .fadeIn(duration: 250.ms, delay: (30 * index).ms)
              .slideX(
                begin: 0.05,
                end: 0,
                duration: 250.ms,
                delay: (30 * index).ms,
                curve: Curves.easeOut,
              ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Favorite Card
// ══════════════════════════════════════════════════════════════════════════════

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.onCopy,
    required this.onDelete,
  });

  final FavoriteItem item;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onCopy,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── 텍스트 ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.styleName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.text,
                      style: const TextStyle(fontSize: 18, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── 복사 버튼 ──────────────────────────────────────
              _CircleButton(
                icon: Icons.copy_rounded,
                onTap: onCopy,
              ),
              const SizedBox(width: 4),

              // ── 삭제 버튼 ──────────────────────────────────────
              _CircleButton(
                icon: Icons.delete_outline,
                color: Colors.red.shade300,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Circle Button
// ══════════════════════════════════════════════════════════════════════════════

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color ?? Colors.grey.shade400),
      ),
    );
  }
}
