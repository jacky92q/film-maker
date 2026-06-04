import 'dart:math' as math;
import 'package:film_maker/domain/models/slide.dart';
import 'package:flutter/material.dart';

/// Returns a dim/gradient overlay widget driven by the slide's dimDirection
/// and dimOpacity. Returns SizedBox.shrink() when dimDirection is none.
Widget buildSlideDim(DimDirection direction, double opacity) {
  if (direction == DimDirection.none || opacity == 0) {
    return const SizedBox.shrink();
  }
  final dark = Colors.black.withValues(alpha: opacity.clamp(0.0, 1.0));
  final clear = Colors.transparent;

  if (direction == DimDirection.radial) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [clear, dark],
            stops: const [0.4, 1.0],
          ),
        ),
      ),
    );
  }

  final (begin, end) = switch (direction) {
    DimDirection.bottom => (Alignment.topCenter,    Alignment.bottomCenter),
    DimDirection.top    => (Alignment.bottomCenter, Alignment.topCenter),
    DimDirection.left   => (Alignment.centerRight,  Alignment.centerLeft),
    DimDirection.right  => (Alignment.centerLeft,   Alignment.centerRight),
    _                   => (Alignment.topCenter,    Alignment.bottomCenter),
  };

  return IgnorePointer(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [clear, dark],
          stops: const [0.35, 1.0],
        ),
      ),
    ),
  );
}

/// Returns an IgnorePointer overlay widget for the given [overlay] type,
/// or an empty SizedBox for [SlideOverlay.none].
Widget buildSlideOverlay(SlideOverlay overlay) {
  switch (overlay) {
    case SlideOverlay.none:
      return const SizedBox.shrink();
    case SlideOverlay.vignette:
      return IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [Colors.transparent, Color(0xBB000000)],
              stops: [0.45, 1.0],
            ),
          ),
        ),
      );
    case SlideOverlay.filmGrain:
      return IgnorePointer(
        child: CustomPaint(
          painter: GrainPainter(seed: 7),
          child: const SizedBox.expand(),
        ),
      );
    case SlideOverlay.lightLeak:
      return IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x00FF8C00),
                Color(0x55FF8C00),
                Color(0x33FF4500),
                Color(0x00FF4500),
              ],
              stops: [0.0, 0.35, 0.6, 1.0],
            ),
          ),
        ),
      );
    case SlideOverlay.bokeh:
      return IgnorePointer(
        child: CustomPaint(
          painter: BokehPainter(),
          child: const SizedBox.expand(),
        ),
      );
  }
}

class GrainPainter extends CustomPainter {
  const GrainPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint();
    final count = (size.width * size.height / 350).round().clamp(0, 4000);
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final opacity = rng.nextDouble() * 0.22;
      paint.color = rng.nextBool()
          ? Colors.white.withValues(alpha: opacity)
          : Colors.black.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(GrainPainter old) => old.seed != seed;
}

class BokehPainter extends CustomPainter {
  const BokehPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    const colors = [
      Color(0x30FFFFFF),
      Color(0x28FFD700),
      Color(0x25FFA0B0),
      Color(0x22A0C0FF),
    ];
    for (int i = 0; i < 14; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 12.0 + rng.nextDouble() * 32.0;
      paint.color = colors[i % colors.length];
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(BokehPainter _) => false;
}
