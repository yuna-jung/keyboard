import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'onboarding_page2.dart';

/// Persisted flag read by `main.dart` on cold launch. Written only by the
/// final onboarding page, so an iOS process eviction mid-flow (e.g. while
/// the user is in the Settings app from page 2) restarts onboarding from
/// the beginning rather than skipping the user past unseen pages.
const onboardingCompletedKey = 'onboarding_completed_v1';

const _accent = Color(0xFF7FC7FF);

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  void _onStart(BuildContext context) {
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
                    Text(
                      AppLocalizations.of(context)!.onboardingWelcomeTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.onboardingWelcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, color: Colors.black),
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
                  child: Text(
                    AppLocalizations.of(context)!.onboardingStart,
                    style: const TextStyle(
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
              child: _TermsText(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TermsText extends StatefulWidget {
  const _TermsText();

  @override
  State<_TermsText> createState() => _TermsTextState();
}

class _TermsTextState extends State<_TermsText> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = () {
      if (!mounted) return;
      _open(AppLocalizations.of(context)!.onboardingTermsUrl);
    };
    _privacyTap = TapGestureRecognizer()..onTap = () {
      if (!mounted) return;
      _open(AppLocalizations.of(context)!.onboardingPrivacyUrl);
    };
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    const grayStyle = TextStyle(fontSize: 13, color: Colors.grey);
    const linkStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey,
      fontWeight: FontWeight.bold,
    );

    final l = AppLocalizations.of(context)!;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l.onboardingTermsPre, style: grayStyle),
          TextSpan(text: l.onboardingTermsLink, style: linkStyle, recognizer: _termsTap),
          TextSpan(text: l.onboardingTermsMid, style: grayStyle),
          TextSpan(text: l.onboardingPrivacyLink, style: linkStyle, recognizer: _privacyTap),
          TextSpan(text: l.onboardingTermsPost, style: grayStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
