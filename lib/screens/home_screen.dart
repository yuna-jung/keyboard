import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
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
          SubscriptionScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 1) {
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
  _ChatMessage({required this.text, required this.fromMe});
  final String text;
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(me ? 16 : 4),
                  bottomRight: Radius.circular(me ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(fontSize: 15, color: fg, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isDark,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
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
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
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
