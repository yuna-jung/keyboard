import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';

const _pink = Color(0xFF5BC8F5);
const _freeLimit = 4;

// ══════════════════════════════════════════════════════════════════════════════
// Data
// ══════════════════════════════════════════════════════════════════════════════

class _Category {
  const _Category(this.label, this.icon, this.emoticons);
  final String label;
  final IconData icon;
  final List<String> emoticons;
}

const _categories = [
  _Category('행복', Icons.sentiment_very_satisfied, [
    '(◕‿◕)',
    '(｡◕‿◕｡)',
    'ヽ(＾▽＾)ノ',
    '(★‿★)',
    '٩(◕‿◕)۶',
    '(◠‿◠)',
    '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
    '(≧▽≦)',
    '(✧ω✧)',
    '(◕ᴗ◕✿)',
    '☆*:.｡.o(≧▽≦)o.｡.:*☆',
    '(✿◠‿◠)',
    '(｡♥‿♥｡)',
    '(ᗒᗨᗕ)',
  ]),
  _Category('슬픔', Icons.sentiment_very_dissatisfied, [
    '(；﹏；)',
    '(╥_╥)',
    '(T_T)',
    '(つ﹏⊂)',
    '(ಥ_ಥ)',
    '(｡•́︿•̀｡)',
    '(っ˘̩╭╮˘̩)っ',
    '(｡ŏ﹏ŏ)',
    '(ノ_<、)',
    '(´;ω;｀)',
    '(⌯˃̶᷄ ﹏ ˂̶᷄⌯)',
    '｡ﾟ(ﾟ´Д｀ﾟ)ﾟ｡',
    '(ᗒᗩᗕ)',
    '(⁄ ⁄•⁄ω⁄•⁄ ⁄)',
  ]),
  _Category('노여움', Icons.mood_bad, [
    '(╬ Ò﹏Ó)',
    '(ﾉಥ益ಥ)ﾉ',
    '(‡▼益▼)',
    '(ﾉ`Д´)ﾉ',
    '(¬_¬")',
    '(눈_눈)',
    '(ꐦ°᷄д°᷅)',
    '(╯°□°)╯︵ ┻━┻',
    '(ᗒᗣᗕ)՞',
    '(▀̿Ĺ̯▀̿ ̿)',
    '(ง •̀_•́)ง',
    '(¬‿¬)',
    'ಠ_ಠ',
    '(ꈨ ꒪⌓꒪)',
  ]),
  _Category('동물', Icons.pets, [
    '(=^･ω･^=)',
    '(◕ᴥ◕)',
    'ʕ•ᴥ•ʔ',
    '(๑˃̵ᴗ˂̵)و',
    '🐾(=✪ᆺ✪=)',
    'ʕ·ᴥ·ʔ',
    '(U・ω・U)',
    '(=①ω①=)',
    '(ΦωΦ)',
    'ᘛ⁐̤ᕐᐷ',
    '(・⊝・)',
    '🐧(・Θ・)',
    '≧◉ᴥ◉≦',
    '(•ˋ _ ˊ•)',
  ]),
  _Category('사랑', Icons.favorite, [
    '(♥ω♥)',
    '(づ￣ ³￣)づ',
    '♡(˘▽˘>ԅ( ˘⌣˘)',
    '(´,,•ω•,,)♡',
    '(⺣◡⺣)♡*',
    '(灬♥ω♥灬)',
    '(*˘︶˘*).｡*♡',
    '(◍•ᴗ•◍)❤',
    '(♡°▽°♡)',
    '(✿ ♥‿♥)',
    '( ˘ ³˘)♥',
    '(❤ω❤)',
    '♡＾▽＾♡',
    '(ɔˆ ³(ˆ⌣ˆc)',
  ]),
  _Category('반응', Icons.thumb_up, [
    '( •̀ᴗ•́ )و',
    '(☞ﾟヮﾟ)☞',
    '¯\\_(ツ)_/¯',
    '(⊙_⊙)',
    '(¬‿¬ )',
    '( ͡° ͜ʖ ͡°)',
    '(•_•) ( •_•)>⌐■-■ (⌐■_■)',
    '(☉_☉)',
    '(◎_◎;)',
    'ᕕ( ᐛ )ᕗ',
    '(ʘ言ʘ╬)',
    '(⌐■_■)',
    '(~˘▾˘)~',
    '┬┴┬┴┤(･_├┬┴┬┴',
  ]),
  _Category('동작', Icons.directions_run, [
    '┗(＾0＾)┓',
    'ヾ(⌐■_■)ノ♪',
    '♪(´ε` )',
    '〜(꒪꒳꒪)〜',
    'ƪ(˘⌣˘)ʃ',
    '┌(★o☆)┘',
    '⊂(◉‿◉)つ',
    '(ノ´ヮ`)ノ*: ・゚✧',
    '₍₍ ◝(●˙꒳˙●)◜ ₎₎',
    '⁽⁽ ◝(　゜∀ 　゜ )◟ ⁾⁾',
    '(ﾉ≧∀≦)ﾉ',
    '~(˘▽˘~)',
    '⊂((・▽・))⊃',
    'ε=ε=ε=┌(;*´Д`)ﾉ',
  ]),
];

// ══════════════════════════════════════════════════════════════════════════════
// Screen
// ══════════════════════════════════════════════════════════════════════════════

class EmoticonScreen extends StatefulWidget {
  const EmoticonScreen({super.key});

  @override
  State<EmoticonScreen> createState() => _EmoticonScreenState();
}

class _EmoticonScreenState extends State<EmoticonScreen> {
  int _selectedIndex = 0;
  final _sub = SubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    _sub.premiumStatus.addListener(_onPremiumChanged);
  }

  void _onPremiumChanged() => setState(() {});

  @override
  void dispose() {
    _sub.premiumStatus.removeListener(_onPremiumChanged);
    super.dispose();
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

  void _showPaywall() {
    PaywallScreen.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final category = _categories[_selectedIndex];
    final emoticons = category.emoticons;

    return Column(
      children: [
        // ── 카테고리 탭 ──────────────────────────────────────────
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

        // ── 이모티콘 그리드 ──────────────────────────────────────
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: emoticons.length,
            itemBuilder: (context, index) {
              final emoticon = emoticons[index];
              final locked = !_sub.isPremiumNow && index >= _freeLimit;

              return _EmoticonTile(
                emoticon: emoticon,
                locked: locked,
                onTap: locked ? _showPaywall : () => _copy(emoticon),
              )
                  .animate()
                  .fadeIn(duration: 250.ms, delay: (30 * index).ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 250.ms,
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
// Emoticon Tile
// ══════════════════════════════════════════════════════════════════════════════

class _EmoticonTile extends StatelessWidget {
  const _EmoticonTile({
    required this.emoticon,
    required this.locked,
    required this.onTap,
  });

  final String emoticon;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: locked ? Colors.grey.shade100 : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    emoticon,
                    style: TextStyle(
                      fontSize: 14,
                      color: locked ? Colors.grey.shade400 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (locked)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('🔒', style: TextStyle(fontSize: 10)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

