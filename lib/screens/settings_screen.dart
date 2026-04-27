import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open a URL whose target depends on device language: Korean device gets
  /// `koUrl`, everything else gets `enUrl`.
  Future<void> _openUrl(BuildContext context, String koUrl, String enUrl) async {
    final locale = Localizations.localeOf(context).languageCode;
    final url = locale == 'ko' ? koUrl : enUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open the iOS Settings page for this app via the `app-settings:` scheme.
  Future<void> _openAppSettings() async {
    final uri = Uri.parse('app-settings:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: const Text('설정',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.close,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: '소셜', isDark: isDark),
          _SettingTile(
            icon: Icons.ios_share,
            label: '앱 공유',
            isDark: isDark,
            onTap: () {
              const appStoreUrl =
                  'https://apps.apple.com/app/fonkii/id6762085484';
              const message =
                  'Fonkii 키보드로 더 재밌게 소통해요! 🎨\n$appStoreUrl';
              SharePlus.instance.share(ShareParams(text: message));
            },
          ),
          _SectionHeader(title: '도움말', isDark: isDark),
          _SettingTile(
            icon: Icons.support_agent,
            label: '고객 지원',
            isDark: isDark,
            onTap: () => _open('mailto:contact.rowan.00@gmail.com'),
          ),
          _SettingTile(
            icon: Icons.help_outline,
            label: '지원 센터',
            isDark: isDark,
            onTap: () => _open('mailto:contact.rowan.00@gmail.com'),
          ),
          _SectionHeader(title: '법적 고지', isDark: isDark),
          _SettingTile(
            icon: Icons.description_outlined,
            label: '서비스 약관',
            isDark: isDark,
            onTap: () => _openUrl(
              context,
              'https://fonkii-keyboard.github.io/Fonkii/terms-of-service-ko.html',
              'https://fonkii-keyboard.github.io/Fonkii/terms-of-service-en.html',
            ),
          ),
          _SettingTile(
            icon: Icons.shield_outlined,
            label: '개인정보처리방침',
            isDark: isDark,
            onTap: () => _openUrl(
              context,
              'https://fonkii-keyboard.github.io/Fonkii/privacy-policy-ko.html',
              'https://fonkii-keyboard.github.io/Fonkii/privacy-policy-en.html',
            ),
          ),
          _SettingTile(
            icon: Icons.lock_outline,
            label: '개인정보 보호 설정',
            isDark: isDark,
            onTap: _openAppSettings,
          ),
          _SettingTile(
            icon: Icons.code,
            label: '오픈소스 라이브러리',
            isDark: isDark,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Fonkii',
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
