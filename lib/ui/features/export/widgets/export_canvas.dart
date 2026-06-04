import 'dart:math' as math;

import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/photo_frame_widget.dart';
import 'package:film_maker/ui/core/slide_overlay.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:flutter/material.dart';

/// Renders a single slide at an explicit [slideTimeSeconds] offset.
/// All animation values are derived mathematically — no AnimationControllers.
/// Used for frame-by-frame video export.
class ExportCanvas extends StatelessWidget {
  const ExportCanvas({
    super.key,
    required this.slide,
    required this.slideTimeSeconds,
  });

  final Slide slide;
  final double slideTimeSeconds;

  static const double kWidth = 1280.0;
  static const double kHeight = 720.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kWidth,
      height: kHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          buildSlideDim(slide.dimDirection, slide.dimOpacity),
          buildSlideOverlay(slide.overlay),
          ..._buildLayers(),
        ],
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    if (slide.imagePath == null && slide.layout == SlideLayout.single) {
      return ColoredBox(color: Color(slide.backgroundColor));
    }
    if (slide.layout != SlideLayout.single) return _buildStrip();
    return _buildSinglePhoto();
  }

  Widget _buildSinglePhoto() {
    final photo = buildShapedPhoto(
      imagePath: slide.imagePath,
      shape: slide.photoShape,
      frame: slide.photoFrame,
      fit: BoxFit.contain,
      colorFilter: slide.photoFilter.colorFilter,
    );

    final base = ColoredBox(
      color: Color(slide.backgroundColor),
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(slide.photoOffsetX * kWidth, slide.photoOffsetY * kHeight),
          child: Transform.scale(scale: slide.photoScale, child: photo),
        ),
      ),
    );

    if (slide.transition != TransitionEffect.kenBurns) return base;

    final dur = slide.durationSeconds.toDouble();
    final kenT = (slideTimeSeconds / dur).clamp(0.0, 1.0);
    final scale = 1.0 + 0.08 * kenT;
    final dx = 0.03 * (kenT - 0.5) * 200;
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Transform.translate(offset: Offset(dx, 0), child: base),
    );
  }

  Widget _buildStrip() {
    final photos = [slide.imagePath, slide.imagePath2];
    if (slide.layout == SlideLayout.strip3) photos.add(slide.imagePath3);
    final n = photos.length;
    final dur = slide.durationSeconds.toDouble();
    final stripT = (slideTimeSeconds / dur).clamp(0.0, 1.0);
    final offset = stripT * (n - 1) * kWidth;

    return ClipRect(
      child: Transform.translate(
        offset: Offset(-offset, 0),
        child: Row(
          children: photos
              .map((path) => SizedBox(
                    width: kWidth,
                    height: kHeight,
                    child: buildShapedPhoto(
                      imagePath: path,
                      shape: slide.photoShape,
                      frame: slide.photoFrame,
                      fit: BoxFit.cover,
                      colorFilter: slide.photoFilter.colorFilter,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Layers ──────────────────────────────────────────────────────────────────

  List<Widget> _buildLayers() {
    final items = <({int z, bool isText, Object layer})>[];
    for (final l in slide.textLayers) {
      items.add((z: l.zOrder, isText: true, layer: l));
    }
    for (final p in slide.photoLayers) {
      items.add((z: p.zOrder, isText: false, layer: p));
    }
    items.sort((a, b) => a.z.compareTo(b.z));
    return [
      for (final item in items)
        if (item.isText)
          _buildTextLayer(item.layer as TextLayer)
        else
          _buildPhotoLayer(item.layer as PhotoLayer),
    ];
  }

  // ── Animation helpers ────────────────────────────────────────────────────────

  static double _animDurSec(SlideContentAnimation a) => switch (a) {
        SlideContentAnimation.none => 0.1,
        SlideContentAnimation.typewriter => 2.8,
        SlideContentAnimation.slideUp || SlideContentAnimation.slideIn => 1.2,
        SlideContentAnimation.fadeStagger => 2.0,
        SlideContentAnimation.float => 2.2,
        SlideContentAnimation.zoomPulse => 3.0,
        SlideContentAnimation.wipeReveal => 2.2,
      };

  /// Returns animation progress ∈ [0, 1] at [t] seconds.
  /// Looping animations (float, zoomPulse) oscillate like repeat(reverse:true).
  double _animT(SlideContentAnimation a) {
    final dur = _animDurSec(a);
    if (dur <= 0) return 1.0;
    switch (a) {
      case SlideContentAnimation.float:
      case SlideContentAnimation.zoomPulse:
        final cycles = slideTimeSeconds / dur;
        final phase = cycles - cycles.floor();
        return (cycles.floor() % 2 == 0) ? phase : 1.0 - phase;
      default:
        return (slideTimeSeconds / dur).clamp(0.0, 1.0);
    }
  }

  // ── Text layer ───────────────────────────────────────────────────────────────

  Widget _buildTextLayer(TextLayer layer) {
    final anim = layer.contentAnimation;
    final t = _animT(anim);
    final align = Alignment(
      (layer.x * 2 - 1).clamp(-0.95, 0.95),
      (layer.y * 2 - 1).clamp(-0.95, 0.92),
    );

    final text = _layerText(layer);

    switch (anim) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.zoomPulse:
        return Positioned.fill(child: Align(alignment: align, child: text));

      case SlideContentAnimation.typewriter:
        final n = (layer.text.length * t).round().clamp(0, layer.text.length);
        return Positioned.fill(
          child: Opacity(
            opacity: t > 0 ? 1.0 : 0.0,
            child: Align(
              alignment: align,
              child: _layerText(layer, text: layer.text.substring(0, n)),
            ),
          ),
        );

      case SlideContentAnimation.slideUp:
        final e = Curves.easeOutCubic.transform(t);
        return Positioned.fill(
          child: Opacity(
            opacity: e,
            child: Transform.translate(
              offset: Offset(0, 100 * (1 - e)),
              child: Align(alignment: align, child: text),
            ),
          ),
        );

      case SlideContentAnimation.slideIn:
        final e = Curves.easeOutCubic.transform(t);
        return Positioned.fill(
          child: Opacity(
            opacity: e,
            child: Transform.translate(
              offset: Offset(-200 * (1 - e), 0),
              child: Align(alignment: align, child: text),
            ),
          ),
        );

      case SlideContentAnimation.fadeStagger:
        return Positioned.fill(
          child: Opacity(opacity: t, child: Align(alignment: align, child: text)),
        );

      case SlideContentAnimation.float:
        final e = Curves.easeInOut.transform(t);
        return Positioned.fill(
          child: Align(
            alignment: align,
            child: Transform.translate(offset: Offset(0, -16 * e + 8), child: text),
          ),
        );

      case SlideContentAnimation.wipeReveal:
        final e = Curves.easeOut.transform(t);
        return Positioned.fill(
          child: Align(
            alignment: align,
            child: ClipRect(clipper: _WipeClipper(e), child: text),
          ),
        );
    }
  }

  Widget _layerText(TextLayer layer, {String? text}) {
    final displayText = text ?? layer.text;
    final style = slideLayerTextStyle(
      layer.fontStyle,
      fontSize: layer.fontSize,
      color: layer.color.color,
      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 12)],
    );
    Widget content = Text(displayText, style: style, textAlign: TextAlign.center);
    if (layer.isSubtitle) {
      content = IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: layer.barColor.color, width: 2.5)),
          ),
          child: content,
        ),
      );
    }
    return Transform.rotate(angle: layer.rotation * math.pi / 180.0, child: content);
  }

  // ── Photo layer ──────────────────────────────────────────────────────────────

  Widget _buildPhotoLayer(PhotoLayer pl) {
    const w = kWidth, h = kHeight;
    final left = (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * w;
    final top = (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * h;
    final pw = pl.widthFraction * w;
    final ph = pl.heightFraction * h;

    final anim = pl.contentAnimation;
    final t = _animT(anim);

    final photo = Transform.rotate(
      angle: pl.rotation * math.pi / 180.0,
      child: buildShapedPhoto(
        imagePath: pl.imagePath,
        shape: pl.shape,
        frame: pl.frame,
        fit: BoxFit.cover,
        colorFilter: pl.filter.colorFilter,
        frameWidth: pl.frameWidth,
        cropScale: pl.cropScale,
        cropOffsetX: pl.cropOffsetX,
        cropOffsetY: pl.cropOffsetY,
      ),
    );

    switch (anim) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.typewriter:
      case SlideContentAnimation.wipeReveal:
        return Stack(children: [
          Positioned(left: left, top: top, width: pw, height: ph, child: photo),
        ]);

      case SlideContentAnimation.slideUp:
        final e = Curves.easeOutCubic.transform(t);
        return Stack(children: [
          Positioned(
            left: left, top: top + 100 * (1 - e), width: pw, height: ph,
            child: Opacity(opacity: e, child: photo),
          ),
        ]);

      case SlideContentAnimation.slideIn:
        final e = Curves.easeOutCubic.transform(t);
        return Stack(children: [
          Positioned(
            left: left - 200 * (1 - e), top: top, width: pw, height: ph,
            child: Opacity(opacity: e, child: photo),
          ),
        ]);

      case SlideContentAnimation.fadeStagger:
        return Stack(children: [
          Positioned(
            left: left, top: top, width: pw, height: ph,
            child: Opacity(opacity: t, child: photo),
          ),
        ]);

      case SlideContentAnimation.float:
        final e = Curves.easeInOut.transform(t);
        return Stack(children: [
          Positioned(
            left: left, top: top + (-16 * e + 8), width: pw, height: ph,
            child: photo,
          ),
        ]);

      case SlideContentAnimation.zoomPulse:
        final e = Curves.easeInOut.transform(t);
        final scale = 1.0 + 0.08 * e;
        final dw = pw * (scale - 1) / 2;
        final dh = ph * (scale - 1) / 2;
        return Stack(children: [
          Positioned(
            left: left - dw, top: top - dh,
            width: pw * scale, height: ph * scale,
            child: photo,
          ),
        ]);
    }
  }
}

class _WipeClipper extends CustomClipper<Rect> {
  const _WipeClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_WipeClipper old) => old.progress != progress;
}
