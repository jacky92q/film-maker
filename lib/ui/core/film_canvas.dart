import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/domain/models/sticker.dart';
import 'package:film_maker/ui/core/photo_frame_widget.dart';
import 'package:film_maker/ui/core/sticker_painter.dart';
import 'package:film_maker/ui/core/slide_frame.dart';
import 'package:film_maker/ui/core/slide_overlay.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:flutter/material.dart';

// ── Public controller ─────────────────────────────────────────────────────────

/// External handle for controlling a [FilmCanvas].
class FilmCanvasController extends ChangeNotifier {
  _FilmCanvasState? _state;

  void _attach(_FilmCanvasState s) {
    _state = s;
    notifyListeners();
  }

  void _detach() {
    _state = null;
  }

  bool get isPlaying    => _state?._isPlaying    ?? false;
  int  get currentIndex => _state?._currentIndex ?? 0;
  bool get isFirst => currentIndex == 0;
  bool get isLast  =>
      _state == null || currentIndex >= _state!.widget.project.slides.length - 1;

  void play()    => _state?._setPlaying(true);
  void pause()   => _state?._setPlaying(false);
  void toggle()  => isPlaying ? pause() : play();
  void next()    => _state?._skipTo(currentIndex + 1);
  void previous()=> _state?._skipTo(currentIndex - 1);
  void seekToSlide(int index) => _state?._skipTo(index);

  // Called by _FilmCanvasState to trigger listener notifications from
  // within the controller (avoids calling the protected notifyListeners
  // from outside the ChangeNotifier subclass).
  void _notifyChanged() => notifyListeners();
}

// ── FilmCanvas ────────────────────────────────────────────────────────────────

/// Self-playing film canvas that renders all slides of [project] in sequence
/// with proper transitions and live AnimationController-driven content
/// animations.
///
/// Logical pixel size follows [Project.orientation]: 1280 × 720 (landscape) or
/// 720 × 1280 (portrait). Layer coordinates are normalized so they render
/// identically in either orientation.
///
/// Assign a [controller] to pause/resume/skip from outside. Attach a
/// [RepaintBoundary] with a [GlobalKey] on the outside to capture frames
/// for video export.
class FilmCanvas extends StatefulWidget {
  const FilmCanvas({
    super.key,
    required this.project,
    this.controller,
    this.autoPlay = true,
    this.onComplete,
    this.onSlideChanged,
  });

  final Project project;
  final FilmCanvasController? controller;
  final bool autoPlay;
  final VoidCallback? onComplete;
  final void Function(int index)? onSlideChanged;

  // Landscape long/short edges. Use [Project.orientation] for the actual
  // per-project canvas dimensions.
  static const double kWidth  = 1280.0;
  static const double kHeight =  720.0;

  @override
  State<FilmCanvas> createState() => _FilmCanvasState();
}

class _FilmCanvasState extends State<FilmCanvas> with TickerProviderStateMixin {
  int  _currentIndex = 0;
  int? _prevIndex;
  bool _isPlaying = false;

  late AnimationController _transitionCtrl;
  late AnimationController _kenBurnsCtrl;
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _kenBurnsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    widget.controller?._attach(this);
    if (widget.autoPlay) _setPlaying(true);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _slideTimer?.cancel();
    _transitionCtrl.dispose();
    _kenBurnsCtrl.dispose();
    super.dispose();
  }

  // ── Playback ────────────────────────────────────────────────────────────────

  void _setPlaying(bool playing) {
    if (_isPlaying == playing) return;
    _isPlaying = playing;
    if (playing) {
      _startSlideTimer();
      _resumeKenBurns();
    } else {
      _slideTimer?.cancel();
      _kenBurnsCtrl.stop();
    }
    widget.controller?._notifyChanged();
    if (mounted) setState(() {});
  }

  void _beginSlide(int index, {bool withTransition = true}) {
    if (index < 0 || index >= widget.project.slides.length) return;
    final slide = widget.project.slides[index];

    // Ken Burns on background.
    if (slide.transition == TransitionEffect.kenBurns) {
      _kenBurnsCtrl
        ..reset()
        ..repeat(reverse: true);
    } else {
      _kenBurnsCtrl
        ..stop()
        ..reset();
    }

    // Slide-in transition.
    if (withTransition) {
      _transitionCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _prevIndex = null);
      });
    }

    widget.onSlideChanged?.call(index);
    widget.controller?._notifyChanged();

    if (_isPlaying) _startSlideTimer();
  }

  void _startSlideTimer() {
    _slideTimer?.cancel();
    if (_currentIndex >= widget.project.slides.length) return;
    final slide = widget.project.slides[_currentIndex];
    _slideTimer = Timer(Duration(seconds: slide.durationSeconds), _advance);
  }

  void _advance() {
    if (!mounted) return;
    final next = _currentIndex + 1;
    if (next >= widget.project.slides.length) {
      widget.onComplete?.call();
      return;
    }
    setState(() {
      _prevIndex    = _currentIndex;
      _currentIndex = next;
    });
    _beginSlide(next);
  }

  void _skipTo(int index) {
    if (index < 0 || index >= widget.project.slides.length) return;
    setState(() {
      _prevIndex    = null;
      _currentIndex = index;
    });
    _beginSlide(index, withTransition: false);
  }

  void _resumeKenBurns() {
    final slide = widget.project.slides[_currentIndex];
    if (slide.transition == TransitionEffect.kenBurns) {
      _kenBurnsCtrl.repeat(reverse: true);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final slides = widget.project.slides;
    final canvasW = widget.project.orientation.canvasWidth;
    final canvasH = widget.project.orientation.canvasHeight;
    if (slides.isEmpty) {
      return SizedBox(width: canvasW, height: canvasH);
    }

    // Every slide is mounted simultaneously and kept alive for the whole film.
    // Inactive slides are painted-invisible (Opacity 0) but stay in the tree, so
    // their Image.file providers resolve and stay decoded — the moment a slide
    // becomes current it paints instantly with no decode flicker or late render.
    return SizedBox(
      width:  canvasW,
      height: canvasH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (int i = 0; i < slides.length; i++)
            _buildSlideLayer(i, slides[i], canvasW, canvasH),
        ],
      ),
    );
  }

  Widget _buildSlideLayer(int i, Slide slide, double canvasW, double canvasH) {
    final isCurrent = i == _currentIndex;
    final isPrev    = i == _prevIndex;

    // Stable key per slide => never remounts => image stays decoded.
    final slideWidget = _SingleSlide(
      key: ValueKey(slide.id),
      slide: slide,
      kenBurnsCtrl: _kenBurnsCtrl,
      playing: isCurrent && _isPlaying,
      canvasW: canvasW,
      canvasH: canvasH,
    );

    // Off-screen slides: kept mounted (warm) but not painted and not hit-tested.
    if (!isCurrent && !isPrev) {
      return Positioned.fill(
        child: IgnorePointer(child: Opacity(opacity: 0.0, child: slideWidget)),
      );
    }

    // Outgoing slide: static, fully visible beneath the entering one.
    if (isPrev) {
      return Positioned.fill(child: slideWidget);
    }

    // Entering (current) slide: wrapped by its transition effect while the
    // transition controller runs. Only this layer rebuilds on transition ticks.
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _transitionCtrl,
        builder: (context, child) {
          final t = _prevIndex != null
              ? Curves.easeInOut.transform(_transitionCtrl.value)
              : 1.0;
          return _applyTransition(slide.transition, t, child!);
        },
        child: slideWidget,
      ),
    );
  }

  Widget _applyTransition(TransitionEffect effect, double t, Widget child) {
    if (t >= 1.0) return child;
    switch (effect) {
      case TransitionEffect.fade:
      case TransitionEffect.kenBurns:
        return Opacity(opacity: t, child: child);
      case TransitionEffect.blurDissolve:
        // Genuine defocus-to-focus dissolve: blur eases out as the slide
        // fades in, so it reads distinctly from a plain fade.
        final blur = (1.0 - t) * 14.0;
        return Opacity(
          opacity: t,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: child,
          ),
        );
      case TransitionEffect.slideLeft:
        return FractionalTranslation(
            translation: Offset(1.0 - t, 0), child: child);
      case TransitionEffect.slideRight:
        return FractionalTranslation(
            translation: Offset(-(1.0 - t), 0), child: child);
      case TransitionEffect.zoomIn:
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
        );
      case TransitionEffect.wipeLeft:
        return ClipRect(clipper: _RightToLeftClipper(t), child: child);
      case TransitionEffect.wipeRight:
        return ClipRect(clipper: _LeftToRightClipper(t),  child: child);
      case TransitionEffect.pushUp:
        return FractionalTranslation(
            translation: Offset(0, 1.0 - t), child: child);
      case TransitionEffect.pushDown:
        return FractionalTranslation(
            translation: Offset(0, -(1.0 - t)), child: child);
      case TransitionEffect.circleReveal:
        return ClipPath(clipper: _CircleRevealClipper(t), child: child);
    }
  }
}

// ── Single slide ──────────────────────────────────────────────────────────────

class _SingleSlide extends StatelessWidget {
  const _SingleSlide({
    super.key,
    required this.slide,
    required this.kenBurnsCtrl,
    required this.playing,
    required this.canvasW,
    required this.canvasH,
  });

  final Slide slide;
  final AnimationController kenBurnsCtrl;
  final bool playing;
  final double canvasW;
  final double canvasH;

  List<Widget> _layers() {
    final items = <({int z, int type, Object layer})>[];
    for (final l in slide.textLayers)    items.add((z: l.zOrder, type: 0, layer: l));
    for (final p in slide.photoLayers)   items.add((z: p.zOrder, type: 1, layer: p));
    for (final s in slide.stickerLayers) items.add((z: s.zOrder, type: 2, layer: s));
    items.sort((a, b) => a.z.compareTo(b.z));
    return [
      for (final item in items)
        if (item.type == 0)
          _TextLayer(
            key: ValueKey((item.layer as TextLayer).id),
            layer: item.layer as TextLayer,
            playing: playing,
          )
        else if (item.type == 1)
          _PhotoLayer(
            key: ValueKey((item.layer as PhotoLayer).id),
            pl: item.layer as PhotoLayer,
            playing: playing,
            canvasW: canvasW,
            canvasH: canvasH,
          )
        else
          _StickerLayer(
            key: ValueKey((item.layer as StickerLayer).id),
            sl: item.layer as StickerLayer,
            canvasW: canvasW,
            canvasH: canvasH,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: canvasW, height: canvasH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Background(slide: slide, kenBurnsCtrl: kenBurnsCtrl, playing: playing),
          buildSlideDim(slide.dimDirection, slide.dimOpacity),
          buildSlideOverlay(slide.overlay),
          buildSlideFrame(slide.frame, slide.frameColor.color),
          ..._layers(),
          if (slide.ambientEffect != SlideAmbientEffect.none)
            Positioned.fill(
              child: _AmbientLayer(
                effect: slide.ambientEffect,
                playing: playing,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _Background extends StatefulWidget {
  const _Background({
    required this.slide,
    required this.kenBurnsCtrl,
    required this.playing,
  });
  final Slide slide;
  final AnimationController kenBurnsCtrl;
  final bool playing;

  @override
  State<_Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<_Background>
    with SingleTickerProviderStateMixin {
  late AnimationController _stripCtrl;

  @override
  void initState() {
    super.initState();
    _stripCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.slide.durationSeconds),
    );
    if (widget.playing && widget.slide.layout != SlideLayout.single) {
      _stripCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(_Background old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing &&
        widget.slide.layout != SlideLayout.single) {
      _stripCtrl.forward();
    } else if (!widget.playing && old.playing) {
      _stripCtrl.stop();
    }
  }

  @override
  void dispose() {
    _stripCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    if (slide.imagePath == null && slide.layout == SlideLayout.single) {
      return ColoredBox(color: Color(slide.backgroundColor));
    }
    if (slide.layout != SlideLayout.single) return _strip(slide);
    return _single(slide);
  }

  Widget _single(Slide slide) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth, h = constraints.maxHeight;
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
            offset: Offset(slide.photoOffsetX * w, slide.photoOffsetY * h),
            child: Transform.scale(scale: slide.photoScale, child: photo),
          ),
        ),
      );
      if (slide.transition != TransitionEffect.kenBurns) return base;
      return AnimatedBuilder(
        animation: widget.kenBurnsCtrl,
        builder: (ctx, child) {
          final v = widget.kenBurnsCtrl.value;
          return Transform.scale(
            scale: 1.0 + 0.08 * v,
            alignment: Alignment.center,
            child: Transform.translate(
                offset: Offset(0.03 * (v - 0.5) * 200, 0), child: child),
          );
        },
        child: base,
      );
    });
  }

  Widget _strip(Slide slide) {
    final photos = [slide.imagePath, slide.imagePath2];
    if (slide.layout == SlideLayout.strip3) photos.add(slide.imagePath3);
    final n = photos.length;
    return ClipRect(
      child: AnimatedBuilder(
        animation: _stripCtrl,
        builder: (ctx, _) => LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth, h = constraints.maxHeight;
          return Transform.translate(
            offset: Offset(-_stripCtrl.value * (n - 1) * w, 0),
            child: Row(
              children: photos.map((path) => SizedBox(
                width: w, height: h,
                child: buildShapedPhoto(
                  imagePath: path,
                  shape: slide.photoShape,
                  frame: slide.photoFrame,
                  fit: BoxFit.cover,
                  colorFilter: slide.photoFilter.colorFilter,
                ),
              )).toList(),
            ),
          );
        }),
      ),
    );
  }
}

// ── Animation helpers ─────────────────────────────────────────────────────────

Duration _animDur(SlideContentAnimation a) => switch (a) {
  SlideContentAnimation.none        => const Duration(milliseconds: 100),
  SlideContentAnimation.typewriter  => const Duration(milliseconds: 2800),
  SlideContentAnimation.slideUp ||
  SlideContentAnimation.slideIn     => const Duration(milliseconds: 1200),
  SlideContentAnimation.fadeStagger => const Duration(milliseconds: 2000),
  SlideContentAnimation.float       => const Duration(milliseconds: 2200),
  SlideContentAnimation.zoomPulse   => const Duration(milliseconds: 3000),
  SlideContentAnimation.wipeReveal  => const Duration(milliseconds: 2200),
  SlideContentAnimation.handwriting => const Duration(milliseconds: 2600),
  SlideContentAnimation.shimmer     => const Duration(milliseconds: 2600),
  SlideContentAnimation.driftZoom   => const Duration(milliseconds: 7000),
};

bool _loops(SlideContentAnimation a) =>
    a == SlideContentAnimation.float ||
    a == SlideContentAnimation.zoomPulse ||
    a == SlideContentAnimation.shimmer ||
    a == SlideContentAnimation.driftZoom;

// ── Text layer ────────────────────────────────────────────────────────────────

class _TextLayer extends StatefulWidget {
  const _TextLayer({super.key, required this.layer, required this.playing});
  final TextLayer layer;
  final bool playing;

  @override
  State<_TextLayer> createState() => _TextLayerState();
}

class _TextLayerState extends State<_TextLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: _animDur(widget.layer.contentAnimation));
    if (widget.playing) _play();
  }

  @override
  void didUpdateWidget(_TextLayer old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) _play();
    else if (!widget.playing && old.playing) _ctrl.stop();
  }

  void _play() => _loops(widget.layer.contentAnimation)
      ? _ctrl.repeat(reverse: true)
      : _ctrl.forward(from: 0);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Alignment get _align => Alignment(
    (widget.layer.x * 2 - 1).clamp(-0.95, 0.95),
    (widget.layer.y * 2 - 1).clamp(-0.95, 0.92),
  );

  Widget _text({String? override}) {
    final l = widget.layer;
    final style = slideLayerTextStyle(
      l.fontStyle, fontSize: l.fontSize, color: l.color.color,
      shadows: l.shadowLevel.shadows,
    );
    Widget content = Text(override ?? l.text, style: style, textAlign: TextAlign.center);
    if (l.isSubtitle) {
      content = IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: l.barColor.color, width: 2.5)),
          ),
          child: content,
        ),
      );
    }
    return Transform.rotate(angle: l.rotation * math.pi / 180.0, child: content);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.layer;
    switch (l.contentAnimation) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.zoomPulse:
        return Positioned.fill(child: Align(alignment: _align, child: _text()));

      case SlideContentAnimation.typewriter:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final n = (l.text.length * _ctrl.value).round().clamp(0, l.text.length);
          return Positioned.fill(child: Opacity(
            opacity: _ctrl.value > 0 ? 1.0 : 0.0,
            child: Align(alignment: _align, child: _text(override: l.text.substring(0, n))),
          ));
        });

      case SlideContentAnimation.slideUp:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return Positioned.fill(child: Opacity(opacity: t,
            child: Transform.translate(offset: Offset(0, 100 * (1 - t)),
              child: Align(alignment: _align, child: _text()))));
        });

      case SlideContentAnimation.slideIn:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return Positioned.fill(child: Opacity(opacity: t,
            child: Transform.translate(offset: Offset(-200 * (1 - t), 0),
              child: Align(alignment: _align, child: _text()))));
        });

      case SlideContentAnimation.fadeStagger:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) =>
          Positioned.fill(child: Opacity(opacity: _ctrl.value,
            child: Align(alignment: _align, child: _text()))));

      case SlideContentAnimation.float:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final dy = -16 * Curves.easeInOut.transform(_ctrl.value) + 8;
          return Positioned.fill(child: Align(alignment: _align,
            child: Transform.translate(offset: Offset(0, dy), child: _text())));
        });

      case SlideContentAnimation.wipeReveal:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final t = Curves.easeOut.transform(_ctrl.value);
          return Positioned.fill(child: Align(alignment: _align,
            child: ClipRect(clipper: _LeftToRightClipper(t), child: _text())));
        });

      case SlideContentAnimation.handwriting:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final t = Curves.easeInOut.transform(_ctrl.value);
          return Positioned.fill(child: Align(alignment: _align,
            child: ClipPath(
              clipper: _BrushRevealClipper(t),
              child: _text(),
            )));
        });

      case SlideContentAnimation.shimmer:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final p = _ctrl.value;
          return Positioned.fill(child: Align(alignment: _align,
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0x00FFFFFF),
                  Color(0xFFFFF4D0),
                  Color(0x00FFFFFF),
                ],
                stops: [
                  (p - 0.18).clamp(0.0, 1.0),
                  p.clamp(0.0, 1.0),
                  (p + 0.18).clamp(0.0, 1.0),
                ],
              ).createShader(rect),
              child: _text(),
            )));
        });

      case SlideContentAnimation.driftZoom:
        return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          final scale = 1.0 + 0.05 * Curves.easeInOut.transform(_ctrl.value);
          return Positioned.fill(child: Align(alignment: _align,
            child: Transform.scale(scale: scale, child: _text())));
        });
    }
  }
}

// ── Photo layer ───────────────────────────────────────────────────────────────

class _PhotoLayer extends StatefulWidget {
  const _PhotoLayer({
    super.key,
    required this.pl,
    required this.playing,
    required this.canvasW,
    required this.canvasH,
  });
  final PhotoLayer pl;
  final bool playing;
  final double canvasW;
  final double canvasH;

  @override
  State<_PhotoLayer> createState() => _PhotoLayerState();
}

class _PhotoLayerState extends State<_PhotoLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: _animDur(widget.pl.contentAnimation));
    if (widget.playing) _play();
  }

  @override
  void didUpdateWidget(_PhotoLayer old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) _play();
    else if (!widget.playing && old.playing) _ctrl.stop();
  }

  void _play() => _loops(widget.pl.contentAnimation)
      ? _ctrl.repeat(reverse: true)
      : _ctrl.forward(from: 0);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _photo() {
    final pl = widget.pl;
    return Transform.rotate(
      angle: pl.rotation * math.pi / 180.0,
      child: buildShapedPhoto(
        imagePath: pl.imagePath, shape: pl.shape, frame: pl.frame,
        fit: BoxFit.cover, colorFilter: pl.filter.colorFilter,
        frameWidth: pl.frameWidth, cropScale: pl.cropScale,
        cropOffsetX: pl.cropOffsetX, cropOffsetY: pl.cropOffsetY,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pl = widget.pl;
    final w = widget.canvasW, h = widget.canvasH;
    final left = (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * w;
    final top  = (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * h;
    final pw   = pl.widthFraction * w;
    final ph   = pl.heightFraction * h;

    switch (pl.contentAnimation) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.typewriter:
      case SlideContentAnimation.wipeReveal:
      case SlideContentAnimation.handwriting:
      case SlideContentAnimation.shimmer:
        return Stack(children: [Positioned(left: left, top: top, width: pw, height: ph, child: _photo())]);

      case SlideContentAnimation.slideUp:
        return AnimatedBuilder(animation: _ctrl, builder: (_, child) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return Stack(children: [Positioned(
            left: left, top: top + 100 * (1 - t), width: pw, height: ph,
            child: Opacity(opacity: t, child: child))]);
        }, child: _photo());

      case SlideContentAnimation.slideIn:
        return AnimatedBuilder(animation: _ctrl, builder: (_, child) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return Stack(children: [Positioned(
            left: left - 200 * (1 - t), top: top, width: pw, height: ph,
            child: Opacity(opacity: t, child: child))]);
        }, child: _photo());

      case SlideContentAnimation.fadeStagger:
        return AnimatedBuilder(animation: _ctrl, builder: (_, child) =>
          Stack(children: [Positioned(left: left, top: top, width: pw, height: ph,
            child: Opacity(opacity: _ctrl.value, child: child))]),
          child: _photo());

      case SlideContentAnimation.float:
        return AnimatedBuilder(animation: _ctrl, builder: (_, child) {
          final dy = -16 * Curves.easeInOut.transform(_ctrl.value) + 8;
          return Stack(children: [Positioned(
            left: left, top: top + dy, width: pw, height: ph, child: child!)]);
        }, child: _photo());

      case SlideContentAnimation.zoomPulse:
        return AnimatedBuilder(animation: _ctrl, builder: (_, child) {
          final sc = 1.0 + 0.08 * Curves.easeInOut.transform(_ctrl.value);
          final dw = pw * (sc - 1) / 2, dh = ph * (sc - 1) / 2;
          return Stack(children: [Positioned(
            left: left - dw, top: top - dh,
            width: pw * sc, height: ph * sc, child: child!)]);
        }, child: _photo());

      case SlideContentAnimation.driftZoom:
        return AnimatedBuilder(animation: _ctrl, builder: (_, child) {
          final t = Curves.easeInOut.transform(_ctrl.value);
          final sc = 1.0 + 0.12 * t;
          final panX = (t - 0.5) * pw * 0.06;
          return Stack(children: [Positioned(
            left: left, top: top, width: pw, height: ph,
            child: ClipRect(
              child: Transform.scale(
                scale: sc,
                child: Transform.translate(
                    offset: Offset(panX, 0), child: child),
              ),
            ))]);
        }, child: _photo());
    }
  }
}

// ── Sticker layer ───────────────────────────────────────────────────────────────

class _StickerLayer extends StatelessWidget {
  const _StickerLayer({
    super.key,
    required this.sl,
    required this.canvasW,
    required this.canvasH,
  });
  final StickerLayer sl;
  final double canvasW;
  final double canvasH;

  @override
  Widget build(BuildContext context) {
    final w = sl.widthFraction * canvasW;
    final h = w / sl.kind.aspectRatio;
    final left = sl.x * canvasW - w / 2;
    final top = sl.y * canvasH - h / 2;
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: Transform.rotate(
        angle: sl.rotation * math.pi / 180.0,
        child: StickerWidget(
          kind: sl.kind,
          opacity: sl.opacity,
        ),
      ),
    );
  }
}

// ── Clippers ──────────────────────────────────────────────────────────────────

class _CircleRevealClipper extends CustomClipper<Path> {
  const _CircleRevealClipper(this.p);
  final double p;
  @override
  Path getClip(Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final maxR = math.sqrt(s.width * s.width + s.height * s.height) / 2;
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: maxR * p));
  }

  @override
  bool shouldReclip(_CircleRevealClipper o) => o.p != p;
}

class _LeftToRightClipper extends CustomClipper<Rect> {
  const _LeftToRightClipper(this.p);
  final double p;
  @override Rect getClip(Size s) => Rect.fromLTWH(0, 0, s.width * p, s.height);
  @override bool shouldReclip(_LeftToRightClipper o) => o.p != p;
}

class _RightToLeftClipper extends CustomClipper<Rect> {
  const _RightToLeftClipper(this.p);
  final double p;
  @override Rect getClip(Size s) {
    final w = s.width;
    return Rect.fromLTWH(w * (1 - p), 0, w * p, s.height);
  }
  @override bool shouldReclip(_RightToLeftClipper o) => o.p != p;
}

class _BrushRevealClipper extends CustomClipper<Path> {
  const _BrushRevealClipper(this.p);
  final double p;

  @override
  Path getClip(Size s) {
    if (p >= 1.0) {
      return Path()..addRect(Rect.fromLTWH(0, 0, s.width, s.height));
    }
    final revealX = s.width * p;
    const segs = 10;
    final path = Path()..moveTo(0, 0)..lineTo(revealX, 0);
    for (int i = 1; i <= segs; i++) {
      final ty = i / segs;
      final wobble = math.sin(ty * math.pi * 3 + p * math.pi) *
          s.width * 0.025 * (1.0 - p * 0.5);
      path.lineTo(revealX + wobble, ty * s.height);
    }
    path.lineTo(0, s.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BrushRevealClipper old) => old.p != p;
}

// ── Ambient particle effects ──────────────────────────────────────────────────

class _Ptcl {
  const _Ptcl({
    required this.x,
    required this.y,
    required this.phase,
    required this.size,
    required this.speed,
    required this.angle,
    required this.color,
  });
  final double x;
  final double y;
  final double phase;
  final double size;
  final double speed;
  final double angle;
  final Color color;
}

List<_Ptcl> _buildParticles(SlideAmbientEffect effect) {
  final rng = math.Random(effect.index * 37 + 13);
  double r() => rng.nextDouble();
  Color pick(List<Color> cs) => cs[rng.nextInt(cs.length)];

  switch (effect) {
    case SlideAmbientEffect.none:
      return [];

    case SlideAmbientEffect.petalFall:
      const cs = [Color(0xFFFFB7C5), Color(0xFFFFCDD2), Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFFFEBEE)];
      return List.generate(26, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.010 + r() * 0.014, speed: 0.35 + r() * 0.45,
        angle: r() * math.pi * 2, color: pick(cs)));

    case SlideAmbientEffect.sparkleRise:
      const cs = [Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFF7E7CE), Color(0xFFFFFFFF), Color(0xFFFFF8DC)];
      return List.generate(22, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.006 + r() * 0.016, speed: 0.3 + r() * 0.6,
        angle: 0, color: pick(cs)));

    case SlideAmbientEffect.snowFall:
      const cs = [Color(0xFFFFFFFF), Color(0xFFE3F2FD), Color(0xFFECEFF1)];
      return List.generate(32, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.006 + r() * 0.012, speed: 0.25 + r() * 0.4,
        angle: 0, color: pick(cs)));

    case SlideAmbientEffect.heartFloat:
      const cs = [Color(0xFFFF8A9A), Color(0xFFFF6B81), Color(0xFFFF4757), Color(0xFFFFB7C5), Color(0xFFF8BBD0)];
      return List.generate(16, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.012 + r() * 0.018, speed: 0.25 + r() * 0.45,
        angle: 0, color: pick(cs)));

    case SlideAmbientEffect.goldDust:
      const cs = [Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFFFF8DC), Color(0xFFDAA520), Color(0xFFFFFFFF)];
      return List.generate(55, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.003 + r() * 0.008, speed: 0.2 + r() * 0.5,
        angle: r() * math.pi * 2, color: pick(cs)));

    case SlideAmbientEffect.confettiFall:
      const cs = [Color(0xFFFFD700), Color(0xFFFF6B81), Color(0xFFFFFFFF), Color(0xFFF7E7CE), Color(0xFFB0C4DE), Color(0xFFDDA0DD)];
      return List.generate(30, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.008 + r() * 0.012, speed: 0.3 + r() * 0.5,
        angle: r() * math.pi * 2, color: pick(cs)));

    case SlideAmbientEffect.bokeFloat:
      const cs = [Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFFFFB7C5), Color(0xFFF7E7CE), Color(0xFFDDA0DD)];
      return List.generate(11, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.06 + r() * 0.12, speed: 0.08 + r() * 0.15,
        angle: r() * math.pi * 2, color: pick(cs)));

    case SlideAmbientEffect.starTwinkle:
      const cs = [Color(0xFFFFFFFF), Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFE0E0E0)];
      return List.generate(22, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.008 + r() * 0.018, speed: 0.4 + r() * 0.6,
        angle: 0, color: pick(cs)));

    case SlideAmbientEffect.ribbonStream:
      const cs = [Color(0xFFFFD700), Color(0xFFFF6B81), Color(0xFFFFFFFF), Color(0xFFF7E7CE)];
      return List.generate(14, (_) => _Ptcl(x: r(), y: r(), phase: r(),
        size: 0.003 + r() * 0.004, speed: 0.3 + r() * 0.4,
        angle: r() * math.pi * 2, color: pick(cs)));

    case SlideAmbientEffect.lightRays:
      const cs = [Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFFFFF8DC)];
      return List.generate(7, (_) => _Ptcl(
        x: 0.5 + (r() - 0.5) * 0.3, y: 0.0, phase: r(),
        size: 0.14 + r() * 0.10, speed: 0.04 + r() * 0.06,
        angle: (r() - 0.5) * math.pi * 0.5, color: pick(cs)));
  }
}

class _AmbientLayer extends StatefulWidget {
  const _AmbientLayer({required this.effect, required this.playing});
  final SlideAmbientEffect effect;
  final bool playing;

  @override
  State<_AmbientLayer> createState() => _AmbientLayerState();
}

class _AmbientLayerState extends State<_AmbientLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Ptcl> _particles;

  Duration _cycleDur(SlideAmbientEffect e) => switch (e) {
    SlideAmbientEffect.bokeFloat   => const Duration(seconds: 8),
    SlideAmbientEffect.lightRays   => const Duration(seconds: 10),
    SlideAmbientEffect.starTwinkle => const Duration(milliseconds: 1800),
    _                              => const Duration(seconds: 5),
  };

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles(widget.effect);
    _ctrl = AnimationController(vsync: this, duration: _cycleDur(widget.effect));
    if (widget.playing) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_AmbientLayer old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) _ctrl.repeat();
    else if (!widget.playing && old.playing) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _AmbientPainter(
          effect: widget.effect,
          particles: _particles,
          t: _ctrl.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({
    required this.effect,
    required this.particles,
    required this.t,
  });
  final SlideAmbientEffect effect;
  final List<_Ptcl> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    switch (effect) {
      case SlideAmbientEffect.none:
        break;
      case SlideAmbientEffect.petalFall:
        _paintPetalFall(canvas, size);
      case SlideAmbientEffect.sparkleRise:
        _paintSparkleRise(canvas, size);
      case SlideAmbientEffect.snowFall:
        _paintSnowFall(canvas, size);
      case SlideAmbientEffect.heartFloat:
        _paintHeartFloat(canvas, size);
      case SlideAmbientEffect.goldDust:
        _paintGoldDust(canvas, size);
      case SlideAmbientEffect.confettiFall:
        _paintConfetti(canvas, size);
      case SlideAmbientEffect.bokeFloat:
        _paintBokeh(canvas, size);
      case SlideAmbientEffect.starTwinkle:
        _paintStarTwinkle(canvas, size);
      case SlideAmbientEffect.ribbonStream:
        _paintRibbons(canvas, size);
      case SlideAmbientEffect.lightRays:
        _paintLightRays(canvas, size);
    }
  }

  double _alpha(double progress) {
    if (progress < 0.08) return progress / 0.08;
    if (progress > 0.92) return (1.0 - progress) / 0.08;
    return 1.0;
  }

  void _paintPetalFall(Canvas canvas, Size s) {
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final py = progress * s.height * 1.25 - s.height * 0.1;
      final px = p.x * s.width +
          math.sin(progress * math.pi * 4 + p.phase * math.pi * 2) * s.width * 0.05;
      final rot = p.angle + progress * math.pi * 4;
      final a = _alpha(progress);
      final pw = p.size * s.width * 0.55;
      final ph = p.size * s.width;
      final paint = Paint()
        ..color = p.color.withValues(alpha: a * 0.85)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      final path = Path()
        ..moveTo(0, -ph * 0.5)
        ..cubicTo(pw * 0.9, -ph * 0.15, pw * 0.9, ph * 0.2, 0, ph * 0.5)
        ..cubicTo(-pw * 0.9, ph * 0.2, -pw * 0.9, -ph * 0.15, 0, -ph * 0.5);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _paintSparkleRise(Canvas canvas, Size s) {
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final py = p.y * s.height - progress * s.height * 0.35;
      final px = p.x * s.width +
          math.sin(progress * math.pi * 3 + p.phase * 6) * s.width * 0.02;
      final a = _alpha(progress);
      final pulse = 0.7 + 0.3 * math.sin(progress * math.pi * 4);
      final r = p.size * s.width * pulse;
      final paint = Paint()
        ..color = p.color.withValues(alpha: a * 0.9)
        ..style = PaintingStyle.fill;
      _drawStar4(canvas, px, py, r, paint);
    }
  }

  void _paintSnowFall(Canvas canvas, Size s) {
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final py = progress * s.height * 1.15 - s.height * 0.05;
      final px = p.x * s.width +
          math.sin(progress * math.pi * 2 + p.phase * math.pi * 2) * s.width * 0.025;
      final a = _alpha(progress);
      final paint = Paint()
        ..color = p.color.withValues(alpha: a * 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size * s.width, paint);
    }
  }

  void _paintHeartFloat(Canvas canvas, Size s) {
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final py = p.y * s.height - progress * s.height * 0.4;
      final px = p.x * s.width +
          math.sin(progress * math.pi * 3 + p.phase * 5) * s.width * 0.03;
      final a = _alpha(progress);
      final scale = p.size * s.width * 0.5;
      final paint = Paint()
        ..color = p.color.withValues(alpha: a * 0.8)
        ..style = PaintingStyle.fill;
      _drawHeart(canvas, px, py, scale, paint);
    }
  }

  void _paintGoldDust(Canvas canvas, Size s) {
    for (final p in particles) {
      final cycle = (t * p.speed + p.phase) % 1.0;
      final a = math.sin(cycle * math.pi) * 0.85;
      if (a <= 0) continue;
      final px = p.x * s.width +
          math.sin(cycle * math.pi * 2 + p.phase * 4) * s.width * 0.015;
      final py = p.y * s.height - cycle * s.height * 0.08;
      final r = p.size * s.width * (0.8 + 0.4 * math.sin(cycle * math.pi * 3));
      final paint = Paint()
        ..color = p.color.withValues(alpha: a)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  void _paintConfetti(Canvas canvas, Size s) {
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final py = progress * s.height * 1.2 - s.height * 0.1;
      final px = p.x * s.width +
          math.sin(progress * math.pi * 5 + p.phase * math.pi * 2) * s.width * 0.04;
      final rot = p.angle + progress * math.pi * 6;
      final a = _alpha(progress);
      final w = p.size * s.width * 1.8;
      final h = p.size * s.width * 0.7;
      final paint = Paint()
        ..color = p.color.withValues(alpha: a * 0.9)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintBokeh(Canvas canvas, Size s) {
    for (final p in particles) {
      final cycle = (t * p.speed + p.phase) % 1.0;
      final px = p.x * s.width +
          math.sin(cycle * math.pi * 2 + p.phase * 4) * s.width * 0.04;
      final py = p.y * s.height +
          math.cos(cycle * math.pi * 2 + p.phase * 3) * s.height * 0.025;
      final r = p.size * math.min(s.width, s.height) *
          (0.85 + 0.15 * math.sin(cycle * math.pi * 3));
      final baseAlpha = 0.16 + 0.10 * math.sin(cycle * math.pi * 2);
      final gradient = RadialGradient(
        colors: [
          p.color.withValues(alpha: baseAlpha),
          p.color.withValues(alpha: baseAlpha * 0.3),
          p.color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      final paint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: Offset(px, py), radius: r));
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  void _paintStarTwinkle(Canvas canvas, Size s) {
    for (final p in particles) {
      final cycle = (t * p.speed + p.phase) % 1.0;
      final brightness =
          math.pow(math.sin(cycle * math.pi), 1.5).toDouble();
      if (brightness < 0.05) continue;
      final px = p.x * s.width;
      final py = p.y * s.height;
      final r = p.size * s.width * brightness;
      final paint = Paint()
        ..color = p.color.withValues(alpha: brightness * 0.95)
        ..style = PaintingStyle.fill;
      _drawStar4(canvas, px, py, r, paint);
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: brightness * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(px, py), r * 2.5, glowPaint);
    }
  }

  void _paintRibbons(Canvas canvas, Size s) {
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final py = progress * s.height * 1.2 - s.height * 0.1;
      final px = p.x * s.width;
      final a = _alpha(progress);
      final rot = p.angle + progress * math.pi * 3;
      final len = p.size * s.width * 60;
      final thick = p.size * s.width * 6;
      final paint = Paint()
        ..color = p.color.withValues(alpha: a * 0.9)
        ..strokeWidth = thick
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      final path = Path()
        ..moveTo(-len * 0.5, 0)
        ..cubicTo(-len * 0.2, -len * 0.15, len * 0.2, len * 0.15, len * 0.5, 0);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _paintLightRays(Canvas canvas, Size s) {
    for (final p in particles) {
      final cycle = (t * p.speed + p.phase) % 1.0;
      final rot = p.angle + cycle * math.pi * 0.15;
      final baseAlpha = 0.22 + 0.12 * math.sin(cycle * math.pi * 2);
      final halfSpread = p.size * 0.5;
      final length = s.height * 1.5;
      final ox = p.x * s.width;
      const oy = 0.0;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.color.withValues(alpha: baseAlpha),
            p.color.withValues(alpha: baseAlpha * 0.4),
            p.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromLTWH(
            ox - length * halfSpread, oy,
            length * halfSpread * 2, length));
      canvas.save();
      canvas.translate(ox, oy);
      canvas.rotate(rot);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-length * halfSpread, length)
        ..lineTo(length * halfSpread, length)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _drawStar4(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final radius = i.isEven ? r : r * 0.3;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double size, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy + size * 0.4)
      ..cubicTo(cx - size * 1.1, cy - size * 0.05,
                cx - size * 1.1, cy - size * 0.7, cx, cy - size * 0.25)
      ..cubicTo(cx + size * 1.1, cy - size * 0.7,
                cx + size * 1.1, cy - size * 0.05, cx, cy + size * 0.4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.t != t || old.effect != effect;
}
