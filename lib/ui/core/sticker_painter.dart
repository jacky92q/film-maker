import 'dart:math' as math;

import 'package:film_maker/domain/models/sticker.dart';
import 'package:flutter/material.dart';

/// Renders a [StickerKind] as crisp vector art inside its slot. Used in both
/// the editor canvas and the playback/export canvas so what you see is exactly
/// what gets exported.
class StickerWidget extends StatelessWidget {
  const StickerWidget({
    super.key,
    required this.kind,
    required this.color,
    this.filled = true,
    this.opacity = 1.0,
  });

  final StickerKind kind;
  final Color color;
  final bool filled;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: CustomPaint(
        painter: StickerPainter(kind: kind, color: color, filled: filled),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class StickerPainter extends CustomPainter {
  const StickerPainter({
    required this.kind,
    required this.color,
    required this.filled,
  });

  final StickerKind kind;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Stroke weight scales with the artwork so thin line art stays elegant.
    final stroke = math.max(1.0, math.min(w, h) * 0.045);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (kind) {
      case StickerKind.heart:
        _heart(canvas, w, h, fill, line);
      case StickerKind.doubleHeart:
        _doubleHeart(canvas, w, h, fill, line);
      case StickerKind.rings:
        _rings(canvas, w, h, line, stroke);
      case StickerKind.ribbonBow:
        _ribbonBow(canvas, w, h, fill, line, stroke);
      case StickerKind.ribbonBanner:
        _ribbonBanner(canvas, w, h, fill, line, stroke);
      case StickerKind.oliveBranch:
        _oliveBranch(canvas, w, h, fill, line, stroke);
      case StickerKind.leafSprig:
        _leafSprig(canvas, w, h, fill, line, stroke);
      case StickerKind.wreath:
        _wreath(canvas, w, h, fill, line, stroke);
      case StickerKind.floralRose:
        _rose(canvas, w, h, fill, line, stroke);
      case StickerKind.sparkle:
        _sparkle(canvas, w, h, fill);
      case StickerKind.starOutline:
        _star(canvas, w, h, fill, line);
      case StickerKind.flourish:
        _flourish(canvas, w, h, line, fill, stroke);
      case StickerKind.cornerFlourish:
        _cornerFlourish(canvas, w, h, line, fill, stroke);
      case StickerKind.ovalFrame:
        _ovalFrame(canvas, w, h, line, stroke);
      case StickerKind.crown:
        _crown(canvas, w, h, fill, line, stroke);
      case StickerKind.champagne:
        _champagne(canvas, w, h, fill, line, stroke);
      case StickerKind.dove:
        _dove(canvas, w, h, fill, line);
      case StickerKind.arch:
        _arch(canvas, w, h, line, stroke);
    }
  }

  Paint _pick(Paint fill, Paint line) => filled ? fill : line;

  // ── Heart ──────────────────────────────────────────────────────────────────
  Path _heartPath(double cx, double cy, double w, double h) {
    final path = Path();
    final top = cy - h * 0.30;
    path.moveTo(cx, cy + h * 0.40);
    path.cubicTo(cx - w * 0.60, cy - h * 0.02,
                 cx - w * 0.50, top - h * 0.22, cx, top + h * 0.04);
    path.cubicTo(cx + w * 0.50, top - h * 0.22,
                 cx + w * 0.60, cy - h * 0.02, cx, cy + h * 0.40);
    path.close();
    return path;
  }

  void _heart(Canvas canvas, double w, double h, Paint fill, Paint line) {
    canvas.drawPath(_heartPath(w * 0.5, h * 0.46, w * 0.84, h * 0.84), _pick(fill, line));
  }

  void _doubleHeart(Canvas canvas, double w, double h, Paint fill, Paint line) {
    canvas.drawPath(_heartPath(w * 0.36, h * 0.42, w * 0.46, h * 0.62), _pick(fill, line));
    canvas.drawPath(_heartPath(w * 0.64, h * 0.56, w * 0.52, h * 0.70), _pick(fill, line));
  }

  // ── Rings ──────────────────────────────────────────────────────────────────
  void _rings(Canvas canvas, double w, double h, Paint line, double stroke) {
    final r = h * 0.30;
    final cy = h * 0.56;
    final left = Offset(w * 0.38, cy);
    final right = Offset(w * 0.62, cy);
    line.strokeWidth = stroke * 1.15;
    canvas.drawCircle(left, r, line);
    canvas.drawCircle(right, r, line);
    // A small diamond on the right ring.
    final dx = right.dx;
    final dy = cy - r;
    final d = h * 0.10;
    final diamond = Path()
      ..moveTo(dx, dy - d)
      ..lineTo(dx + d * 0.62, dy)
      ..lineTo(dx, dy + d * 0.72)
      ..lineTo(dx - d * 0.62, dy)
      ..close();
    final fill = Paint()..color = line.color..style = PaintingStyle.fill..isAntiAlias = true;
    canvas.drawPath(diamond, fill);
    canvas.drawLine(Offset(dx - d * 0.62, dy), Offset(dx, dy + d * 0.72), line);
    canvas.drawLine(Offset(dx + d * 0.62, dy), Offset(dx, dy + d * 0.72), line);
  }

  // ── Ribbon bow ───────────────────────────────────────────────────────────────
  void _ribbonBow(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final cx = w * 0.5;
    final cy = h * 0.42;
    final lw = w * 0.30; // loop width
    final lh = h * 0.26; // loop height
    final p = _pick(fill, line);

    // Left loop
    final left = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx - lw * 1.4, cy - lh * 1.5, cx - lw * 1.5, cy + lh * 1.4, cx, cy + lh * 0.2)
      ..close();
    // Right loop (mirror)
    final right = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx + lw * 1.4, cy - lh * 1.5, cx + lw * 1.5, cy + lh * 1.4, cx, cy + lh * 0.2)
      ..close();
    canvas.drawPath(left, p);
    canvas.drawPath(right, p);

    // Tails
    final tail = Path()
      ..moveTo(cx - w * 0.07, cy + lh * 0.3)
      ..lineTo(cx - w * 0.20, h * 0.92)
      ..lineTo(cx - w * 0.07, h * 0.86)
      ..lineTo(cx, cy + lh * 0.5)
      ..lineTo(cx + w * 0.07, h * 0.86)
      ..lineTo(cx + w * 0.20, h * 0.92)
      ..lineTo(cx + w * 0.07, cy + lh * 0.3)
      ..close();
    canvas.drawPath(tail, p);

    // Center knot
    final knot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + lh * 0.18), width: w * 0.14, height: h * 0.20),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(knot, p);
  }

  // ── Ribbon banner ────────────────────────────────────────────────────────────
  void _ribbonBanner(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final top = h * 0.30;
    final bot = h * 0.70;
    final notch = w * 0.06;
    final body = Path()
      ..moveTo(w * 0.08, top)
      ..lineTo(w * 0.92, top)
      ..lineTo(w * 0.92 - notch, (top + bot) / 2)
      ..lineTo(w * 0.92, bot)
      ..lineTo(w * 0.08, bot)
      ..lineTo(w * 0.08 + notch, (top + bot) / 2)
      ..close();
    canvas.drawPath(body, _pick(fill, line));
    if (filled) {
      final edge = Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.7;
      canvas.drawPath(body, edge);
    }
    // Folded ends
    final p = _pick(fill, line);
    final tailL = Path()
      ..moveTo(w * 0.08, top)
      ..lineTo(w * 0.02, top + h * 0.10)
      ..lineTo(w * 0.08 + notch * 0.6, (top + bot) / 2)
      ..close();
    final tailR = Path()
      ..moveTo(w * 0.92, top)
      ..lineTo(w * 0.98, top + h * 0.10)
      ..lineTo(w * 0.92 - notch * 0.6, (top + bot) / 2)
      ..close();
    canvas.drawPath(tailL, p);
    canvas.drawPath(tailR, p);
  }

  // ── Botanical helpers ─────────────────────────────────────────────────────────
  void _leaf(Canvas canvas, Offset base, double len, double width, double angle, Paint p) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width, -len * 0.5, 0, -len)
      ..quadraticBezierTo(-width, -len * 0.5, 0, 0)
      ..close();
    canvas.drawPath(leaf, p);
    canvas.restore();
  }

  void _oliveBranch(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final p = _pick(fill, line);
    final stem = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.8
      ..strokeCap = StrokeCap.round;
    final start = Offset(w * 0.08, h * 0.62);
    final end = Offset(w * 0.92, h * 0.40);
    final ctrl = Offset(w * 0.5, h * 0.30);
    final stemPath = Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    canvas.drawPath(stemPath, stem);
    const n = 6;
    for (int i = 1; i <= n; i++) {
      final t = i / (n + 1);
      final pt = _quad(start, ctrl, end, t);
      final tangent = _quadTangent(start, ctrl, end, t);
      final baseAngle = math.atan2(tangent.dy, tangent.dx);
      final len = h * 0.30;
      final lw = h * 0.10;
      _leaf(canvas, pt, len, lw, baseAngle - math.pi / 2 - 0.5, p);
      _leaf(canvas, pt, len, lw, baseAngle - math.pi / 2 + 0.5 + math.pi, p);
    }
    // Tip leaf
    _leaf(canvas, end, h * 0.26, h * 0.08, -0.4, p);
  }

  void _leafSprig(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final p = _pick(fill, line);
    final stem = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.8
      ..strokeCap = StrokeCap.round;
    final start = Offset(w * 0.5, h * 0.92);
    final end = Offset(w * 0.5, h * 0.12);
    canvas.drawLine(start, end, stem);
    const n = 4;
    for (int i = 1; i <= n; i++) {
      final t = i / (n + 0.5);
      final y = start.dy + (end.dy - start.dy) * t;
      final len = h * 0.30 * (1.0 - t * 0.35);
      _leaf(canvas, Offset(w * 0.5, y), len, len * 0.34, -math.pi / 2 - 0.7, p);
      _leaf(canvas, Offset(w * 0.5, y), len, len * 0.34, -math.pi / 2 + 0.7, p);
    }
    _leaf(canvas, end, h * 0.22, h * 0.07, -math.pi / 2, p);
  }

  void _wreath(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final p = _pick(fill, line);
    final cx = w * 0.5;
    final cy = h * 0.5;
    final r = math.min(w, h) * 0.38;
    final leafLen = r * 0.42;
    final leafW = leafLen * 0.34;
    // Two arcs of leaves, leaving a gap at the very top.
    for (int side = 0; side < 2; side++) {
      const count = 7;
      for (int i = 0; i < count; i++) {
        // Sweep from near-top, down each side, to bottom.
        final frac = i / (count - 1);
        final ang = (side == 0)
            ? (-math.pi / 2 + 0.35) + frac * (math.pi - 0.35)
            : (-math.pi / 2 - 0.35) - frac * (math.pi - 0.35);
        final pt = Offset(cx + r * math.cos(ang), cy + r * math.sin(ang));
        // Leaf points inward-tangentially.
        final leafAngle = ang + math.pi / 2 + (side == 0 ? -0.4 : 0.4);
        _leaf(canvas, pt, leafLen, leafW, leafAngle, p);
      }
    }
  }

  void _rose(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final cx = w * 0.5;
    final cy = h * 0.42;
    final maxR = math.min(w, h) * 0.30;
    final spiral = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.85
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    if (filled) {
      canvas.drawCircle(Offset(cx, cy), maxR, fill);
      final petalLine = Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.6
        ..isAntiAlias = true;
      _spiral(canvas, cx, cy, maxR * 0.92, petalLine);
    } else {
      _spiral(canvas, cx, cy, maxR, spiral);
    }
    // Two leaves at the base.
    final p = _pick(fill, line);
    _leaf(canvas, Offset(cx, cy + maxR * 0.7), h * 0.26, h * 0.09, -math.pi / 2 - 0.8, p);
    _leaf(canvas, Offset(cx, cy + maxR * 0.7), h * 0.26, h * 0.09, -math.pi / 2 + 0.8, p);
  }

  void _spiral(Canvas canvas, double cx, double cy, double maxR, Paint paint) {
    final path = Path();
    const turns = 3.2;
    const steps = 90;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final ang = t * turns * 2 * math.pi;
      final rad = maxR * t;
      final x = cx + rad * math.cos(ang);
      final y = cy + rad * math.sin(ang);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  // ── Sparkle ──────────────────────────────────────────────────────────────────
  void _sparkle(Canvas canvas, double w, double h, Paint fill) {
    void star4(double cx, double cy, double r) {
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final ang = i * math.pi / 4 - math.pi / 2;
        final rad = i.isEven ? r : r * 0.26;
        final x = cx + rad * math.cos(ang);
        final y = cy + rad * math.sin(ang);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, fill);
    }

    star4(w * 0.5, h * 0.46, math.min(w, h) * 0.40);
    star4(w * 0.80, h * 0.78, math.min(w, h) * 0.16);
    star4(w * 0.20, h * 0.80, math.min(w, h) * 0.12);
  }

  void _star(Canvas canvas, double w, double h, Paint fill, Paint line) {
    final cx = w * 0.5;
    final cy = h * 0.52;
    final r = math.min(w, h) * 0.42;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final ang = i * math.pi / 5 - math.pi / 2;
      final rad = i.isEven ? r : r * 0.4;
      final x = cx + rad * math.cos(ang);
      final y = cy + rad * math.sin(ang);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, _pick(fill, line));
  }

  // ── Flourish divider ──────────────────────────────────────────────────────────
  void _flourish(Canvas canvas, double w, double h, Paint line, Paint fill, double stroke) {
    final cy = h * 0.5;
    final thin = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.55
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    // Two tapering lines from center.
    final leftLine = Path()
      ..moveTo(w * 0.42, cy)
      ..quadraticBezierTo(w * 0.22, cy, w * 0.08, cy - h * 0.16)
      ..moveTo(w * 0.42, cy)
      ..quadraticBezierTo(w * 0.20, cy + h * 0.04, w * 0.10, cy + h * 0.16);
    final rightLine = Path()
      ..moveTo(w * 0.58, cy)
      ..quadraticBezierTo(w * 0.78, cy, w * 0.92, cy - h * 0.16)
      ..moveTo(w * 0.58, cy)
      ..quadraticBezierTo(w * 0.80, cy + h * 0.04, w * 0.90, cy + h * 0.16);
    canvas.drawPath(leftLine, thin);
    canvas.drawPath(rightLine, thin);
    // Center diamond.
    final d = h * 0.22;
    final diamond = Path()
      ..moveTo(w * 0.5, cy - d)
      ..lineTo(w * 0.5 + d * 0.5, cy)
      ..lineTo(w * 0.5, cy + d)
      ..lineTo(w * 0.5 - d * 0.5, cy)
      ..close();
    canvas.drawPath(diamond, fill);
    // End dots.
    canvas.drawCircle(Offset(w * 0.08, cy - h * 0.16), stroke * 0.7, fill);
    canvas.drawCircle(Offset(w * 0.92, cy - h * 0.16), stroke * 0.7, fill);
  }

  void _cornerFlourish(Canvas canvas, double w, double h, Paint line, Paint fill, double stroke) {
    final thin = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.7
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    // An L-corner with a swirl, top-left oriented.
    final path = Path()
      ..moveTo(w * 0.92, h * 0.10)
      ..lineTo(w * 0.18, h * 0.10)
      ..quadraticBezierTo(w * 0.10, h * 0.10, w * 0.10, h * 0.18)
      ..lineTo(w * 0.10, h * 0.92);
    canvas.drawPath(path, thin);
    // Inner accent line.
    final inner = Path()
      ..moveTo(w * 0.88, h * 0.20)
      ..lineTo(w * 0.26, h * 0.20)
      ..quadraticBezierTo(w * 0.20, h * 0.20, w * 0.20, h * 0.26)
      ..lineTo(w * 0.20, h * 0.88);
    canvas.drawPath(inner, thin);
    // Swirl at the corner.
    final swirl = Path()
      ..moveTo(w * 0.10, h * 0.18)
      ..quadraticBezierTo(w * 0.30, h * 0.02, w * 0.34, h * 0.16)
      ..quadraticBezierTo(w * 0.36, h * 0.26, w * 0.26, h * 0.22);
    canvas.drawPath(swirl, thin);
    canvas.drawCircle(Offset(w * 0.10, h * 0.10), stroke * 0.8, fill);
  }

  void _ovalFrame(Canvas canvas, double w, double h, Paint line, double stroke) {
    final outer = Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.86, height: h * 0.90);
    final inner = Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.74, height: h * 0.80);
    line.strokeWidth = stroke * 0.9;
    canvas.drawOval(outer, line);
    final thin = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.5
      ..isAntiAlias = true;
    canvas.drawOval(inner, thin);
  }

  void _crown(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final base = h * 0.72;
    final top = h * 0.24;
    final path = Path()
      ..moveTo(w * 0.14, base)
      ..lineTo(w * 0.10, top)
      ..lineTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.5, top - h * 0.04)
      ..lineTo(w * 0.68, h * 0.52)
      ..lineTo(w * 0.90, top)
      ..lineTo(w * 0.86, base)
      ..close();
    canvas.drawPath(path, _pick(fill, line));
    // Jewel dots on the points.
    final dot = Paint()
      ..color = filled ? Colors.white.withValues(alpha: 0.75) : line.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.10, top), stroke * 0.9, dot);
    canvas.drawCircle(Offset(w * 0.5, top - h * 0.04), stroke * 1.0, dot);
    canvas.drawCircle(Offset(w * 0.90, top), stroke * 0.9, dot);
    // Base band.
    final band = Rect.fromLTRB(w * 0.12, base - h * 0.02, w * 0.88, base + h * 0.04);
    canvas.drawRect(band, _pick(fill, line));
  }

  void _champagne(Canvas canvas, double w, double h, Paint fill, Paint line, double stroke) {
    final glass = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    void flute(double topCx, double topY, double tilt) {
      canvas.save();
      canvas.translate(topCx, topY);
      canvas.rotate(tilt);
      final bowlW = w * 0.16;
      final bowlH = h * 0.22;
      // Bowl (V-ish cup).
      final bowl = Path()
        ..moveTo(-bowlW, 0)
        ..quadraticBezierTo(-bowlW * 0.7, bowlH, 0, bowlH)
        ..quadraticBezierTo(bowlW * 0.7, bowlH, bowlW, 0)
        ..close();
      canvas.drawPath(bowl, glass);
      // Stem + base.
      canvas.drawLine(Offset(0, bowlH), Offset(0, bowlH + h * 0.30), glass);
      canvas.drawLine(Offset(-bowlW * 0.7, bowlH + h * 0.30), Offset(bowlW * 0.7, bowlH + h * 0.30), glass);
      canvas.restore();
    }

    flute(w * 0.40, h * 0.18, 0.28);
    flute(w * 0.60, h * 0.18, -0.28);
    // Bubbles.
    final bub = Paint()..color = line.color..style = PaintingStyle.fill..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.5, h * 0.10), stroke * 0.5, bub);
    canvas.drawCircle(Offset(w * 0.58, h * 0.05), stroke * 0.4, bub);
    canvas.drawCircle(Offset(w * 0.42, h * 0.06), stroke * 0.35, bub);
  }

  void _dove(Canvas canvas, double w, double h, Paint fill, Paint line) {
    final p = _pick(fill, line);
    // Body + head.
    final body = Path()
      ..moveTo(w * 0.18, h * 0.62)
      ..quadraticBezierTo(w * 0.40, h * 0.40, w * 0.66, h * 0.46)
      ..quadraticBezierTo(w * 0.78, h * 0.48, w * 0.88, h * 0.40)
      ..quadraticBezierTo(w * 0.84, h * 0.52, w * 0.74, h * 0.56)
      ..quadraticBezierTo(w * 0.52, h * 0.66, w * 0.34, h * 0.74)
      ..quadraticBezierTo(w * 0.24, h * 0.78, w * 0.18, h * 0.62)
      ..close();
    canvas.drawPath(body, p);
    // Upper wing.
    final wing = Path()
      ..moveTo(w * 0.40, h * 0.52)
      ..quadraticBezierTo(w * 0.46, h * 0.22, w * 0.66, h * 0.20)
      ..quadraticBezierTo(w * 0.52, h * 0.36, w * 0.56, h * 0.54)
      ..close();
    canvas.drawPath(wing, p);
    // Eye.
    if (filled) {
      final eye = Paint()..color = Colors.white.withValues(alpha: 0.85)..isAntiAlias = true;
      canvas.drawCircle(Offset(w * 0.80, h * 0.45), math.min(w, h) * 0.02, eye);
    }
  }

  void _arch(Canvas canvas, double w, double h, Paint line, double stroke) {
    line.strokeWidth = stroke * 0.8;
    final left = w * 0.14;
    final right = w * 0.86;
    final bottom = h * 0.92;
    final shoulder = h * 0.34;
    final path = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, shoulder)
      ..quadraticBezierTo(left, h * 0.10, w * 0.5, h * 0.10)
      ..quadraticBezierTo(right, h * 0.10, right, shoulder)
      ..lineTo(right, bottom);
    canvas.drawPath(path, line);
    // Inner thin line.
    final inset = w * 0.05;
    final thin = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.45
      ..isAntiAlias = true;
    final inner = Path()
      ..moveTo(left + inset, bottom)
      ..lineTo(left + inset, shoulder + inset * 0.4)
      ..quadraticBezierTo(left + inset, h * 0.10 + inset, w * 0.5, h * 0.10 + inset)
      ..quadraticBezierTo(right - inset, h * 0.10 + inset, right - inset, shoulder + inset * 0.4)
      ..lineTo(right - inset, bottom);
    canvas.drawPath(inner, thin);
  }

  // ── Quadratic bezier helpers ───────────────────────────────────────────────────
  Offset _quad(Offset a, Offset c, Offset b, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * a.dx + 2 * mt * t * c.dx + t * t * b.dx,
      mt * mt * a.dy + 2 * mt * t * c.dy + t * t * b.dy,
    );
  }

  Offset _quadTangent(Offset a, Offset c, Offset b, double t) {
    final mt = 1 - t;
    return Offset(
      2 * mt * (c.dx - a.dx) + 2 * t * (b.dx - c.dx),
      2 * mt * (c.dy - a.dy) + 2 * t * (b.dy - c.dy),
    );
  }

  @override
  bool shouldRepaint(StickerPainter old) =>
      old.kind != kind || old.color != color || old.filled != filled;
}
