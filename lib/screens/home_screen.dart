import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/subscription_service.dart';
import 'add_phrase_screen.dart';
import 'guide_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';
import 'sticker_screen.dart';

const _pink = Color(0xFF5BC8F5);

/// HomeScreen: AppBar (logo + settings) + tabbed body (Chat / Guide /
/// optionally Subscription) + bottom navigation bar. Subscription is
/// iOS-only — Android skips the tab and all paywall/Adapty plumbing so
/// the Flutter side stays inert on that platform.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  /// iOS-only platform gate. Cached at construction so every build / handler
  /// reuses the same answer. On Android this is `false`, which trims the
  /// subscription tab, the paywall deep-link handler, and the Adapty tier
  /// listener entirely.
  static final bool _isIOS = Platform.isIOS;

  /// Same channel name as `_ChatTabState._appGroupChannel`. Dart-side handlers
  /// are global per channel name, so we hook listening here (HomeScreen owns
  /// the navigator context needed to push the paywall). iOS-only.
  static const _appGroupChannel = MethodChannel('com.yunajung.fonki/appgroup');

  /// Guard against the paywall being pushed twice. Two events can race here:
  /// the warm-start `openPaywall` invokeMethod and the cold-start
  /// `consumePendingPaywall` drain (AppDelegate fires both for safety on a
  /// single deep-link). The flag flips on entry and resets when the bottom
  /// sheet closes.
  bool _paywallShowing = false;
  bool _addPhraseShowing = false;

  @override
  void initState() {
    super.initState();
    if (!_isIOS) return;
    SubscriptionService.instance.tierListenable.addListener(_onTier);
    // Live `openPaywall` / `openAddPhrase` events from native deep links.
    _appGroupChannel.setMethodCallHandler(_handleNativeCall);
    // Cold-start drain for paywall.
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainPendingPaywall());
  }

  @override
  void dispose() {
    if (_isIOS) {
      SubscriptionService.instance.tierListenable.removeListener(_onTier);
      _appGroupChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  void _onTier() {
    if (mounted) setState(() {});
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'openPaywall') {
      _showPaywall();
    } else if (call.method == 'openAddPhrase') {
      _showAddPhrase();
    }
    return null;
  }

  Future<void> _drainPendingPaywall() async {
    try {
      final pending = await _appGroupChannel.invokeMethod<bool>(
        'consumePendingPaywall',
      );
      if (pending == true) _showPaywall();
    } catch (_) {
      // Native handler not registered yet on first launch — ignore; live
      // `openPaywall` events still flow through `setMethodCallHandler`.
    }
  }

  void _showPaywall() {
    if (!_isIOS || !mounted) return;
    if (_paywallShowing) return;
    _paywallShowing = true;
    // Defer to the next frame so `context` is mounted under the Navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _paywallShowing = false;
        return;
      }
      try {
        await PaywallScreen.show(context);
      } finally {
        if (mounted) _paywallShowing = false;
      }
    });
  }

  void _showAddPhrase() {
    if (!mounted) return;
    if (_addPhraseShowing) return;
    _addPhraseShowing = true;
    // Consume both flags so racing paths are no-ops:
    // - consumePendingAddPhrase: clears AppDelegate flag → stops 1.5s delayed retry
    // - checkAndClearOpenMyList: clears App Group flag → _checkOpenMyList() in main.dart returns early
    _appGroupChannel.invokeMethod<bool>('consumePendingAddPhrase');
    _appGroupChannel.invokeMethod<bool>('checkAndClearOpenMyList');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addPhraseShowing = false;
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.popUntil((route) => route.isFirst);
      nav.push(MaterialPageRoute(builder: (_) => const AddPhraseScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/images/logo_white.png'
        : 'assets/images/logo_black.png';
    final l = AppLocalizations.of(context)!;

    // Tab list. The 구독 tab item is added to `navItems` on iOS but NOT
    // backed by a screen here — its tap handler (below) opens the Adapty
    // paywall as a modal and returns without flipping `_selectedIndex`,
    // so dismissing the paywall lands the user back on whatever tab they
    // were on before. Keeping `IndexedStack` length at 3 also prevents
    // any accidental index-out-of-range if `_selectedIndex` ever drifted
    // to 3 — 구독's index (it can't, by construction).
    final screens = <Widget>[
      const _ChatTab(),
      StickerScreen(isActive: _selectedIndex == 1),
      const GuideScreen(),
    ];
    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.chat_bubble_outline),
        activeIcon: const Icon(Icons.chat_bubble),
        label: l.homeTabTrial,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.photo_library_outlined),
        activeIcon: const Icon(Icons.photo_library),
        label: l.homeTabStickerMaker,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.help_outline),
        activeIcon: const Icon(Icons.help),
        label: l.homeTabGuide,
      ),
      if (_isIOS)
        BottomNavigationBarItem(
          icon: const Icon(Icons.workspace_premium_outlined),
          activeIcon: const Icon(Icons.workspace_premium),
          label: l.homeTabSubscription,
        ),
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Image.asset(logoAsset, height: 28),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.format_list_bulleted,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: l.homeMyListTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPhraseScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          // iOS 구독 tab (index 3): show the Adapty paywall as a modal and
          // return WITHOUT touching `_selectedIndex`. Dismissing the paywall
          // (StoreKit cancel, X button, swipe down) leaves the user on
          // whatever tab they were on before tapping 구독 — there is no
          // SubscriptionScreen behind it to fall through to.
          if (_isIOS && i == 3) {
            PaywallScreen.show(context);
            return;
          }
          setState(() => _selectedIndex = i);
        },
        backgroundColor: isDark ? Colors.black : Colors.white,
        selectedItemColor: _pink,
        unselectedItemColor: isDark ? Colors.white38 : Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: navItems,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Chat experience tab
// ══════════════════════════════════════════════════════════════════════════

class _ChatMessage {
  _ChatMessage({
    this.text,
    this.gifUrl,
    this.stickerBytes,
    this.stickerIsGif = false,
    required this.fromMe,
  }) : assert(text != null || gifUrl != null || stickerBytes != null);
  final String? text;
  final String? gifUrl;

  /// Raw PNG/GIF bytes pasted from a sticker copied via the keyboard's
  /// sticker tab (`UIPasteboard`, not a network URL like `gifUrl` — see
  /// `_ChatTabState._pasteFromClipboard`). `stickerIsGif` only matters for
  /// picking the right rendering path; `Image.memory` itself doesn't need
  /// to know — it animates multi-frame GIF byte data automatically, same
  /// as it does for `Image.file`/`Image.network`.
  final Uint8List? stickerBytes;
  final bool stickerIsGif;
  final bool fromMe;
}

class _ChatTab extends StatefulWidget {
  const _ChatTab();

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  late final List<_ChatMessage> _messages;
  bool _messagesInitialized = false;

  /// Mirrors `_HomeScreenState._isIOS` — Android skips the CTA wiring
  /// entirely (no listener, no button render, no paywall import use).
  static final bool _isIOS = Platform.isIOS;

  @override
  void initState() {
    super.initState();
    // iOS-only: live-update the CTA visibility when Adapty's tier flips
    // (purchase, restore, refund). On Android the listener is never wired.
    if (_isIOS) {
      SubscriptionService.instance.tierListenable.addListener(_onTier);
    }
  }

  @override
  void dispose() {
    if (_isIOS) {
      SubscriptionService.instance.tierListenable.removeListener(_onTier);
    }
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTier() {
    if (mounted) setState(() {});
  }

  Future<void> _openPaywall() async {
    await PaywallScreen.show(context);
    // `tierListenable` will already fire on a successful purchase, but
    // call setState here too so the CTA disappears immediately on dismiss
    // even if the tier didn't change (covers the cancel-but-already-premium
    // edge case where the listener wouldn't be re-triggered).
    if (mounted) setState(() {});
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: t, fromMe: true));
      _input.clear();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static const _appGroupChannel = MethodChannel('com.yunajung.fonki/appgroup');

  /// Paste handler, checked in order:
  ///   1. The App Group stash the keyboard's GIF *search* tab writes when
  ///      copying a remote GIF (a Giphy URL — the standard Clipboard API
  ///      can't see it either way, since it's never plain text).
  ///   2. The real system pasteboard for sticker image bytes — the
  ///      keyboard's *sticker* tab copies local PNG/GIF files as raw binary
  ///      data straight onto `UIPasteboard` (see `stickerCellTapped` in
  ///      KeyboardViewController.swift), which Flutter's `Clipboard` API
  ///      has no way to read at all (it only ever exposes plain text), so
  ///      this goes through a native channel instead.
  ///   3. Plain text clipboard, as a final fallback.
  Future<void> _pasteFromClipboard() async {
    String? gifUrl;
    try {
      gifUrl = await _appGroupChannel.invokeMethod<String>(
        'getLastCopiedGifUrl',
      );
    } catch (_) {
      gifUrl = null;
    }
    if (!mounted) return;

    if (gifUrl != null) {
      final lower = gifUrl.toLowerCase();
      final looksLikeGif =
          lower.contains('giphy.com') ||
          lower.endsWith('.gif') ||
          lower.contains('.gif?');
      if (looksLikeGif) {
        setState(() {
          _messages.add(_ChatMessage(gifUrl: gifUrl, fromMe: true));
        });
        _scrollToBottom();
        // Consume the stash so the same GIF doesn't keep re-pasting.
        try {
          await _appGroupChannel.invokeMethod('clearLastCopiedGifUrl');
        } catch (_) {}
        return;
      }
    }

    Map<Object?, Object?>? clipboardImage;
    try {
      clipboardImage = await _appGroupChannel
          .invokeMethod<Map<Object?, Object?>>('getClipboardImageData');
    } catch (_) {
      clipboardImage = null;
    }
    if (!mounted) return;
    if (clipboardImage != null) {
      final type = clipboardImage['type'] as String?;
      final bytes = clipboardImage['data'] as Uint8List?;
      if (type != null && bytes != null) {
        setState(() {
          _messages.add(
            _ChatMessage(
              stickerBytes: bytes,
              stickerIsGif: type == 'gif',
              fromMe: true,
            ),
          );
        });
        _scrollToBottom();
        return;
      }
    }

    // Fallback — plain text clipboard (Giphy URL pasted manually, or
    // ordinary text the user wants to drop into the input field).
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    if (!mounted) return;

    final lower = text.toLowerCase();
    final looksLikeGif =
        lower.contains('giphy.com') ||
        lower.endsWith('.gif') ||
        lower.contains('.gif?');
    if (looksLikeGif) {
      setState(() {
        _messages.add(_ChatMessage(gifUrl: text, fromMe: true));
      });
      _scrollToBottom();
    } else {
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgChat = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final l = AppLocalizations.of(context)!;

    if (!_messagesInitialized) {
      _messages = [
        _ChatMessage(text: l.homeChatMsg1, fromMe: false),
        _ChatMessage(text: l.homeChatMsg2, fromMe: true),
        _ChatMessage(text: l.homeChatMsg3, fromMe: false),
      ];
      _messagesInitialized = true;
    }

    // Show CTA only on iOS *and* only while the user is non-premium.
    // Reading from `SubscriptionService` is cheap (it just returns a cached
    // tier); the `tierListenable` we registered in initState forces a
    // setState whenever Adapty's tier changes so this re-evaluates live.
    final showPremiumCta = _isIOS && !SubscriptionService.instance.isPremiumNow;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgChat,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l.homeChatSectionTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _ChatBubble(
                            message: _messages[i],
                            isDark: isDark,
                          ),
                        ),
                      ),
                      _ChatInput(
                        controller: _input,
                        focusNode: _focus,
                        onSend: _send,
                        onPaste: _pasteFromClipboard,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              if (showPremiumCta) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _openPaywall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l.homePremiumCta,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ] else if (_isIOS) ...[
                // Premium-active state on iOS: disabled grey button as the
                // current-status indicator. Same height/radius/typography as
                // the CTA above so the chat layout doesn't reflow when tier
                // flips. Android skips this branch (`_isIOS` false) and
                // renders nothing — no subscription concept on that side.
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      disabledForegroundColor: isDark
                          ? Colors.white60
                          : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l.homePremiumActive,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isDark});
  final _ChatMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final me = message.fromMe;
    final bg = me ? _pink : (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    final fg = me ? Colors.white : (isDark ? Colors.white : Colors.black87);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(me ? 16 : 4),
      bottomRight: Radius.circular(me ? 4 : 16),
    );

    final Widget content;
    if (message.stickerBytes != null) {
      final bytes = message.stickerBytes!;
      // `Image.memory` animates multi-frame GIF byte data automatically —
      // same underlying codec Flutter uses for `Image.file`/`Image.network`
      // — so `stickerIsGif` doesn't need to pick a different widget here,
      // only whether the bytes came from a GIF at all (unused directly,
      // kept on the message for anything that might need it later, e.g.
      // debugging which pasteboard type actually matched).
      content = GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.92),
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: radius,
          child: Image.memory(
            bytes,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 200,
              height: 120,
              color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      );
    } else if (message.gifUrl != null) {
      final stillUrl = message.gifUrl!;
      final animatedUrl = message.gifUrl!;
      content = GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.92),
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  child: Image.network(
                    animatedUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: radius,
          child: Image.network(
            stillUrl,
            width: 200,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : SizedBox(
                    width: 200,
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white54 : Colors.grey.shade400,
                      ),
                    ),
                  ),
            errorBuilder: (_, _, _) => Container(
              width: 200,
              height: 120,
              color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      );
    } else {
      // Detect dot-art by the presence of Braille codepoints (U+2800-U+28FF).
      // Dot-art needs `softWrap: false` + horizontal scroll to keep its grid
      // intact; ordinary text/emoticon messages should wrap naturally so the
      // bubble doesn't blow out into a single long horizontal strip.
      final isDotArt =
          message.text?.runes.any((r) => r >= 0x2800 && r <= 0x28FF) ?? false;
      final textWidget = Text(
        message.text ?? '',
        softWrap: !isDotArt,
        style: TextStyle(
          fontSize: 13,
          color: fg,
          height: 1.2,
          letterSpacing: 0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: isDotArt
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(child: textWidget),
                )
              : SingleChildScrollView(child: textWidget),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [Flexible(child: content)],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onPaste,
    required this.isDark,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onPaste;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 4,
              minLines: 1,
              maxLength: 1000,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.2,
                letterSpacing: 0,
              ),
              // Intercept the system Paste button so a copied GIF lands as a
              // GIF bubble (not raw text). Routes through `_pasteFromClipboard`
              // which checks the App Group for the keyboard's last-copied URL
              // before falling back to the OS clipboard's plain text.
              //
              // Force-inject the paste item: GIFs are stashed in App Group
              // UserDefaults, never on `UIPasteboard.general`, so Flutter's
              // `contextMenuButtonItems` would otherwise omit "Paste" whenever
              // the system clipboard is empty — leaving the user with no way
              // to drop a copied GIF into the chat.
              contextMenuBuilder: (context, editableTextState) {
                final items = editableTextState.contextMenuButtonItems
                    .where((i) => i.type != ContextMenuButtonType.paste)
                    .toList();
                items.add(
                  ContextMenuButtonItem(
                    type: ContextMenuButtonType.paste,
                    onPressed: () {
                      ContextMenuController.removeAny();
                      onPaste();
                    },
                  ),
                );
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: items,
                );
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.homeChatHint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: _pink,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_upward, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
