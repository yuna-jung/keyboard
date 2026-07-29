import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../l10n/app_localizations.dart';
import 'sticker_library_view.dart';

const _pink = Color(0xFF5BC8F5);

/// Lets the user pick one or many photos/GIFs and saves them as stickers in
/// the App Group sticker library, and browse previously-saved stickers.
/// Static images are center-cropped to a square PNG; GIFs are saved as
/// their original animated bytes, uncropped (see StickerImagePicker.swift).
/// Picking a single item shows a save/cancel preview first; picking
/// multiple saves all of them immediately with no per-item confirmation,
/// then reports how many succeeded/failed. The library grid is the default
/// view; adding stickers is a single "+" action, not a separate tab —
/// there's no drawing surface here, just "pick image(s) → save".
///
/// Also owns a single 3-step spotlight onboarding tour (via `showcaseview`):
/// "+" button → grid area → "선택" button. It fires in full the first time
/// the tab is entered, regardless of whether the library has any stickers
/// yet — the grid area and "선택" button are always present in
/// `StickerLibraryView` now (showing an empty-state placeholder / a
/// disabled button respectively when there's nothing saved yet, see
/// `StickerLibraryViewState._buildGridArea`/`_buildToolbar`), specifically
/// so the tour never has to wait on the user actually adding a sticker.
/// Tracked with a single SharedPreferences flag so it only auto-plays once;
/// the "?" button replays the same 3 steps regardless of that flag. The
/// keyboard extension's own sticker tab isn't covered — it's a separate
/// process this overlay approach can't reach into.
///
/// `isActive` must reflect whether this tab is the one actually on screen.
/// `HomeScreen` keeps every tab mounted via `IndexedStack` (so scroll
/// position/state survives tab switches), which means this widget's own
/// `initState` runs once at app launch regardless of which tab the user
/// is looking at — auto-starting a tour straight from `initState` would
/// show the spotlight over whatever tab happens to be selected by default,
/// not this one. `isActive` is how the tour logic knows to wait.
class StickerScreen extends StatefulWidget {
  const StickerScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen> {
  static const _channel = MethodChannel('com.yunajung.fonki/sticker_image');
  static const _tourShownPrefKey = 'sticker_tour_shown';

  final _libraryKey = GlobalKey<StickerLibraryViewState>();
  final _addButtonKey = GlobalKey();
  final _gridKey = GlobalKey();
  final _selectButtonKey = GlobalKey();

  bool _isPicking = false;
  bool _tourShown = true; // optimistic default until prefs load, so the
  bool _tourQueued = false; // tour never flashes on for a returning user

  List<GlobalKey> get _tourKeys => [_addButtonKey, _gridKey, _selectButtonKey];

  @override
  void initState() {
    super.initState();
    // `onFinish` fires once the whole 3-step sequence completes naturally
    // (the user tapped through every step) — that's the point at which the
    // tour counts as "seen" and should stop auto-playing.
    ShowcaseView.register(onFinish: _markTourShown);
    _loadTourFlag();
  }

  @override
  void didUpdateWidget(covariant StickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fires when the bottom nav switches TO this tab (IndexedStack keeps
    // this State alive across switches, so this is the only reliable signal
    // that the user just started looking at it).
    if (widget.isActive && !oldWidget.isActive) {
      _maybeStartTour();
    }
  }

  Future<void> _loadTourFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _tourShown = prefs.getBool(_tourShownPrefKey) ?? false);
    _maybeStartTour();
  }

  /// A no-op unless the tab is actually the one on screen, the tour hasn't
  /// run yet, and nothing has already queued it.
  void _maybeStartTour() {
    if (!widget.isActive || _tourShown || _tourQueued) return;
    _tourQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tourQueued = false;
      if (mounted && widget.isActive) {
        ShowcaseView.get().startShowCase(_tourKeys);
      }
    });
  }

  Future<void> _markTourShown() async {
    if (_tourShown) return;
    setState(() => _tourShown = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourShownPrefKey, true);
  }

  /// The "?" replay button — bypasses the shown-once flag entirely rather
  /// than resetting it, so replaying doesn't also make the tour pop up
  /// again unprompted on some future launch.
  void _replayTutorial() {
    ShowcaseView.get().startShowCase(_tourKeys);
  }

  /// Presents the native photo picker. The native side reports back one of
  /// two shapes depending on how many items the user picked:
  ///   - Single pick: `{"kind": "single", "type": "png"|"gif", "data": <bytes>}`
  ///     — shows a preview with a save/cancel choice, same as before
  ///     multi-select existed.
  ///   - Multi pick: `{"kind": "batch", "saved": <int>, "failed": <int>}`
  ///     — every item has *already* been processed and saved natively (no
  ///     per-item confirmation step), so this just reports the outcome.
  /// A `null` result means the user cancelled the picker, not an error, so
  /// it's handled silently.
  ///
  /// Static images are already center-cropped to a square by the time they
  /// get here; GIFs are the original file's bytes untouched (no cropping —
  /// out of scope for this pass, see StickerImagePicker.swift) but
  /// `Image.memory` animates either way with no extra code, so the only
  /// thing that actually needs to track "is this a GIF" on the single-pick
  /// path is the save call, which has to tell the native side which file
  /// extension to use.
  Future<void> _pickImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'pickImage',
      );
      if (!mounted || result == null) return;

      if (result['kind'] == 'batch') {
        final saved = result['saved'] as int? ?? 0;
        final failed = result['failed'] as int? ?? 0;
        _showBatchResult(saved: saved, failed: failed);
        if (saved > 0) _libraryKey.currentState?.reload();
        return;
      }

      final type = result['type'] as String?;
      final data = result['data'] as Uint8List?;
      if (type == null || data == null) return;
      await _showSavePreview(data, isGif: type == 'gif');
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnack(
        AppLocalizations.of(context)!.stickerPickFailed(e.message ?? e.code),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _showBatchResult({required int saved, required int failed}) {
    final l = AppLocalizations.of(context)!;
    if (failed == 0) {
      _showSnack(l.stickerBatchSavedAll(saved));
    } else if (saved == 0) {
      _showSnack(l.stickerBatchFailedAll(failed));
    } else {
      _showSnack(l.stickerBatchPartial(saved, failed));
    }
  }

  Future<void> _showSavePreview(Uint8List data, {required bool isGif}) async {
    final save = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => _SavePreviewSheet(data: data),
    );
    if (save != true || !mounted) return;
    await _saveSticker(data, isGif: isGif);
  }

  Future<void> _saveSticker(Uint8List data, {required bool isGif}) async {
    try {
      await _channel.invokeMethod('saveImageToPhotoLibrary', {
        'data': data,
        'type': isGif ? 'gif' : 'png',
      });
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.stickerSaved);
      _libraryKey.currentState?.reload();
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnack(
        AppLocalizations.of(context)!.stickerSaveFailed(e.message ?? e.code),
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // No own Scaffold/AppBar — this is embedded directly as a HomeScreen
    // bottom-nav tab body (same pattern as GuideScreen), so HomeScreen's
    // single outer AppBar (Fonkii logo + toolbar icons) is the only one
    // shown. The header row below is plain body content, not a real AppBar.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              // Same text as the bottom-nav tab label for this screen
              // (`homeTabStickerMaker`) — reused rather than duplicated.
              Text(
                l.homeTabStickerMaker,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  color: Colors.grey,
                  size: 22,
                ),
                onPressed: _replayTutorial,
                tooltip: l.stickerHelpTooltip,
              ),
              Showcase(
                key: _addButtonKey,
                description: l.stickerTourAddDesc,
                tooltipBackgroundColor: _pink,
                textColor: Colors.white,
                targetShapeBorder: const CircleBorder(),
                child: IconButton(
                  icon: _isPicking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle, color: _pink, size: 28),
                  onPressed: _isPicking ? null : _pickImage,
                  tooltip: l.stickerAddImage,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StickerLibraryView(
            key: _libraryKey,
            onCreateNew: _pickImage,
            gridShowcaseKey: _gridKey,
            selectButtonShowcaseKey: _selectButtonKey,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet shown right after a successful pick — a checkerboard
/// preview of the picked image or GIF (so transparency, if any, is
/// visible; GIFs animate automatically) plus save/cancel. Kept in this file
/// since it only exists to bridge `_pickImage` and `_saveSticker`.
class _SavePreviewSheet extends StatelessWidget {
  const _SavePreviewSheet({required this.data});
  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: _CheckerboardBackground(
                  child: Image.memory(data, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l.stickerSaveButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple checkerboard so a transparent PNG doesn't just look like an empty
/// white box in the preview.
class _CheckerboardBackground extends StatelessWidget {
  const _CheckerboardBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _CheckerboardPainter()),
        child,
      ],
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  static const _cell = 12.0;
  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFF3F4F6);
    final dark = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0.0; y < size.height; y += _cell) {
      for (var x = 0.0; x < size.width; x += _cell) {
        final isDark = ((x / _cell).floor() + (y / _cell).floor()) % 2 == 0;
        if (isDark) {
          canvas.drawRect(Rect.fromLTWH(x, y, _cell, _cell), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
