import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

const _pink = Color(0xFF5BC8F5);

/// Pre-permission "primer" shown before the iOS system notification
/// permission dialog, explaining in our own words why we're about to ask.
///
/// The confirm button does not grant, deny, or toggle anything itself — it
/// only tells the caller the user is ready to see the real iOS prompt next.
/// Dismissing any other way (tap outside the dialog, back gesture) resolves
/// to `false` and leaves the system permission state completely untouched,
/// so the next trial-state re-evaluation can show this primer again rather
/// than treating a stray dismissal as a permanent "don't ask again".
class TrialNotificationPrimerDialog extends StatelessWidget {
  const TrialNotificationPrimerDialog({super.key});

  /// Shows the dialog and returns `true` only if the user tapped the
  /// confirm button.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const TrialNotificationPrimerDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 32,
                color: _pink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.trialPrimerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l.trialPrimerBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l.trialPrimerConfirmButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
