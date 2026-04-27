import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _pink = Color(0xFF5BC8F5);

// ══════════════════════════════════════════════════════════════════════════════
// Data — 두 종류: 그리드 아이템(개별 문자) / 와이드 아이템(장식선·ASCII아트)
// ══════════════════════════════════════════════════════════════════════════════

enum _LayoutType { grid, wide }

class _Category {
  const _Category(this.label, this.icon, this.items, [this.layout = _LayoutType.grid]);
  final String label;
  final IconData icon;
  final List<String> items;
  final _LayoutType layout;
}

const _categories = [
  _Category('화살표', Icons.arrow_forward, [
    '→', '←', '↑', '↓', '➜', '➡', '⇒', '⇐', '⇑', '⇓',
    '⟶', '⟵', '↩', '↪', '↗', '↘', '↙', '↖', '⤴', '⤵',
    '➤', '➔', '➞', '⇢', '⇠', '⟹', '⟸', '↔', '⇔', '⟷',
  ]),
  _Category('도형', Icons.category, [
    '■', '□', '▪', '▫', '▲', '△', '▼', '▽', '◆', '◇',
    '●', '○', '◉', '◎', '★', '☆', '▶', '◀', '▷', '◁',
    '⬟', '⬡', '⬢', '⏣', '⬤', '⬠', '⬣', '◈', '▣', '▧',
  ]),
  _Category('별/꽃', Icons.local_florist, [
    '✿', '❀', '✾', '❁', '✦', '✧', '❋', '✺', '✵', '✶',
    '✷', '✸', '✹', '❂', '❃', '✻', '✼', '❄', '❅', '❆',
    '✡', '✢', '✣', '✤', '✥', '⁂', '※', '⁑', '꙳', '✱',
  ]),
  _Category('하트', Icons.favorite, [
    '♡', '♥', '❤', '❣', '❥', '❦', '❧', '💕', '💗', '💓',
    '💖', '💘', '💝', '💞', '🤍', '🖤', '🤎', '💛', '💚', '💙',
    '💜', '🩷', '🩵', '🩶', '❤️‍🔥', '♡̷', '❥', '❣', '♥', '❤',
  ]),
  _Category('음악', Icons.music_note, [
    '♩', '♪', '♫', '♬', '♭', '♮', '♯', '🎵', '🎶', '🎼',
    '𝄞', '𝄡', '𝄢', '𝅗𝅥', '𝅘𝅥', '𝅘𝅥𝅮', '🎹', '🎸', '🎺', '🎻',
    '🥁', '🎷', '🪗', '🎤', '🔔', '🔕', '📯', '🪘', '🎙', '🔊',
  ]),
  _Category('수학', Icons.calculate, [
    '±', '×', '÷', '≠', '≈', '≤', '≥', '∞', '√', '∑',
    '∏', '∫', '∂', '∆', '∇', '∈', '∉', '∋', '∅', '∧',
    '∨', '⊂', '⊃', '⊆', '⊇', '∩', '∪', '⊕', '⊗', '⊥',
  ]),
  _Category('장식선', Icons.horizontal_rule, [
    '══════════════',
    '──────────────',
    '┄┄┄┄┄┄┄┄┄┄┄┄┄┄',
    '╌╌╌╌╌╌╌╌╌╌╌╌╌╌',
    '─ ─ ─ ─ ─ ─ ─',
    '━━━━━━━━━━━━━━',
    '┅┅┅┅┅┅┅┅┅┅┅┅┅┅',
    '╍╍╍╍╍╍╍╍╍╍╍╍╍╍',
    '·͜·♡·͜·♡·͜·♡·͜·♡·͜·',
    '꒰ ꒱꒰ ꒱꒰ ꒱꒰ ꒱꒰ ꒱',
    '✦•┈┈•✦•┈┈•✦',
    '•─────────────•',
    '⋆⋅☆⋅⋆⋅☆⋅⋆⋅☆⋅⋆',
    '♡━━━━━━━━━━♡',
    '•°.✿.°•.✿.°•.✿.°•',
    '▸ ▹ ▸ ▹ ▸ ▹ ▸ ▹',
    '◈ ◇ ◈ ◇ ◈ ◇ ◈ ◇',
    '★·.·´¯`·.·★·.·´¯`·.·★',
    '═══════╗♡╔═══════',
    '┊ ┊ ┊ ┊ ┊ ┊ ┊ ┊',
  ], _LayoutType.wide),
  _Category('ASCII아트', Icons.draw, [
    'ฅ^•ﻌ•^ฅ',
    '(づ◡﹏◡)づ',
    '( ˘▽˘)っ♨',
    '(っ˘ω˘ς)',
    '₍ᐢ..ᐢ₎',
    '( ˶ˆᗜˆ˵ )',
    '(⸝⸝⸝°_°⸝⸝⸝)',
    '(ᵔᴥᵔ)',
    '꒰ᐢ⸝⸝•༝•⸝⸝ᐢ꒱',
    '(≧ᗜ≦)',
    '♪(´▽`)',
    '(˶ᵔ ᵕ ᵔ˶)',
    '(⊃｡•́‿•̀｡)⊃',
    '(ᴗ_ ᴗ。)',
    '(◕ᴗ◕✿)',
    '(⁎⁍̴̛ᴗ⁍̴̛⁎)',
    '(*ᴗ͈ˬᴗ͈)ꕤ',
    '(ノ◕ヮ◕)ノ*:・゚✧',
    '(⸝⸝ᵕᴗᵕ⸝⸝)',
    '(つ✧ω✧)つ',
  ], _LayoutType.wide),
];

// ══════════════════════════════════════════════════════════════════════════════
// Screen
// ══════════════════════════════════════════════════════════════════════════════

class SpecialCharsScreen extends StatefulWidget {
  const SpecialCharsScreen({super.key});

  @override
  State<SpecialCharsScreen> createState() => _SpecialCharsScreenState();
}

class _SpecialCharsScreenState extends State<SpecialCharsScreen> {
  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final category = _categories[_selectedIndex];

    return Column(
      children: [
        // ── 카테고리 칩 ──────────────────────────────────────────
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = index == _selectedIndex;
              return _CategoryChip(
                label: cat.label,
                icon: cat.icon,
                selected: selected,
                onTap: () => setState(() => _selectedIndex = index),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // ── 아이템 영역 ──────────────────────────────────────────
        Expanded(
          child: category.layout == _LayoutType.grid
              ? _buildGrid(category)
              : _buildWideList(category),
        ),
      ],
    );
  }

  // ── 5열 그리드 (화살표·도형·별/꽃·하트·음악·수학) ─────────────
  Widget _buildGrid(_Category category) {
    final items = category.items;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _CharTile(char: items[index], onTap: () => _copy(items[index]))
            .animate()
            .fadeIn(duration: 200.ms, delay: (20 * index).ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 200.ms,
              delay: (20 * index).ms,
              curve: Curves.easeOut,
            );
      },
    );
  }

  // ── 와이드 리스트 (장식선·ASCII아트) ──────────────────────────
  Widget _buildWideList(_Category category) {
    final items = category.items;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _WideTile(text: items[index], onTap: () => _copy(items[index]))
            .animate()
            .fadeIn(duration: 250.ms, delay: (30 * index).ms)
            .slideX(
              begin: 0.05,
              end: 0,
              duration: 250.ms,
              delay: (30 * index).ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Category Chip
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _pink : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Character Tile (5-column grid)
// ══════════════════════════════════════════════════════════════════════════════

class _CharTile extends StatelessWidget {
  const _CharTile({required this.char, required this.onTap});

  final String char;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(char, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Wide Tile (장식선 / ASCII아트)
// ══════════════════════════════════════════════════════════════════════════════

class _WideTile extends StatelessWidget {
  const _WideTile({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16, letterSpacing: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.copy_rounded, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
