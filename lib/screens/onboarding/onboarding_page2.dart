import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_page3.dart';

/// Matches the channel registered in `ios/Runner/AppDelegate.swift`.
const _keyboardCheckChannel =
    MethodChannel('com.yunajung.fonki/keyboard_check');

/// Persisted the first time the user reaches page 2. Read by `main.dart`'s
/// launch router so a cold relaunch mid-flow (iOS routinely evicts the app
/// during the Settings excursion from this page) resumes at page 2 instead
/// of restarting at page 1.
const onboardingPage2VisitedKey = 'onboarding_page2_visited';

const _bgBlue = Color(0xFFC8E8FF);
const _borderBlue = Color(0xFFA8D4F0);
const _accent = Color(0xFF7FC7FF);

class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2>
    with WidgetsBindingObserver {
  /// True only between the "지금 설정하기" tap and the next foreground.
  /// Without this gate, the very first time the user tabs back from the app
  /// switcher or pulls down notifications, they'd be silently advanced to
  /// page 3 having seen nothing of this page.
  bool _awaitingReturnFromSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markPage2Visited();
    // Cold-launch resume path: if iOS evicted the app while the user was in
    // Settings, _LaunchRouter brings them back here. If they already enabled
    // the keyboard before the eviction, skip straight to page 3 instead of
    // making them tap the settings button again just to fire the lifecycle
    // observer.
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoAdvanceIfReady());
  }

  Future<void> _markPage2Visited() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingPage2VisitedKey, true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReturnFromSettings) {
      _awaitingReturnFromSettings = false;
      _checkKeyboardAndAdvance();
    }
  }

  Future<void> _openSettings() async {
    _awaitingReturnFromSettings = true;
    await AppSettings.openAppSettings();
  }

  /// Asks the iOS side whether Fonkii is in `UITextInputMode.activeInputModes`.
  /// On Android (and on any channel error) returns false — there's no
  /// reliable parallel API to derive enablement from, so failing closed is
  /// safer than auto-advancing.
  Future<bool> _isKeyboardEnabled() async {
    if (!Platform.isIOS) return false;
    try {
      return await _keyboardCheckChannel
              .invokeMethod<bool>('isKeyboardEnabled') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _autoAdvanceIfReady() async {
    final enabled = await _isKeyboardEnabled();
    if (!mounted || !enabled) return;
    _goToPage3();
  }

  Future<void> _checkKeyboardAndAdvance() async {
    final enabled = await _isKeyboardEnabled();
    if (!mounted) return;
    if (enabled) {
      _goToPage3();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              '아직 설정이 완료되지 않았어요 😢\n키보드를 추가하고 전체 접근을 허용해주세요',
            ),
            duration: Duration(seconds: 4),
          ),
        );
    }
  }

  void _goToPage3() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingPage3()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              'Fonkii 키보드 켜볼까요? 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '딱 30초면 설정 끝!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF444444)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: const [
                    Positioned.fill(child: Center(child: _IPhoneMockup())),
                    Positioned(top: 12, left: 12, child: _Sparkle(size: 22)),
                    Positioned(top: 60, right: 4, child: _Sparkle(size: 16)),
                    Positioned(bottom: 50, left: 0, child: _Sparkle(size: 18)),
                    Positioned(bottom: 10, right: 14, child: _Sparkle(size: 14)),
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
                  onPressed: _openSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '설정하러 가기',
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

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      '✦',
      style: TextStyle(color: _accent, fontSize: size),
    );
  }
}

class _IPhoneMockup extends StatelessWidget {
  const _IPhoneMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderBlue, width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 14),
          const Opacity(
            opacity: 0.4,
            child: Column(
              children: [
                _SettingsRow(icon: 'Aa', label: '서체'),
                _SettingsRow(icon: '🌐', label: '언어 및 지역'),
                _SettingsRow(icon: '🔑', label: '자동 완성 및 암호'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _StepBadge('1'),
              const SizedBox(width: 8),
              const Expanded(
                child: _StepCard(
                  child: _SettingsRow(icon: '⌨️', label: '키보드'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: _accent),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: _StepBadge('2'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StepCard(
                  child: Column(
                    children: [
                      _ToggleRow(label: 'Fonkii'),
                      _ToggleRow(label: '전체 접근 허용', leadingIcon: '⌨️'),
                      SizedBox(height: 4),
                      Text('👆', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(icon, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge(this.n);
  final String n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        n,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, this.leadingIcon});
  final String label;
  final String? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Text(leadingIcon!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          const _ToggleOn(),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_back, size: 14, color: _accent),
        ],
      ),
    );
  }
}

class _ToggleOn extends StatelessWidget {
  const _ToggleOn();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 18,
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
