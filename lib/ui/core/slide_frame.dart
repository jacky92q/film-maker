import 'dart:math' as math;

import 'package:film_maker/domain/models/slide.dart';
import 'package:flutter/material.dart';

/// Returns a decorative full-slide border frame widget for [frame], drawn in
/// [color]. Returns `SizedBox.shrink()` for [SlideFrame.none]. The frame is
/// non-interactive and sits above the photo but below the user's own layers.
Widget buildSlideFrame(SlideFrame frame, Color color) {
  if (frame == SlideFrame.none) return const SizedBox.shrink();
  return IgnorePointer(
    child: CustomPaint(
      painter: _SlideFramePainter(frame: frame, color: color),
      child: const SizedBox.expand(),
    ),
  );
}

class _SlideFramePainter extends CustomPainter {
  const _SlideFramePainter({required this.frame, required this.color});

  final SlideFrame frame;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Inset and stroke scale with the canvas so the frame reads the same in
    // editor, preview and export.
    final unit = math.min(w, h);
    final inset = unit * 0.045;
    final stroke = math.max(1.0, unit * 0.004);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    // A soft shadow so light frames stay legible on bright photos.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    switch (frame) {
      case SlideFrame.none:
        break;
      case SlideFrame.thinBorder:
        final r = _inset(size, inset);
        canvas.drawRect(r, shadow);
        canvas.drawRect(r, line);
      case SlideFrame.doubleBorder:
        final outer = _inset(size, inset);
        final innerGap = unit * 0.018;
        final inner = _inset(size, inset + innerGap);
        canvas.drawRect(outer, shadow);
        canvas.drawRect(outer, line);
        final thin = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.6
          ..isAntiAlias = true;
        canvas.drawRect(inner, thin);
      case SlideFrame.cornerBrackets:
        _corners(canvas, size, inset, line, shadow, unit * 0.10);
      case SlideFrame.editorialTicks:
        final r = _inset(size, inset);
        canvas.drawRect(r, shadow);
        canvas.drawRect(r, line);
        _ticks(canvas, r, line, unit * 0.04);
      case SlideFrame.insetLine:
        final r = _inset(size, unit * 0.085);
        final thin = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.8
          ..isAntiAlias = true;
        canvas.drawRect(r, shadow);
        canvas.drawRect(r, thin);
      case SlideFrame.dashedBorder:
        final r = _inset(size, inset);
        _dashedRect(canvas, r, line, unit * 0.022, unit * 0.014);
      case SlideFrame.ornateCorners:
        _corners(canvas, size, inset, line, shadow, unit * 0.10);
        _ornateCornerSwirls(canvas, size, inset, line, unit * 0.08);
    }
  }

  Rect _inset(Size s, double inset) =>
      Rect.fromLTRB(inset, inset, s.width - inset, s.height - inset);

  void _corners(Canvas canvas, Size s, double inset, Paint line, Paint shadow, double len) {
    final r = _inset(s, inset);
    void bracket(Offset corner, double dx, double dy) {
      final path = Path()
        ..moveTo(corner.dx + dx * len, corner.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(corner.dx, corner.dy + dy * len);
      canvas.drawPath(path, shadow);
      canvas.drawPath(path, line);
    }

    bracket(r.topLeft, 1, 1);
    bracket(r.topRight, -1, 1);
    bracket(r.bottomLeft, 1, -1);
    bracket(r.bottomRight, -1, -1);
  }

  void _ticks(Canvas canvas, Rect r, Paint line, double len) {
    // Small marks at the midpoint of each edge — editorial detail.
    canvas.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.top + len), line);
    canvas.drawLine(Offset(r.center.dx, r.bottom), Offset(r.center.dx, r.bottom - len), line);
    canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.left + len, r.center.dy), line);
    canvas.drawLine(Offset(r.right, r.center.dy), Offset(r.right - len, r.center.dy), line);
  }

  void _dashedRect(Canvas canvas, Rect r, Paint line, double dash, double gap) {
    void seg(Offset a, Offset b) {
      final total = (b - a).distance;
      if (total <= 0) return;
      final dir = (b - a) / total;
      double d = 0;
      while (d < total) {
        final start = a + dir * d;
        final end = a + dir * math.min(d + dash, total);
        canvas.drawLine(start, end, line);
        d += dash + gap;
      }
    }

    seg(r.topLeft, r.topRight);
    seg(r.topRight, r.bottomRight);
    seg(r.bottomRight, r.bottomLeft);
    seg(r.bottomLeft, r.topLeft);
  }

  void _ornateCornerSwirls(Canvas canvas, Size s, double inset, Paint line, double size) {
    final r = _inset(s, inset);
    final thin = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = line.strokeWidth * 0.7
      ..isAntiAlias = true;
    void swirl(Offset c, double sx, double sy) {
      final path = Path()
        ..moveTo(c.dx + sx * size, c.dy)
        ..quadraticBezierTo(
            c.dx + sx * size * 0.2, c.dy + sy * size * 0.2,
            c.dx, c.dy + sy * size)
        ..moveTo(c.dx + sx * size * 0.5, c.dy + sy * size * 0.1)
        ..quadraticBezierTo(
            c.dx + sx * size * 0.1, c.dy + sy * size * 0.5,
            c.dx + sx * size * 0.1, c.dy + sy * size * 0.5);
      canvas.drawPath(path, thin);
    }

    swirl(r.topLeft, 1, 1);
    swirl(r.topRight, -1, 1);
    swirl(r.bottomLeft, 1, -1);
    swirl(r.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(_SlideFramePainter old) =>
      old.frame != frame || old.color != color;
}
