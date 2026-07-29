import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';

import '../l10n/app_localizations.dart';

const _pink = Color(0xFF5BC8F5);

class _StickerEntry {
  const _StickerEntry({required this.path, required this.createdAt});

  final String path;
  final double createdAt;

  static _StickerEntry? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final path = raw['path'];
    if (path is! String || path.isEmpty) return null;
    final createdAt = raw['createdAt'];
    return _StickerEntry(
      path: path,
      createdAt: createdAt is num ? createdAt.toDouble() : 0,
    );
  }
}

/// "내 스티커" — a grid of previously-saved stickers, backed by the App
/// Group sticker library (see `StickerLibrary.swift`). Reads/deletes go
/// through the same `com.yunajung.fonki/appgroup` channel every other App
/// Group interaction in this app already uses; saving itself happens on
/// `StickerScreen`'s own channel (see `_StickerScreenState._saveSticker`),
/// since that's where the picked image's PNG bytes already are.
///
/// A `GlobalKey<StickerLibraryViewState>` lets the parent screen trigger
/// `reload()` after a new sticker is saved, so the grid picks it up
/// immediately without needing to be recreated.
///
/// `gridShowcaseKey`/`selectButtonShowcaseKey` exist purely for
/// `StickerScreen`'s onboarding coach-mark tour — this view doesn't know
/// anything about tutorial state itself, it just exposes the two widgets
/// that need to be targetable, always at a stable position in the tree
/// (see `_buildGridArea`/`_buildToolbar`) regardless of whether the
/// library is empty.
class StickerLibraryView extends StatefulWidget {
  const StickerLibraryView({
    super.key,
    required this.onCreateNew,
    required this.gridShowcaseKey,
    required this.selectButtonShowcaseKey,
  });

  final VoidCallback onCreateNew;
  final GlobalKey gridShowcaseKey;
  final GlobalKey selectButtonShowcaseKey;

  @override
  State<StickerLibraryView> createState() => StickerLibraryViewState();
}

class StickerLibraryViewState extends State<StickerLibraryView> {
  static const _channel = MethodChannel('com.yunajung.fonki/appgroup');

  List<_StickerEntry> _stickers = [];
  bool _loading = true;

  // Multi-select delete. Tap still does the original single-item
  // delete-confirm in normal mode (unchanged) — long-press, which
  // previously did the exact same thing as a tap, now enters selection
  // mode with that item pre-selected instead, since a distinct gesture is
  // more useful than a duplicate of tap. A "선택" button offers the same
  // entry point without needing a long-press.
  bool _selectionMode = false;
  final Set<String> _selectedPaths = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    List<_StickerEntry> stickers = [];
    try {
      final raw = await _channel.invokeMethod<List<Object?>>('getStickers');
      stickers = (raw ?? [])
          .map(_StickerEntry.fromMap)
          .whereType<_StickerEntry>()
          .toList();
    } catch (_) {
      // Leave `stickers` empty — the grid falls back to the empty state,
      // which is a reasonable outcome for "couldn't read the library"
      // without needing a separate error UI for this phase.
    }
    if (!mounted) return;
    setState(() {
      _stickers = stickers;
      _loading = false;
    });
  }

  /// The one place that actually calls the native delete — both the
  /// single-item confirm flow and the multi-select batch flow below loop
  /// over this rather than each re-implementing the channel call.
  Future<bool> _deleteOne(String path) async {
    try {
      return await _channel.invokeMethod<bool>('deleteSticker', {
            'path': path,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirmDelete(_StickerEntry sticker) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.stickerDeleteTitle),
        content: Text(l.stickerDeleteConfirmSingle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await _deleteOne(sticker.path);
    if (!mounted) return;
    if (success) {
      setState(() => _stickers.removeWhere((s) => s.path == sticker.path));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.stickerDeleteFailed)));
    }
  }

  void _enterSelectionMode([String? initialPath]) {
    setState(() {
      _selectionMode = true;
      _selectedPaths.clear();
      if (initialPath != null) _selectedPaths.add(initialPath);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedPaths.clear();
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (!_selectedPaths.remove(path)) {
        _selectedPaths.add(path);
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedPaths.isEmpty || _isDeleting) return;
    final l = AppLocalizations.of(context)!;
    final count = _selectedPaths.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.stickerDeleteTitle),
        content: Text(l.stickerDeleteConfirmMultiple(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final targets = _selectedPaths.toList();
    final deletedPaths = <String>{};
    // GIF/PNG are handled identically here — `_deleteOne` (and the native
    // `StickerLibrary.delete(path:)` behind it) matches by file name only,
    // never by extension, so mixed selections work with no extra branching.
    for (final path in targets) {
      if (await _deleteOne(path)) deletedPaths.add(path);
    }

    if (!mounted) return;
    final failedCount = targets.length - deletedPaths.length;
    setState(() {
      _stickers.removeWhere((s) => deletedPaths.contains(s.path));
      _selectionMode = false;
      _selectedPaths.clear();
      _isDeleting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failedCount == 0
              ? l.stickerDeletedAll(deletedPaths.length)
              : l.stickerDeletedPartial(deletedPaths.length, failedCount),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Toolbar and the grid-area are now always both rendered, empty library
    // or not — the coach-mark tour's grid/선택 steps need both to exist in
    // the tree (at a stable position) from the very first tab entry, since
    // the tour no longer waits for the user to add a sticker first.
    return Column(
      children: [
        _buildToolbar(l),
        Expanded(child: _buildGridArea(l)),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_emotions_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            l.stickerEmptyTitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.onCreateNew,
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l.stickerAddImage),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations l) {
    final selectedCount = _selectedPaths.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: _selectionMode
            ? [
                TextButton(
                  onPressed: _isDeleting ? null : _exitSelectionMode,
                  child: Text(l.cancel),
                ),
                const Spacer(),
                Text(
                  l.stickerSelectedCount(selectedCount),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: (selectedCount == 0 || _isDeleting)
                      ? null
                      : _confirmDeleteSelected,
                  child: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l.stickerDeleteWithCount(selectedCount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selectedCount == 0
                                ? Colors.grey
                                : Colors.red,
                          ),
                        ),
                ),
              ]
            : [
                const Spacer(),
                Showcase(
                  key: widget.selectButtonShowcaseKey,
                  description: l.stickerTourSelectDesc,
                  tooltipBackgroundColor: _pink,
                  textColor: Colors.white,
                  targetShapeBorder: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: TextButton(
                    // Always rendered (even with zero stickers) so the tour's
                    // final step always has a real target to point at; just
                    // disabled — Flutter's default TextButton styling grays
                    // it out automatically when `onPressed` is null.
                    onPressed: _stickers.isEmpty
                        ? null
                        : () => _enterSelectionMode(),
                    child: Text(l.stickerSelectButton),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildGridArea(AppLocalizations l) {
    return Showcase(
      key: widget.gridShowcaseKey,
      description: l.stickerTourGridDesc,
      tooltipBackgroundColor: _pink,
      textColor: Colors.white,
      child: _stickers.isEmpty ? _buildEmptyState(l) : _buildGrid(l),
    );
  }

  Widget _buildGrid(AppLocalizations l) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _stickers.length,
      itemBuilder: (_, i) {
        final sticker = _stickers[i];
        final selected = _selectedPaths.contains(sticker.path);
        return GestureDetector(
          onTap: () {
            if (_selectionMode) {
              _toggleSelection(sticker.path);
            } else {
              _confirmDelete(sticker);
            }
          },
          onLongPress: () {
            if (!_selectionMode) _enterSelectionMode(sticker.path);
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(
                      color: selected ? _pink : Colors.grey.shade300,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Image.file(File(sticker.path), fit: BoxFit.contain),
                ),
              ),
              if (_selectionMode)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _SelectionCheckmark(selected: selected),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectionCheckmark extends StatelessWidget {
  const _SelectionCheckmark({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? _pink : Colors.white,
        border: Border.all(
          color: selected ? _pink : Colors.grey.shade400,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
