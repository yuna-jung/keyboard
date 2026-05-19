import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_screen.dart';
import 'onboarding_page1.dart' show onboardingCompletedKey;

const _accent = Color(0xFF7FC7FF);
const _accentSoft = Color(0x337FC7FF);
const _accentInkDark = Color(0xFF3A8FCC);
const _innerBg = Color(0xFFF0F8FF);

class OnboardingPage4 extends StatefulWidget {
  const OnboardingPage4({super.key});

  @override
  State<OnboardingPage4> createState() => _OnboardingPage4State();
}

class _OnboardingPage4State extends State<OnboardingPage4> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _pages = <Widget>[
    _FontSlide(),
    _TranslationSlide(),
    _ReplacementSlide(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _onNext() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F4FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: _pages,
                ),
              ),
              _PageIndicator(count: _pages.length, current: _index),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: isLast
                      ? ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            '시작하기',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: _onNext,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: const BorderSide(color: _accent, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            '다음',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? _accent : const Color(0xFFD7D7D7),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _SlideShell extends StatelessWidget {
  const _SlideShell({
    required this.icon,
    required this.title,
    required this.description,
    required this.preview,
  });

  final String icon;
  final String title;
  final String description;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 28),
          preview,
        ],
      ),
    );
  }
}

/// Shared "preview card" shell — white background with a soft drop shadow.
/// Each slide drops its example content inside this so the visual treatment
/// is identical across slides (the spec asked for the *entire* card style to
/// be unified).
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Slide 1 — Fonts ─────────────────────────────────────────────────────
class _FontSlide extends StatelessWidget {
  const _FontSlide();

  @override
  Widget build(BuildContext context) {
    return const _SlideShell(
      icon: 'Aa',
      title: '46가지의 폰트 변환',
      description: '채팅을 더 특별하게! 나만의 개성 폰트',
      preview: _PreviewCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChatBubble(
              side: _BubbleSide.left,
              text: 'Hey! Did you see my post? 😊',
            ),
            SizedBox(height: 8),
            _ChatBubble(
              side: _BubbleSide.right,
              text:
                  'ᴏᴍɢ ɪᴛ ʟᴏᴏᴋs ꜱᴏ ɢᴏᴏᴅ!!\nɪ ʟᴏᴠᴇ ʏᴏᴜʀ ꜱᴛʏʟᴇ 🔥',
            ),
            SizedBox(height: 8),
            _ChatBubble(
              side: _BubbleSide.left,
              text: 'wait how did you do that??',
            ),
            SizedBox(height: 8),
            _ChatBubble(
              side: _BubbleSide.right,
              text: '𝒿𝓊𝓈𝓉 𝓊𝓈𝒾𝓃𝑔 𝐹𝑜𝓃𝓀𝒾𝒾 😏✨',
            ),
          ],
        ),
      ),
    );
  }
}

enum _BubbleSide { left, right }

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.side});
  final String text;
  final _BubbleSide side;

  @override
  Widget build(BuildContext context) {
    final isRight = side == _BubbleSide.right;
    final bg = isRight ? _accent : const Color(0xFFEFEFEF);
    final fg = isRight ? Colors.white : Colors.black87;
    final radius = isRight
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          );

    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 230),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: Text(
            text,
            style: TextStyle(color: fg, fontSize: 14, height: 1.35),
          ),
        ),
      ),
    );
  }
}

// ─── Slide 2 — Translation ───────────────────────────────────────────────
class _TranslationSlide extends StatelessWidget {
  const _TranslationSlide();

  @override
  Widget build(BuildContext context) {
    return const _SlideShell(
      icon: '🌐',
      title: '실시간 번역',
      description: '9개 언어로 바로 번역!\n외국 친구와도 자유롭게 소통해요',
      preview: _PreviewCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LangPill('한국어'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 14, color: _accent),
                SizedBox(width: 6),
                _LangPill('English'),
              ],
            ),
            SizedBox(height: 12),
            _TranslateBox(
              text: '오늘 저녁에 시간 있어?',
              background: _innerBg,
              textColor: Colors.black,
            ),
            SizedBox(height: 8),
            Center(
              child: Icon(Icons.arrow_downward, color: _accent, size: 20),
            ),
            SizedBox(height: 8),
            _TranslateBox(
              text: 'Are you free tonight?',
              background: _accentSoft,
              textColor: _accentInkDark,
              bold: true,
            ),
            SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag('🇺🇸 영어'),
                _Tag('🇯🇵 일본어'),
                _Tag('🇨🇳 중국어'),
                _Tag('+6'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _innerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _accentInkDark,
        ),
      ),
    );
  }
}

class _TranslateBox extends StatelessWidget {
  const _TranslateBox({
    required this.text,
    required this.background,
    required this.textColor,
    this.bold = false,
  });
  final String text;
  final Color background;
  final Color textColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: textColor,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _innerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
      ),
    );
  }
}

// ─── Slide 3 — Instagram showcase ────────────────────────────────────────
class _ReplacementSlide extends StatelessWidget {
  const _ReplacementSlide();

  @override
  Widget build(BuildContext context) {
    return const _SlideShell(
      icon: '📱',
      title: '인스타에서도 써봐요! 📸',
      description: 'Fonkii 폰트로 인스타 스토리, 게시물을 더 특별하게!',
      preview: _InstagramProfileCard(),
    );
  }
}

class _InstagramProfileCard extends StatelessWidget {
  const _InstagramProfileCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _PreviewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'ꜰᴏɴᴋɪɪ_ᴋᴇʏʙᴏᴀʀᴅ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/app_icon.jpg',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _IGStat(count: '1,234', label: 'Posts'),
                        _IGStat(count: '2M', label: 'Followers'),
                        _IGStat(count: '9,101', label: 'Following'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'fonkii_keyboard',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '키보드 앱',
                style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
              ),
              const SizedBox(height: 6),
              const Text(
                '⌨️ 𝒀𝒐𝒖𝒓 𝒌𝒆𝒚𝒃𝒐𝒂𝒓𝒅, 𝒚𝒐𝒖𝒓 𝒔𝒕𝒚𝒍𝒆 ✨',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '𝟰𝟲 𝗳𝗼𝗻𝘁𝘀 • 𝗿𝗲𝗮𝗹-𝘁𝗶𝗺𝗲 𝘁𝗿𝗮𝗻𝘀𝗹𝗮𝘁𝗶𝗼𝗻 🌐',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'ᴍᴀᴋᴇ ᴇᴠᴇʀʏ ᴍᴇssᴀɢᴇ ᴜɴꜰᴏʀɢᴇᴛᴛᴀʙʟᴇ 💬',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        // Floating emoji at top-right. `Clip.none` on the Stack lets it
        // extend slightly past the card corner without being cut by the
        // surrounding SingleChildScrollView's edges.
        const Positioned(
          top: -12,
          right: -8,
          child: Text('😍', style: TextStyle(fontSize: 36)),
        ),
      ],
    );
  }
}

class _IGStat extends StatelessWidget {
  const _IGStat({required this.count, required this.label});
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
        ),
      ],
    );
  }
}
