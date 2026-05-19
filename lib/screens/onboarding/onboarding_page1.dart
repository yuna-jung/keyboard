import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_page2.dart';

/// Persisted flag read by `main.dart` on app launch to decide whether to
/// show onboarding. When more onboarding pages are added, move the
/// flag-set call out of [OnboardingPage1] and into the final page so users
/// see the full flow before it's marked done.
const onboardingCompletedKey = 'onboarding_completed_v1';

const _accent = Color(0xFF7FC7FF);

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  Future<void> _onStart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingPage2()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Fonkii',
                      style: GoogleFonts.nerkoOne(
                        fontSize: 64,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/images/cloud.png',
                      width: 280,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '환영해요!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '당신만의 특별한 키보드를 만나보세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => _onStart(context),
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
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '당사의 이용 약관을 수락하고 개인정보 보호정책에 대해\n고지받으신 것으로 간주됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
