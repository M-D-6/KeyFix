import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../fluent_theme.dart';

class CaptionButtons extends StatefulWidget {
  const CaptionButtons({super.key});

  @override
  State<CaptionButtons> createState() => _CaptionButtonsState();
}

class _CaptionButtonsState extends State<CaptionButtons> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _refresh();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    final bool value = await windowManager.isMaximized();
    if (mounted && value != _maximized) {
      setState(() => _maximized = value);
    }
  }

  @override
  void onWindowMaximize() => _refresh();

  @override
  void onWindowUnmaximize() => _refresh();

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _CaptionButton(
          kind: _Glyph.minimize,
          onPressed: () => windowManager.minimize(),
        ),
        _CaptionButton(
          kind: _maximized ? _Glyph.restore : _Glyph.maximize,
          onPressed: _toggleMaximize,
        ),
        _CaptionButton(
          kind: _Glyph.close,
          isClose: true,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

enum _Glyph { minimize, maximize, restore, close }

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.kind,
    required this.onPressed,
    this.isClose = false,
  });

  final _Glyph kind;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);

    Color fill = Colors.transparent;
    Color glyph = c.textPrimary;

    if (widget.isClose && (_hover || _down)) {
      fill = _down ? const Color(0xFFB32A1C) : const Color(0xFFC42B1C);
      glyph = Colors.white;
    } else if (_down) {
      fill = c.isDark ? const Color(0x12FFFFFF) : const Color(0x0C000000);
    } else if (_hover) {
      fill = c.isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          color: fill,
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(10, 10),
            painter: _GlyphPainter(widget.kind, glyph),
          ),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.kind, this.color);

  final _Glyph kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = kind == _Glyph.close;

    switch (kind) {
      case _Glyph.minimize:
        canvas.drawLine(const Offset(0, 5.5), const Offset(10, 5.5), p);
      case _Glyph.maximize:
        canvas.drawRect(const Rect.fromLTWH(0.5, 0.5, 9, 9), p);
      case _Glyph.restore:
        canvas.drawRect(const Rect.fromLTWH(0.5, 2.5, 7, 7), p);
        final Path back = Path()
          ..moveTo(2.5, 2.5)
          ..lineTo(2.5, 0.5)
          ..lineTo(9.5, 0.5)
          ..lineTo(9.5, 7.5)
          ..lineTo(7.5, 7.5);
        canvas.drawPath(back, p);
      case _Glyph.close:
        canvas.drawLine(Offset.zero, const Offset(10, 10), p);
        canvas.drawLine(const Offset(10, 0), const Offset(0, 10), p);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.kind != kind || old.color != color;
}
