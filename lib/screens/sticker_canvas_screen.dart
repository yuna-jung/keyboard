import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _pink = Color(0xFF5BC8F5);

enum _Tool { pen, eraser, bucket }

/// A screen where the user draws on a square, transparent-background
/// PencilKit canvas — with a bucket (flood fill) tool and photo import as
/// a drawable background layer — and saves the result as a PNG to the
/// Photos app.
///
/// Deliberately out of scope so far (see later work): App Group sharing, a
/// "my stickers" gallery, the keyboard extension side, and any
/// free-tier/paywall gating.
class StickerCanvasScreen extends StatefulWidget {
  const StickerCanvasScreen({super.key});

  @override
  State<StickerCanvasScreen> createState() => _StickerCanvasScreenState();
}

class _StickerCanvasScreenState extends State<StickerCanvasScreen> {
  static const _viewType = 'com.yunajung.fonki/drawing_canvas';

  MethodChannel? _channel;
  _Tool _tool = _Tool.pen;
  // Pen and eraser each remember their own last-picked size — switching
  // tools no longer clobbers the other's choice.
  int _penWidthIndex = 1; // 0 = thin, 1 = medium, 2 = thick
  int _eraserWidthIndex = 2; // middle of 5 — see `_eraserWidthLabels`
  int _colorIndex = 0;
  bool _isSaving = false;
  bool _isImporting = false;

  static const _widthLabels = ['얇게', '중간', '굵게'];
  // Eraser gets its own, wider size range — erasing typically needs to
  // cover more area than a single pen stroke, so the top end (40pt) sits
  // well above the pen's thickest (16pt) rather than just reusing it.
  static const _eraserWidthLabels = ['아주 얇게', '얇게', '중간', '굵게', '아주 굵게'];

  // Hardcoded swatches — a custom color picker is out of scope for this
  // phase.
  static const _colors = <Color>[
    Color(0xFF000000), // black
    Color(0xFFFFFFFF), // white
    Color(0xFFEF4444), // red
    Color(0xFFF97316), // orange
    Color(0xFFFACC15), // yellow
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFA855F7), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF78350F), // brown
  ];

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('${_viewType}_$id');
    _channel = channel;
    _applyCurrentTool();
  }

  String _hexOf(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  Future<void> _applyCurrentTool() async {
    final channel = _channel;
    if (channel == null) return;
    switch (_tool) {
      case _Tool.pen:
        await channel.invokeMethod('setPenTool', {
          'widthIndex': _penWidthIndex,
          'colorHex': _hexOf(_colors[_colorIndex]),
        });
      case _Tool.eraser:
        await channel.invokeMethod('setEraserTool', {
          'widthIndex': _eraserWidthIndex,
        });
      case _Tool.bucket:
        await channel.invokeMethod('setBucketTool', {
          'colorHex': _hexOf(_colors[_colorIndex]),
        });
    }
  }

  Future<void> _undo() async {
    await _channel?.invokeMethod('undo');
  }

  Future<void> _redo() async {
    await _channel?.invokeMethod('redo');
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 지우기'),
        content: const Text('지금까지 그린 내용을 전부 지울까요?\n이 동작은 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('지우기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _channel?.invokeMethod('clear');
    }
  }

  Future<void> _save() async {
    final channel = _channel;
    if (channel == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final pngData = await channel.invokeMethod<Uint8List>('renderPNG');
      if (pngData == null) {
        _showSnack('저장할 그림이 없어요');
        return;
      }
      await channel.invokeMethod('saveImageToPhotoLibrary', {
        'pngData': pngData,
      });
      if (!mounted) return;
      _showSnack('사진 앱에 저장했어요');
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnack('저장에 실패했어요: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Presents the native photo picker, center-crops the selection to the
  /// canvas's own square size, and sets it as the drawable background layer
  /// (native side — see `DrawingCanvasPlatformView.centerCroppedSquare`).
  /// A `false` result means the user cancelled the picker, not an error, so
  /// it's handled silently.
  Future<void> _pickImage() async {
    final channel = _channel;
    if (channel == null || _isImporting) return;
    setState(() => _isImporting = true);
    try {
      final imported = await channel.invokeMethod<bool>('pickAndSetBackgroundImage');
      if (!mounted || imported != true) return;
      _showSnack('이미지를 가져왔어요');
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnack('이미지를 가져오지 못했어요: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // No own Scaffold/AppBar — this is embedded directly as a HomeScreen
    // bottom-nav tab body (same pattern as GuideScreen), so HomeScreen's
    // single outer AppBar (Fonkii logo + toolbar icons) is the only one
    // shown. The header row below is plain body content, not a real AppBar.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              const Text('이모티콘 생성',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
              const Spacer(),
              TextButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('저장',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _pink)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _CheckerboardBackground(
                  child: UiKitView(
                    viewType: _viewType,
                    onPlatformViewCreated: _onPlatformViewCreated,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(top: false, child: _buildToolbar()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < (_tool == _Tool.eraser ? _eraserWidthLabels.length : _widthLabels.length); i++)
                _widthButton(i),
              const SizedBox(width: 8),
              _eraserButton(),
              const SizedBox(width: 8),
              _bucketButton(),
              const Spacer(),
              IconButton(
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                onPressed: _isImporting ? null : _pickImage,
                tooltip: '이미지 가져오기',
              ),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _undo,
                tooltip: '실행취소',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: _redo,
                tooltip: '다시하기',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmClear,
                tooltip: '전체 지우기',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _colorSwatch(i),
            ),
          ),
        ],
      ),
    );
  }

  // Shown for both pen and eraser, but each tool keeps its own size index
  // (`_penWidthIndex` / `_eraserWidthIndex`) and its own size list — the
  // eraser's is longer and runs larger (see `_eraserWidthLabels`). A width
  // tap only forces a tool switch when coming from bucket (which has no
  // width concept); it never switches between pen and eraser.
  Widget _widthButton(int index) {
    final isEraserMode = _tool == _Tool.eraser;
    final currentIndex = isEraserMode ? _eraserWidthIndex : _penWidthIndex;
    final selected = _tool != _Tool.bucket && currentIndex == index;
    final dotSize = 6.0 + index * 5.0;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_tool == _Tool.bucket) _tool = _Tool.pen;
            if (_tool == _Tool.eraser) {
              _eraserWidthIndex = index;
            } else {
              _penWidthIndex = index;
            }
          });
          _applyCurrentTool();
        },
        child: Tooltip(
          message: isEraserMode ? _eraserWidthLabels[index] : _widthLabels[index],
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _pink.withValues(alpha: 0.15) : Colors.grey.shade100,
              border: Border.all(color: selected ? _pink : Colors.transparent, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eraserButton() {
    final selected = _tool == _Tool.eraser;
    return GestureDetector(
      onTap: () {
        setState(() => _tool = _Tool.eraser);
        _applyCurrentTool();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? _pink.withValues(alpha: 0.15) : Colors.grey.shade100,
          border: Border.all(color: selected ? _pink : Colors.transparent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.auto_fix_normal, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _bucketButton() {
    final selected = _tool == _Tool.bucket;
    return GestureDetector(
      onTap: () {
        setState(() => _tool = _Tool.bucket);
        _applyCurrentTool();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? _pink.withValues(alpha: 0.15) : Colors.grey.shade100,
          border: Border.all(color: selected ? _pink : Colors.transparent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.format_color_fill, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _colorSwatch(int index) {
    final color = _colors[index];
    final selected = _tool != _Tool.eraser && _colorIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_tool == _Tool.eraser) _tool = _Tool.pen;
          _colorIndex = index;
        });
        _applyCurrentTool();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? _pink : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

/// Simple checkerboard so a transparent canvas doesn't just look like an
/// empty white box while drawing.
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
