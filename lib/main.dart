import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
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

enum _LaunchTarget { page1, page2, home, myList }

class _LaunchRouterState extends State<_LaunchRouter>
    with WidgetsBindingObserver {
  late final Future<_LaunchTarget> _target = _resolveTarget();
  StreamSubscription<Uri>? _linkSub;
  // Guard: prevent duplicate push when FutureBuilder rebuilds.
  bool _myListPushed = false;

  static const _channel = MethodChannel('com.yunajung.fonki/appgroup');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler(_onChannelCall);
    _initDeepLinks();
  }

  Future<dynamic> _onChannelCall(MethodCall call) async {
    if (call.method == 'openAddPhrase') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AddPhraseScreen()),
          (route) => route.isFirst,
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkOpenMyList();
  }

  Future<void> _checkOpenMyList() async {
    if (!Platform.isIOS) return;
    try {
      final should =
          await _channel.invokeMethod<bool>('checkAndClearOpenMyList');
      if (should != true) return;

      // Poll until the navigator is mounted (typically 1-2 frames, ~50 ms).
      for (var i = 0; i < 20; i++) {
        if (_navigatorKey.currentState != null) break;
        await Future.delayed(const Duration(milliseconds: 50));
      }
      final nav = _navigatorKey.currentState;
      if (nav == null) return;

      nav.pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const AddPhraseScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => route.isFirst,
      );
    } catch (_) {}
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
    if (uri.scheme != 'fonkii') return;
    final host = uri.host.toLowerCase();
    if (host == 'addphrase' || host == 'mylist') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AddPhraseScreen()),
          (route) => route.isFirst,
        );
      });
    }
  }

  Future<_LaunchTarget> _resolveTarget() async {
    debugPrint('🔥 [resolveTarget] 시작');
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(onboardingCompletedKey) ?? false;
    debugPrint('🔥 [resolveTarget] 온보딩 완료: $onboardingDone');

    if (!onboardingDone) {
      if (prefs.getBool(onboardingPage2VisitedKey) ?? false) return _LaunchTarget.page2;
      return _LaunchTarget.page1;
    }

    if (Platform.isIOS) {
      try {
        // Primary: in-memory flag set by AppDelegate when fonkii://myList URL received.
        // More reliable than App Group on cold start (no inter-process sync delay).
        final pending = await _channel.invokeMethod<bool>('consumePendingAddPhrase');
        debugPrint('🔥 [resolveTarget] consumePendingAddPhrase 결과: $pending');
        if (pending == true) {
          debugPrint('🔥 [resolveTarget] 최종 target: myList (consumePendingAddPhrase)');
          return _LaunchTarget.myList;
        }

        // Fallback: App Group UserDefaults flag written by keyboard before opening app.
        // Covers the LSApplicationWorkspace bundle-ID-only path where URL callback
        // doesn't fire. May have slight inter-process sync delay on cold start.
        final openMyList = await _channel.invokeMethod<bool>('checkAndClearOpenMyList');
        debugPrint('🔥 [resolveTarget] checkAndClearOpenMyList 결과: $openMyList');
        if (openMyList == true) {
          debugPrint('🔥 [resolveTarget] 최종 target: myList (checkAndClearOpenMyList)');
          return _LaunchTarget.myList;
        }
      } catch (e) {
        debugPrint('🔥 [resolveTarget] 채널 오류: $e');
      }
    }

    debugPrint('🔥 [resolveTarget] 최종 target: home');
    return _LaunchTarget.home;
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
          case _LaunchTarget.myList:
            debugPrint('🔥 [FutureBuilder] myList 케이스 진입');
            if (!_myListPushed) {
              _myListPushed = true;
              debugPrint('🔥 [FutureBuilder] postFrameCallback 등록');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                debugPrint('🔥 [FutureBuilder] AddPhraseScreen push 시도');
                debugPrint('🔥 [FutureBuilder] navigatorKey.currentState: ${_navigatorKey.currentState == null ? "NULL ❌" : "OK ✅"}');
                _navigatorKey.currentState?.push(
                  PageRouteBuilder(
                    pageBuilder: (_, a, b) => const AddPhraseScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
                debugPrint('🔥 [FutureBuilder] push 완료');
              });
            }
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
