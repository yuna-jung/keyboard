import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// "내 스티커함" — a grid of previously-saved stickers, backed by the App
/// Group sticker library (see `StickerLibrary.swift`). Reads/deletes go
/// through the same `com.yunajung.fonki/appgroup` channel every other App
/// Group interaction in this app already uses; saving itself happens on
/// the drawing canvas's own channel (see `StickerCanvasScreen._save`),
/// since that's where the PNG bytes already are.
///
/// A `GlobalKey<StickerLibraryViewState>` lets the parent screen trigger
/// `reload()` when the user switches into this view — the widget itself
/// stays mounted (via `Offstage`, not conditional creation) so the canvas
/// beneath it never loses its in-progress drawing, which also means
/// `initState` alone isn't enough to catch newly-saved stickers.
class StickerLibraryView extends StatefulWidget {
  const StickerLibraryView({super.key, required this.onCreateNew});

  final VoidCallback onCreateNew;

  @override
  State<StickerLibraryView> createState() => StickerLibraryViewState();
}

class StickerLibraryViewState extends State<StickerLibraryView> {
  static const _channel = MethodChannel('com.yunajung.fonki/appgroup');

  List<_StickerEntry> _stickers = [];
  bool _loading = true;

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

  Future<void> _confirmDelete(_StickerEntry sticker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('스티커 삭제'),
        content: const Text('이 스티커를 삭제할까요?\n이 동작은 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    bool success = false;
    try {
      success = await _channel.invokeMethod<bool>('deleteSticker', {
            'path': sticker.path,
          }) ??
          false;
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    if (success) {
      setState(() => _stickers.removeWhere((s) => s.path == sticker.path));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제하지 못했어요')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stickers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_emotions_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('아직 그린 스티커가 없어요',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
              child: const Text('그리러 가기'),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _stickers.length,
      itemBuilder: (_, i) {
        final sticker = _stickers[i];
        return GestureDetector(
          onTap: () => _confirmDelete(sticker),
          onLongPress: () => _confirmDelete(sticker),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Image.file(File(sticker.path), fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }
}
