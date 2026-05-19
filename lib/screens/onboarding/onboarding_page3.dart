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
                '이제 Fonkii 키보드를 사용해봐요! 🎹',
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
                height: 280,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _ChatInputMockup(),
        SizedBox(height: 6),
        _LongPressHint(),
        SizedBox(height: 10),
        _KeyboardPickerMockup(),
      ],
    );
  }
}

class _ChatInputMockup extends StatelessWidget {
  const _ChatInputMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🌐', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '메시지 입력...',
              style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.send, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LongPressHint extends StatelessWidget {
  const _LongPressHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: const [
          Icon(Icons.arrow_upward, color: _accent, size: 16),
          SizedBox(width: 4),
          Text(
            '꾹 누르기',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardPickerMockup extends StatelessWidget {
  const _KeyboardPickerMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: const [
            _PickerRow(label: 'Fonkii', selected: true),
            _PickerDivider(),
            _PickerRow(label: 'English (US)'),
            _PickerDivider(),
            _PickerRow(label: '한국어'),
            _PickerDivider(),
            _PickerRow(label: '이모지'),
          ],
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
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: selected ? _accent : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check, size: 14, color: Colors.white),
        ],
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
