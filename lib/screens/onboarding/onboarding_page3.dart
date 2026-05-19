import 'package:flutter/material.dart';

import 'onboarding_page4.dart';

const _accent = Color(0xFF7FC7FF);
const _illustrationBg = Color(0xFFF0F8FF);

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  void _goToNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingPage4()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '이제 Fonkii 키보드를 사용해봐요! ⌨️',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '지구본 버튼을 꾹 누르면 Fonkii를 선택할 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF444444)),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 340,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _illustrationBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const _Illustration(),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => _goToNext(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popup is left-aligned so it visually sits above the globe key in
        // the keyboard mockup below — mimicking iOS's actual long-press
        // popover anchor.
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 220, child: _PickerPopup()),
        ),
        const SizedBox(height: 10),
        const Expanded(child: _KeyboardMockup()),
      ],
    );
  }
}

class _PickerPopup extends StatelessWidget {
  const _PickerPopup();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: const [
            _PickerRow(label: '한국어'),
            _PickerDivider(),
            _PickerRow(label: '이모지'),
            _PickerDivider(),
            _PickerRow(label: 'English (US)'),
            _PickerDivider(),
            _PickerRow(label: 'font_keyboard — Fonkii', selected: true),
          ],
        ),
      ),
    );
  }
}

class _KeyboardMockup extends StatelessWidget {
  const _KeyboardMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _KeyRow(count: 10),
        SizedBox(height: 4),
        _KeyRow(count: 9),
        SizedBox(height: 4),
        _KeyRow(count: 8),
        SizedBox(height: 4),
        _KeyboardBottomRow(),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            '꾹 누르기 →',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFDADCDE),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _KeyboardBottomRow extends StatelessWidget {
  const _KeyboardBottomRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Globe key — blue circle to highlight the long-press target.
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🌐', style: TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 4),
        _SpecialKey(label: '한/영', width: 40),
        const SizedBox(width: 4),
        const Expanded(child: _SpecialKey(label: 'space')),
        const SizedBox(width: 4),
        _SpecialKey(label: 'return', width: 56, accent: true),
      ],
    );
  }
}

class _SpecialKey extends StatelessWidget {
  const _SpecialKey({required this.label, this.width, this.accent = false});
  final String label;
  final double? width;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 28,
      decoration: BoxDecoration(
        color: accent ? _accent : const Color(0xFFDADCDE),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: accent ? Colors.white : const Color(0xFF555555),
          fontWeight: accent ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: selected ? const Color(0xFFE5E5E5) : Colors.transparent,
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PickerDivider extends StatelessWidget {
  const _PickerDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFFEEEEEE),
    );
  }
}
