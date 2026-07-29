import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _appGroupChannel = MethodChannel('com.yunajung.fonki/appgroup');

  // Ships on by default (see the native "unset key reads as true" default
  // in AppDelegate.swift's `getKeyboardHapticSettings` — this is just a
  // placeholder until that first read completes).
  bool _hapticEnabled = true;
  bool _hasFullAccess = false;
  bool _loadingHaptic = true;

  @override
  void initState() {
    super.initState();
    _loadHapticSettings();
  }

  /// `hasFullAccess` here is the keyboard extension's own last-known status,
  /// mirrored into the App Group on its side (see `viewDidLoad`/
  /// `viewWillAppear` in KeyboardViewController.swift) — there's no public
  /// API for the containing app to query Full Access directly, so this can
  /// lag until the keyboard is actually opened at least once after the user
  /// grants it. Re-read every time this screen appears (not cached across
  /// screens) so returning here after toggling Full Access in iOS Settings
  /// picks up a stale value as soon as possible.
  Future<void> _loadHapticSettings() async {
    try {
      final result = await _appGroupChannel.invokeMethod<Map<Object?, Object?>>(
        'getKeyboardHapticSettings',
      );
      if (!mounted) return;
      setState(() {
        _hapticEnabled = result?['enabled'] as bool? ?? true;
        _hasFullAccess = result?['hasFullAccess'] as bool? ?? false;
        _loadingHaptic = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHaptic = false);
    }
  }

  Future<void> _setHapticEnabled(bool value) async {
    setState(() => _hapticEnabled = value);
    try {
      await _appGroupChannel.invokeMethod('setKeyboardHapticEnabled', {
        'enabled': value,
      });
    } catch (_) {
      // App Group unavailable — revert the optimistic UI update.
      if (mounted) setState(() => _hapticEnabled = !value);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open a URL whose target depends on device language: Korean device gets
  /// `koUrl`, everything else gets `enUrl`. Uses `Platform.localeName`
  /// (e.g. "ko_KR") so detection works regardless of MaterialApp's
  /// supportedLocales configuration.
  Future<void> _openUrl(
    BuildContext context,
    String koUrl,
    String enUrl,
  ) async {
    final locale = Platform.localeName.split('_').first;
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
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          l.settingsTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: l.settingsSectionKeyboard, isDark: isDark),
          _SettingSwitchTile(
            icon: Icons.vibration,
            label: l.settingsKeyboardHapticTitle,
            subtitle: _hasFullAccess
                ? l.settingsKeyboardHapticSubtitle
                : l.settingsKeyboardHapticFullAccessNotice,
            subtitleIsWarning: !_hasFullAccess,
            isDark: isDark,
            value: _hapticEnabled,
            // Deliberately NOT gated on `_hasFullAccess` — that flag is the
            // keyboard extension's own last-known status, mirrored into the
            // App Group only when the extension actually runs (see
            // `viewWillAppear` in KeyboardViewController.swift), so it can
            // read stale/false here even while Full Access is genuinely on
            // (e.g. right after granting it, before the keyboard has been
            // reopened). Disabling the switch on that stale read silently
            // blocked every write to `keyboardHapticEnabled` — the actual
            // bug behind "toggled it on, still reads false" — even though
            // the real gating already happens safely on the extension side,
            // which always checks the *live* `hasFullAccess` at the moment
            // of each keystroke. So the preference is always settable; only
            // its *effect* depends on Full Access actually being on.
            enabled: !_loadingHaptic,
            onChanged: _setHapticEnabled,
            // Full Access notice stays purely informational — still offers
            // the same one-tap shortcut to Settings, just without blocking
            // the switch itself.
            onRowTap: _hasFullAccess ? null : _openAppSettings,
          ),
          _SectionHeader(title: l.settingsSectionSocial, isDark: isDark),
          _SettingTile(
            icon: Icons.ios_share,
            label: l.settingsShareApp,
            isDark: isDark,
            onTap: () {
              SharePlus.instance.share(
                ShareParams(text: l.settingsShareMessage),
              );
            },
          ),
          _SectionHeader(title: l.settingsSectionHelp, isDark: isDark),
          _SettingTile(
            icon: Icons.support_agent,
            label: l.settingsSupport,
            isDark: isDark,
            onTap: () => _open('mailto:contact.rowan.00@gmail.com'),
          ),
          _SectionHeader(title: l.settingsSectionLegal, isDark: isDark),
          _SettingTile(
            icon: Icons.description_outlined,
            label: l.settingsTerms,
            isDark: isDark,
            onTap: () => _openUrl(
              context,
              'https://fonkii-keyboard.github.io/Fonkii/terms-of-service-ko.html',
              'https://fonkii-keyboard.github.io/Fonkii/terms-of-service-en.html',
            ),
          ),
          _SettingTile(
            icon: Icons.shield_outlined,
            label: l.settingsPrivacy,
            isDark: isDark,
            onTap: () => _openUrl(
              context,
              'https://fonkii-keyboard.github.io/Fonkii/privacy-policy-ko.html',
              'https://fonkii-keyboard.github.io/Fonkii/privacy-policy-en.html',
            ),
          ),
          _SettingTile(
            icon: Icons.lock_outline,
            label: l.settingsPrivacySettings,
            isDark: isDark,
            onTap: _openAppSettings,
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
            Icon(
              icon,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
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
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.subtitleIsWarning = false,
    this.onRowTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool subtitleIsWarning;
  final VoidCallback? onRowTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRowTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleIsWarning
                          ? const Color(0xFFE8935C)
                          : (isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
