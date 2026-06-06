import 'dart:async';
import 'dart:math' as math;

import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/photo_frame_widget.dart';
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
/// Always 1280 × 720 logical pixels.
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
    if (slides.isEmpty) {
      return const SizedBox(width: FilmCanvas.kWidth, height: FilmCanvas.kHeight);
    }

    // Every slide is mounted simultaneously and kept alive for the whole film.
    // Inactive slides are painted-invisible (Opacity 0) but stay in the tree, so
    // their Image.file providers resolve and stay decoded — the moment a slide
    // becomes current it paints instantly with no decode flicker or late render.
    return SizedBox(
      width:  FilmCanvas.kWidth,
      height: FilmCanvas.kHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (int i = 0; i < slides.length; i++)
            _buildSlideLayer(i, slides[i]),
        ],
      ),
    );
  }

  Widget _buildSlideLayer(int i, Slide slide) {
    final isCurrent = i == _currentIndex;
    final isPrev    = i == _prevIndex;

    // Stable key per slide => never remounts => image stays decoded.
    final slideWidget = _SingleSlide(
      key: ValueKey(slide.id),
      slide: slide,
      kenBurnsCtrl: _kenBurnsCtrl,
      playing: isCurrent && _isPlaying,
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
      case TransitionEffect.blurDissolve:
        return Opacity(opacity: t, child: child);
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
  });

  final Slide slide;
  final AnimationController kenBurnsCtrl;
  final bool playing;

  List<Widget> _layers() {
    final items = <({int z, bool isText, Object layer})>[];
    for (final l in slide.textLayers)  items.add((z: l.zOrder, isText: true,  layer: l));
    for (final p in slide.photoLayers) items.add((z: p.zOrder, isText: false, layer: p));
    items.sort((a, b) => a.z.compareTo(b.z));
    return [
      for (final item in items)
        if (item.isText)
          _TextLayer(
            key: ValueKey((item.layer as TextLayer).id),
            layer: item.layer as TextLayer,
            playing: playing,
          )
        else
          _PhotoLayer(
            key: ValueKey((item.layer as PhotoLayer).id),
            pl: item.layer as PhotoLayer,
            playing: playing,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FilmCanvas.kWidth, height: FilmCanvas.kHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Background(slide: slide, kenBurnsCtrl: kenBurnsCtrl, playing: playing),
          buildSlideDim(slide.dimDirection, slide.dimOpacity),
          buildSlideOverlay(slide.overlay),
          ..._layers(),
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
};

bool _loops(SlideContentAnimation a) =>
    a == SlideContentAnimation.float || a == SlideContentAnimation.zoomPulse;

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
      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 12)],
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
    }
  }
}

// ── Photo layer ───────────────────────────────────────────────────────────────

class _PhotoLayer extends StatefulWidget {
  const _PhotoLayer({super.key, required this.pl, required this.playing});
  final PhotoLayer pl;
  final bool playing;

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
    const w = FilmCanvas.kWidth, h = FilmCanvas.kHeight;
    final left = (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * w;
    final top  = (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * h;
    final pw   = pl.widthFraction * w;
    final ph   = pl.heightFraction * h;

    switch (pl.contentAnimation) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.typewriter:
      case SlideContentAnimation.wipeReveal:
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
    }
  }
}

// ── Clippers ──────────────────────────────────────────────────────────────────

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
