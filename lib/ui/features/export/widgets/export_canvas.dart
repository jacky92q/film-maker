import 'dart:math' as math;

import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/photo_frame_widget.dart';
import 'package:film_maker/ui/core/slide_overlay.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:flutter/material.dart';

/// Renders one or two slides for frame-by-frame video export.
///
/// When [prevSlide] is provided and [transitionProgress] ∈ (0, 1), the
/// previous slide is drawn as the bottom layer and the current slide is
/// composited on top using [slide.transition].
class ExportCanvas extends StatelessWidget {
  const ExportCanvas({
    super.key,
    required this.slide,
    required this.slideTimeSeconds,
    this.prevSlide,
    this.prevSlideTimeSeconds = 0.0,
    this.transitionProgress = 0.0,
  });

  final Slide slide;
  final double slideTimeSeconds;

  /// The slide that was playing before this one (for cross-slide transitions).
  final Slide? prevSlide;

  /// The time offset used to render [prevSlide] (typically its end time).
  final double prevSlideTimeSeconds;

  /// 0 = still showing [prevSlide], 1 = fully on [slide].
  final double transitionProgress;

  static const double kWidth  = 1280.0;
  static const double kHeight =  720.0;

  @override
  Widget build(BuildContext context) {
    final inTransition =
        prevSlide != null && transitionProgress > 0 && transitionProgress < 1.0;

    if (!inTransition) {
      return _SlideRender(slide: slide, time: slideTimeSeconds);
    }

    final te = Curves.easeInOut.transform(transitionProgress);
    final incoming = _SlideRender(slide: slide, time: slideTimeSeconds);

    final Widget overlay;
    switch (slide.transition) {
      case TransitionEffect.fade:
      case TransitionEffect.kenBurns:
      case TransitionEffect.blurDissolve:
        overlay = Opacity(opacity: te, child: incoming);

      case TransitionEffect.slideLeft:
        // Incoming enters from the right edge.
        overlay = Transform.translate(
          offset: Offset(kWidth * (1.0 - te), 0),
          child: incoming,
        );

      case TransitionEffect.slideRight:
        // Incoming enters from the left edge.
        overlay = Transform.translate(
          offset: Offset(-kWidth * (1.0 - te), 0),
          child: incoming,
        );

      case TransitionEffect.zoomIn:
        overlay = Opacity(
          opacity: te,
          child: Transform.scale(scale: 0.5 + 0.5 * te, child: incoming),
        );

      case TransitionEffect.wipeLeft:
        // New slide revealed from right → left.
        overlay = ClipRect(
          clipper: _RightToLeftWipeClipper(te),
          child: incoming,
        );

      case TransitionEffect.wipeRight:
        // New slide revealed from left → right.
        overlay = ClipRect(
          clipper: _LeftToRightWipeClipper(te),
          child: incoming,
        );
    }

    return SizedBox(
      width: kWidth,
      height: kHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _SlideRender(slide: prevSlide!, time: prevSlideTimeSeconds),
          overlay,
        ],
      ),
    );
  }
}

// ── Single-slide renderer ─────────────────────────────────────────────────────

/// Renders one [slide] at the given [time] offset. All animation values are
/// derived mathematically — no AnimationControllers required.
class _SlideRender extends StatelessWidget {
  const _SlideRender({required this.slide, required this.time});

  final Slide slide;
  final double time;

  static const double _w = ExportCanvas.kWidth;
  static const double _h = ExportCanvas.kHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _w,
      height: _h,
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

  // ── Background ─────────────────────────────────────────────────────────────

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
          offset: Offset(slide.photoOffsetX * _w, slide.photoOffsetY * _h),
          child: Transform.scale(scale: slide.photoScale, child: photo),
        ),
      ),
    );

    if (slide.transition != TransitionEffect.kenBurns) return base;

    // Ken Burns: slow zoom + pan across the slide's own duration.
    final kenT = (time / slide.durationSeconds.toDouble()).clamp(0.0, 1.0);
    final scale = 1.0 + 0.08 * kenT;
    final dx    = 0.03 * (kenT - 0.5) * 200;
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Transform.translate(offset: Offset(dx, 0), child: base),
    );
  }

  Widget _buildStrip() {
    final photos = [slide.imagePath, slide.imagePath2];
    if (slide.layout == SlideLayout.strip3) photos.add(slide.imagePath3);
    final n      = photos.length;
    final stripT = (time / slide.durationSeconds.toDouble()).clamp(0.0, 1.0);
    final offset = stripT * (n - 1) * _w;

    return ClipRect(
      child: Transform.translate(
        offset: Offset(-offset, 0),
        child: Row(
          children: photos
              .map((path) => SizedBox(
                    width: _w,
                    height: _h,
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

  // ── Layers ─────────────────────────────────────────────────────────────────

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

  // ── Animation helpers ──────────────────────────────────────────────────────

  static double _animDurSec(SlideContentAnimation a) => switch (a) {
        SlideContentAnimation.none        => 0.1,
        SlideContentAnimation.typewriter  => 2.8,
        SlideContentAnimation.slideUp ||
        SlideContentAnimation.slideIn     => 1.2,
        SlideContentAnimation.fadeStagger => 2.0,
        SlideContentAnimation.float       => 2.2,
        SlideContentAnimation.zoomPulse   => 3.0,
        SlideContentAnimation.wipeReveal  => 2.2,
      };

  double _animT(SlideContentAnimation a) {
    final dur = _animDurSec(a);
    if (dur <= 0) return 1.0;
    switch (a) {
      case SlideContentAnimation.float:
      case SlideContentAnimation.zoomPulse:
        // Looping: triangle wave so the animation oscillates continuously.
        final cycles = time / dur;
        final phase  = cycles - cycles.floor();
        return (cycles.floor() % 2 == 0) ? phase : 1.0 - phase;
      default:
        return (time / dur).clamp(0.0, 1.0);
    }
  }

  // ── Text layer ─────────────────────────────────────────────────────────────

  Widget _buildTextLayer(TextLayer layer) {
    final anim  = layer.contentAnimation;
    final t     = _animT(anim);
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
            child: ClipRect(clipper: _LeftToRightWipeClipper(e), child: text),
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

  // ── Photo layer ────────────────────────────────────────────────────────────

  Widget _buildPhotoLayer(PhotoLayer pl) {
    final left = (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * _w;
    final top  = (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * _h;
    final pw   = pl.widthFraction * _w;
    final ph   = pl.heightFraction * _h;

    final anim = pl.contentAnimation;
    final t    = _animT(anim);

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
        final e    = Curves.easeInOut.transform(t);
        final sc   = 1.0 + 0.08 * e;
        final dw   = pw * (sc - 1) / 2;
        final dh   = ph * (sc - 1) / 2;
        return Stack(children: [
          Positioned(
            left: left - dw, top: top - dh, width: pw * sc, height: ph * sc,
            child: photo,
          ),
        ]);
    }
  }
}

// ── Clippers ──────────────────────────────────────────────────────────────────

/// Reveals content from left → right (wipeRight transition / wipeReveal anim).
class _LeftToRightWipeClipper extends CustomClipper<Rect> {
  const _LeftToRightWipeClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_LeftToRightWipeClipper old) => old.progress != progress;
}

/// Reveals content from right → left (wipeLeft transition).
class _RightToLeftWipeClipper extends CustomClipper<Rect> {
  const _RightToLeftWipeClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) {
    final w = size.width;
    return Rect.fromLTWH(w * (1.0 - progress), 0, w * progress, size.height);
  }

  @override
  bool shouldReclip(_RightToLeftWipeClipper old) => old.progress != progress;
}
