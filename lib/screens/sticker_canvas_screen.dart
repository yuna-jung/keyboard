import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _pink = Color(0xFF5BC8F5);

/// Phase 1 of the sticker feature: a standalone screen where the user draws
/// on a square, transparent-background PencilKit canvas and saves the
/// result as a PNG to the Photos app.
///
/// Deliberately out of scope for this phase (see later work): App Group
/// sharing, a "my stickers" gallery, the keyboard extension side, the flood
/// fill / bucket tool, and any free-tier/paywall gating. This screen only
/// needs to prove out the native PencilKit embed and the save-to-Photos
/// path end to end.
class StickerCanvasScreen extends StatefulWidget {
  const StickerCanvasScreen({super.key});

  @override
  State<StickerCanvasScreen> createState() => _StickerCanvasScreenState();
}

class _StickerCanvasScreenState extends State<StickerCanvasScreen> {
  static const _viewType = 'com.yunajung.fonki/drawing_canvas';

  MethodChannel? _channel;
  bool _isEraser = false;
  int _widthIndex = 1; // 0 = thin, 1 = medium, 2 = thick
  int _colorIndex = 0;
  bool _isSaving = false;

  static const _widthLabels = ['얇게', '중간', '굵게'];

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
    if (_isEraser) {
      await channel.invokeMethod('setEraserTool');
    } else {
      await channel.invokeMethod('setPenTool', {
        'widthIndex': _widthIndex,
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
              for (var i = 0; i < 3; i++) _widthButton(i),
              const SizedBox(width: 8),
              _eraserButton(),
              const Spacer(),
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

  Widget _widthButton(int index) {
    final selected = !_isEraser && _widthIndex == index;
    final dotSize = 6.0 + index * 5.0;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isEraser = false;
            _widthIndex = index;
          });
          _applyCurrentTool();
        },
        child: Tooltip(
          message: _widthLabels[index],
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
    return GestureDetector(
      onTap: () {
        setState(() => _isEraser = true);
        _applyCurrentTool();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isEraser ? _pink.withValues(alpha: 0.15) : Colors.grey.shade100,
          border: Border.all(color: _isEraser ? _pink : Colors.transparent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.auto_fix_normal, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _colorSwatch(int index) {
    final color = _colors[index];
    final selected = !_isEraser && _colorIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEraser = false;
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
