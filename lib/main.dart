import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/add_phrase_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_page1.dart';
import 'screens/onboarding/onboarding_page2.dart';
import 'services/subscription_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

const _pink = Color(0xFF5BC8F5);

/// Adapty SDK key — iOS-only. Android intentionally skips Adapty.activate(),
/// so the SDK stays dormant on that platform; the subscription tab and
/// paywall plumbing are also gated to iOS in `home_screen.dart`.
const _adaptyPublicKey = 'public_live_3DOX3Si9.vj8Cmt2zJnmbSqUZYtfk';

/// Dev-only switch: when true, clears [onboardingCompletedKey] on every
/// launch so the onboarding flow is guaranteed to appear. Flip back to
/// `false` before shipping — otherwise returning users will see onboarding
/// on every cold start.
const _forceShowOnboarding = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  if (_forceShowOnboarding) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(onboardingPage2VisitedKey);
    await prefs.remove(onboardingCompletedKey);
  }
  if (Platform.isIOS && _adaptyPublicKey != 'YOUR_ADAPTY_PUBLIC_KEY') {
    await SubscriptionService.instance.initialize(_adaptyPublicKey);
  }
  runApp(const FontKeyboardApp());
}

class FontKeyboardApp extends StatelessWidget {
  const FontKeyboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fonkii',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _pink,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: _pink,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _pink,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigatorKey: _navigatorKey,
      home: const _LaunchRouter(),
    );
  }
}

/// Three-way launch decision read once at cold launch:
///   * [onboardingCompletedKey] set → home screen
///   * [onboardingPage2VisitedKey] set → resume at page 2 (covers the
///     iOS-eviction-during-Settings case: page 1's content was already
///     seen, the user just needs to finish the keyboard hookup)
///   * neither set → page 1
/// Runs exactly once — no lifecycle observer, no rebuilds on resume —
/// so a Settings excursion can't bounce the user back to page 1. The
/// brief blank frame while the future resolves is intentional — gating
/// navigation on `SharedPreferences.getInstance()` avoids flashing the
/// wrong screen to a returning user.
class _LaunchRouter extends StatefulWidget {
  const _LaunchRouter();

  @override
  State<_LaunchRouter> createState() => _LaunchRouterState();
}

enum _LaunchTarget { page1, page2, home }

class _LaunchRouterState extends State<_LaunchRouter> {
  late final Future<_LaunchTarget> _target = _resolveTarget();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Cold start: app was closed and opened via deep link
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handleLink(initial);
    } catch (_) {}

    // Warm start: app already running, new link arrives
    _linkSub = appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'fonkii' && uri.host == 'addphrase') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const AddPhraseScreen()),
        );
      });
    }
  }

  Future<_LaunchTarget> _resolveTarget() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(onboardingCompletedKey) ?? false) {
      return _LaunchTarget.home;
    }
    if (prefs.getBool(onboardingPage2VisitedKey) ?? false) {
      return _LaunchTarget.page2;
    }
    return _LaunchTarget.page1;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LaunchTarget>(
      future: _target,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(backgroundColor: Colors.white);
        }
        switch (snapshot.data!) {
          case _LaunchTarget.home:
            return const HomeScreen();
          case _LaunchTarget.page2:
            return const OnboardingPage2();
          case _LaunchTarget.page1:
            return const OnboardingPage1();
        }
      },
    );
  }
}
