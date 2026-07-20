import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_ko.dart';
import '../widgets/trial_notification_primer_dialog.dart';
import 'app_navigation.dart';

/// Schedules the "trial ending in 2 days" local reminder for free-trial
/// subscribers. Everything here is best-effort and fails silently — this is
/// a nice-to-have reminder, not a feature the app depends on, so a denied
/// permission or a plugin error must never surface to the user or interrupt
/// [SubscriptionService]'s profile syncing.
class TrialNotificationService {
  TrialNotificationService._();
  static final instance = TrialNotificationService._();

  /// Fixed so every schedule/cancel call targets the same slot — there is
  /// never more than one trial-expiry reminder pending at a time.
  static const int _trialExpiryNotificationId = 90001;

  /// TODO: REMOVE - 테스트용. When true, the reminder is scheduled to fire
  /// ~30 seconds from now instead of "2 days before expiry, at noon" — lets
  /// the full flow (permission prompt → schedule → actual delivery) be
  /// verified on a real device without needing a multi-day sandbox trial.
  static const bool debugFireReminderSoon = false;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // There's no device-timezone plugin in the dependency tree, so the
    // local zone is approximated from the current UTC offset via a
    // fixed-offset Etc/GMT zone. A DST transition between now and the
    // scheduled date could drift the "noon" wall-clock time by up to an
    // hour — acceptable for a reminder sent two days in advance.
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final tzName = offsetHours == 0
        ? 'UTC'
        // Etc/GMT uses inverted signs: Etc/GMT-9 is UTC+9.
        : 'Etc/GMT${offsetHours > 0 ? '-' : '+'}${offsetHours.abs()}';
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: iosSettings,
          android: androidSettings,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 [TrialNotificationService] initialize failed: $e');
      }
    }
    _initialized = true;
  }

  /// Whether the app has ever actually triggered the real iOS/Android
  /// system permission prompt (as opposed to just showing our own primer).
  /// Nothing else in the app requests notification permission, so "never
  /// triggered" is equivalent to the system's own "not determined" status —
  /// the plugin's own [_isPermissionGranted] check can't tell "not
  /// determined" apart from "denied" (both report as not-enabled), so this
  /// locally-tracked flag is what actually answers that question.
  static const _systemPermissionRequestedKey =
      'trial_notification_system_permission_requested';

  Future<bool> _hasRequestedSystemPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_systemPermissionRequestedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markSystemPermissionRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_systemPermissionRequestedKey, true);
    } catch (_) {}
  }

  Future<bool> _isPermissionGranted() async {
    try {
      if (Platform.isIOS) {
        final status = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return status?.isEnabled ?? false;
      } else if (Platform.isAndroid) {
        final enabled = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
        return enabled ?? false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 [TrialNotificationService] permission check failed: $e');
      }
    }
    return false;
  }

  /// Shows [TrialNotificationPrimerDialog] if a navigator is currently
  /// mounted, returning `true` only if the user tapped "확인". Returns
  /// `false` (without showing anything) when there's no context yet — e.g.
  /// this fires during the pre-`runApp` profile check on cold launch — so
  /// the caller neither shows the system prompt nor marks it as asked; the
  /// next profile re-evaluation (app resume, live profile update, etc.)
  /// will simply try again once a navigator exists.
  Future<bool> _showPrimerIfPossible() async {
    if (appNavigatorKey.currentContext == null) {
      if (kDebugMode) {
        debugPrint(
          '🔥 [TrialNotificationService] no navigator context yet, '
          'skipping primer this time',
        );
      }
      return false;
    }
    // Give any purchase-sheet/paywall dismissal animation a moment to
    // settle before stacking another dialog on top of it.
    await Future.delayed(const Duration(milliseconds: 1200));
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return false;

    final confirmed = await TrialNotificationPrimerDialog.show(ctx);
    if (kDebugMode) {
      debugPrint(
        '🔥 [TrialNotificationService] primer dialog confirmed=$confirmed',
      );
    }
    return confirmed;
  }

  /// Resolves notification text for the device's current language. Reads
  /// `PlatformDispatcher` directly rather than `AppLocalizations.of(context)`
  /// — this runs from the service layer with no guaranteed live
  /// `BuildContext`, and mirrors the same ko-or-en binary check `main.dart`'s
  /// own `localeResolutionCallback` uses for the rest of the app. iOS local
  /// notifications are scheduled with a fixed string at `zonedSchedule`
  /// time, so a language change after scheduling won't retroactively
  /// re-translate an already-scheduled reminder — an inherent limitation of
  /// local notifications generally, not specific to this feature.
  AppLocalizations _localizedStrings() {
    final isKorean = ui.PlatformDispatcher.instance.locale.languageCode == 'ko';
    return isKorean ? AppLocalizationsKo() : AppLocalizationsEn();
  }

  /// Triggers the real system permission prompt. Only ever called right
  /// after the user confirms our own primer dialog, so — since nothing else
  /// in the app requests notification permission — this is effectively
  /// "ask at trial start" rather than at app launch.
  Future<void> _requestPermission() async {
    try {
      await _markSystemPermissionRequested();
      if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '🔥 [TrialNotificationService] permission request failed: $e',
        );
      }
    }
  }

  /// Guards against overlapping calls to [scheduleTrialExpiryIfNeeded] —
  /// `_applyProfile` in `SubscriptionService` can fire more than once in
  /// quick succession around a purchase (its own `refreshStatus()` call
  /// plus a concurrent `didUpdateProfileStream` event), and since the
  /// "already scheduled" dedup check only starts working once
  /// `zonedSchedule` has actually run, two overlapping calls could each
  /// independently decide permission is still undetermined and both show
  /// [TrialNotificationPrimerDialog] — stacking two dialog routes, so
  /// dismissing the top one left an identical one still on screen. This
  /// flag makes only the *first* concurrent call actually run the flow;
  /// it is reset in `finally` so a skip here is never permanent — the next
  /// `_applyProfile` call (resume, next profile refresh, etc.) tries again
  /// normally.
  bool _schedulingInFlight = false;

  /// Schedules the trial-expiry reminder for `expiresAt` unless one is
  /// already pending. If notification permission is still undetermined,
  /// shows [TrialNotificationPrimerDialog] first and only triggers the real
  /// system prompt if the user confirms it — called only once a trial is
  /// actually active, so in practice this means the primer (and, if
  /// confirmed, the system prompt) appears at trial start rather than at
  /// app launch. Never throws.
  Future<void> scheduleTrialExpiryIfNeeded(DateTime expiresAt) async {
    if (_schedulingInFlight) {
      if (kDebugMode) {
        debugPrint(
          '🔥 [TrialNotificationService] scheduling already in flight, '
          'skipping this call (expiresAt=$expiresAt)',
        );
      }
      return;
    }
    _schedulingInFlight = true;
    try {
      await _ensureInitialized();

      final pending = await _plugin.pendingNotificationRequests();
      if (pending.any((n) => n.id == _trialExpiryNotificationId)) {
        if (kDebugMode) {
          debugPrint(
            '🔥 [TrialNotificationService] already scheduled, skipping '
            '(expiresAt=$expiresAt)',
          );
        }
        return;
      }

      DateTime scheduledAt;
      if (debugFireReminderSoon) {
        scheduledAt = DateTime.now().add(const Duration(seconds: 30));
      } else {
        final reminderDay = expiresAt.subtract(const Duration(days: 2));
        scheduledAt = DateTime(
          reminderDay.year,
          reminderDay.month,
          reminderDay.day,
          12,
          0,
          0,
        );
      }
      if (!scheduledAt.isAfter(DateTime.now())) {
        if (kDebugMode) {
          debugPrint(
            '🔥 [TrialNotificationService] computed time $scheduledAt is '
            'already past, skipping (expiresAt=$expiresAt)',
          );
        }
        return;
      }

      // Only go through the primer → system-prompt flow when permission
      // hasn't been granted yet AND we've genuinely never asked before
      // (i.e. the system status is still "not determined" — see
      // `_hasRequestedSystemPermission`'s doc comment for why that flag,
      // not the plugin's own check, is what answers this). Already
      // granted → nothing to ask. Already asked-and-not-granted → already
      // denied, asking again would be a no-op, so don't show the primer
      // again either.
      if (!await _isPermissionGranted() && !await _hasRequestedSystemPermission()) {
        final confirmed = await _showPrimerIfPossible();
        if (confirmed) {
          await _requestPermission();
        }
      }

      final l = _localizedStrings();
      await _plugin.zonedSchedule(
        id: _trialExpiryNotificationId,
        title: l.trialNotificationTitle,
        body: l.trialNotificationBody,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'trial_expiry',
            'Trial Expiry Reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      if (kDebugMode) {
        debugPrint(
          '🔥 [TrialNotificationService] scheduled for $scheduledAt '
          '(expiresAt=$expiresAt)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 [TrialNotificationService] schedule failed: $e');
      }
    } finally {
      _schedulingInFlight = false;
    }
  }

  /// Cancels any pending trial-expiry reminder. Safe to call even when
  /// nothing is scheduled.
  Future<void> cancelTrialExpiry() async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: _trialExpiryNotificationId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 [TrialNotificationService] cancel failed: $e');
      }
    }
  }

  /// Test utility, kept intentionally (not a "remove before ship" leftover)
  /// — nothing calls this by default, so it's inert unless a caller is
  /// deliberately wired in for a test run. Fires `scheduleTrialExpiryIfNeeded`
  /// twice without awaiting the first, deterministically reproducing the
  /// concurrent-call race `_schedulingInFlight` guards against — no real
  /// subscription/Sandbox trial needed, `expiresAt` is just a placeholder
  /// future date. Before that guard existed this showed two stacked
  /// `TrialNotificationPrimerDialog`s; with it, only one call should get
  /// past the in-flight check (the other logs "scheduling already in
  /// flight, skipping this call"). Call `cancelTrialExpiry()` first if
  /// re-running this in the same session — otherwise the second run's
  /// "already scheduled" dedup check short-circuits before ever reaching
  /// the primer.
  Future<void> debugTriggerConcurrentSchedule() async {
    final fakeExpiresAt = DateTime.now().add(const Duration(days: 3));
    unawaited(scheduleTrialExpiryIfNeeded(fakeExpiresAt));
    unawaited(scheduleTrialExpiryIfNeeded(fakeExpiresAt));
  }
}
