import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/subscription_service.dart';
import 'guide_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

const _pink = Color(0xFF5BC8F5);

/// HomeScreen: AppBar (logo + settings) + tabbed body (Chat / Subscription)
/// + bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.tierListenable.addListener(_onTier);
  }

  @override
  void dispose() {
    SubscriptionService.instance.tierListenable.removeListener(_onTier);
    super.dispose();
  }

  void _onTier() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset =
        isDark ? 'assets/images/logo_white.png' : 'assets/images/logo_black.png';

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Image.asset(logoAsset, height: 28),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _ChatTab(),
          GuideScreen(),
          SubscriptionScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 2) {
            // Subscription tab → open Adapty paywall directly without switching tab
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '체험하기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            activeIcon: Icon(Icons.help),
            label: '가이드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium_outlined),
            activeIcon: Icon(Icons.workspace_premium),
            label: '구독',
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Chat experience tab
// ══════════════════════════════════════════════════════════════════════════

class _ChatMessage {
  _ChatMessage({this.text, this.gifUrl, required this.fromMe})
      : assert(text != null || gifUrl != null);
  final String? text;
  final String? gifUrl;
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
  final _messages = <_ChatMessage>[
    _ChatMessage(text: '안녕! 새로운 키보드 써봤어? 😊', fromMe: false),
    _ChatMessage(text: '응! Fonkii 키보드인데 폰트도 바꿀 수 있어', fromMe: true),
    _ChatMessage(text: '진짜? 어떻게 생겼어? 보여줘!', fromMe: false),
  ];

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.tierListenable.addListener(_onTier);
  }

  @override
  void dispose() {
    SubscriptionService.instance.tierListenable.removeListener(_onTier);
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTier() {
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

  static const _appGroupChannel =
      MethodChannel('com.yunajung.fonki/appgroup');

  /// Paste handler: first checks the App Group stash that the keyboard
  /// extension writes when copying a GIF (which the standard Clipboard API
  /// can't see — GIFs are copied as `com.compuserve.gif` binary data, not
  /// plain text). Falls back to text clipboard if no GIF URL is queued.
  Future<void> _pasteFromClipboard() async {
    String? gifUrl;
    try {
      gifUrl = await _appGroupChannel.invokeMethod<String>('getLastCopiedGifUrl');
    } catch (_) {
      gifUrl = null;
    }
    if (!mounted) return;

    if (gifUrl != null) {
      final lower = gifUrl.toLowerCase();
      final looksLikeGif = lower.contains('giphy.com') ||
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

    // Fallback — plain text clipboard (Giphy URL pasted manually, or
    // ordinary text the user wants to drop into the input field).
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    if (!mounted) return;

    final lower = text.toLowerCase();
    final looksLikeGif = lower.contains('giphy.com') ||
        lower.endsWith('.gif') ||
        lower.contains('.gif?');
    if (looksLikeGif) {
      setState(() {
        _messages.add(_ChatMessage(gifUrl: text, fromMe: true));
      });
      _scrollToBottom();
    } else {
      _input.text = text;
      _input.selection =
          TextSelection.collapsed(offset: _input.text.length);
    }
  }

  Future<void> _openPaywall() async {
    if (SubscriptionService.instance.isPremiumNow) return;
    await PaywallScreen.show(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgChat = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final isPremium = SubscriptionService.instance.isPremiumNow;

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
                          'Fonkii 키보드 체험하기',
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
                            horizontal: 12, vertical: 4),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _ChatBubble(message: _messages[i], isDark: isDark),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isPremium ? null : _openPaywall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium
                      ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                      : _pink,
                  foregroundColor: isPremium
                      ? (isDark ? Colors.white60 : Colors.grey.shade700)
                      : Colors.white,
                  disabledBackgroundColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  disabledForegroundColor:
                      isDark ? Colors.white60 : Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isPremium ? '✓ 프리미엄 이용 중' : '✨ 프리미엄 시작하기',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
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
    if (message.gifUrl != null) {
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
                        Icons.broken_image, color: Colors.white, size: 48),
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
                        color: isDark
                            ? Colors.white54
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
            errorBuilder: (_, _, _) => Container(
              width: 200,
              height: 120,
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Icon(Icons.broken_image,
                  color: isDark
                      ? Colors.white38
                      : Colors.grey.shade500),
            ),
          ),
        ),
      );
    } else {
      // Detect dot-art by the presence of Braille codepoints (U+2800-U+28FF).
      // Dot-art needs `softWrap: false` + horizontal scroll to keep its grid
      // intact; ordinary text/emoticon messages should wrap naturally so the
      // bubble doesn't blow out into a single long horizontal strip.
      final isDotArt = message.text?.runes
              .any((r) => r >= 0x2800 && r <= 0x28FF) ??
          false;
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
        mainAxisAlignment:
            me ? MainAxisAlignment.end : MainAxisAlignment.start,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 5,
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
                items.add(ContextMenuButtonItem(
                  type: ContextMenuButtonType.paste,
                  onPressed: () {
                    ContextMenuController.removeAny();
                    onPaste();
                  },
                ));
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: items,
                );
              },
              decoration: InputDecoration(
                hintText: '메시지 입력...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
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
                child: Icon(Icons.arrow_upward,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
