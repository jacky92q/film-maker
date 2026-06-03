import 'dart:async';

import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/core/photo_frame_widget.dart';
import 'package:film_maker/ui/core/slide_overlay.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:film_maker/ui/features/preview/view_models/preview_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class PreviewView extends StatefulWidget {
  const PreviewView({super.key, required this.viewModel});

  final PreviewViewModel viewModel;

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView>
    with TickerProviderStateMixin {
  late AnimationController _kenBurnsController;
  Timer? _autoAdvanceTimer;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _kenBurnsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    widget.viewModel.addListener(_onViewModelChanged);
    _scheduleHideControls();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _kenBurnsController.dispose();
    _autoAdvanceTimer?.cancel();
    _hideControlsTimer?.cancel();
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (widget.viewModel.isPlaying) {
      _startAutoAdvance();
      _startKenBurns();
    } else {
      _stopAutoAdvance();
      _kenBurnsController.stop();
    }
  }

  void _startAutoAdvance() {
    _stopAutoAdvance();
    final slide = widget.viewModel.currentSlide;
    if (slide == null) return;
    _autoAdvanceTimer = Timer(
      Duration(seconds: slide.durationSeconds),
      () {
        if (widget.viewModel.isPlaying) {
          widget.viewModel.nextSlide();
        }
      },
    );
  }

  void _stopAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  void _startKenBurns() {
    if (widget.viewModel.currentSlide?.transition == TransitionEffect.kenBurns) {
      _kenBurnsController.repeat(reverse: true);
    } else {
      _kenBurnsController.stop();
      _kenBurnsController.reset();
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTapScreen() {
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  void _onPlayPause() {
    widget.viewModel.togglePlayPause();
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTapScreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // All slides pre-rendered so photos load instantly on open.
            // Only the current slide is visible (opacity 1); others are 0.
            _buildAllSlides(),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSlides() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final slides = widget.viewModel.project.slides;
        final currentIndex = widget.viewModel.currentIndex;
        if (slides.isEmpty) {
          return const Center(
            child: Text('No slides', style: TextStyle(color: AppTheme.subtleText)),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            for (int i = 0; i < slides.length; i++)
              _AnimatedSlideCanvas(
                key: ValueKey(slides[i].id),
                slide: slides[i],
                kenBurnsController: _kenBurnsController,
                isActive: i == currentIndex,
              ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        _buildTopBar(),
        _buildCenterControls(),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8, right: 16, bottom: 16,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                widget.viewModel.project.title,
                style: TextStyle(fontFamily: AppTheme.fontTheme,
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconButton(
                icon: Icons.skip_previous_rounded,
                onTap: widget.viewModel.isFirstSlide ? null : widget.viewModel.previousSlide,
                size: 36,
              ),
              const SizedBox(width: 20),
              _buildIconButton(
                icon: widget.viewModel.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                onTap: _onPlayPause,
                size: 64,
                color: AppTheme.gold,
              ),
              const SizedBox(width: 20),
              _buildIconButton(
                icon: Icons.skip_next_rounded,
                onTap: widget.viewModel.isLastSlide ? null : widget.viewModel.nextSlide,
                size: 36,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    double size = 32,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: size,
        color: onTap == null ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 24,
        ),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSlideIndicators(),
                const SizedBox(height: 8),
                _buildProgressBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: widget.viewModel.progress,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
        minHeight: 3,
      ),
    );
  }

  Widget _buildSlideIndicators() {
    final total = widget.viewModel.project.slides.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isCurrent = i == widget.viewModel.currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isCurrent ? 20 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isCurrent ? AppTheme.gold : Colors.white.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated slide canvas — pre-rendered, visibility driven by AnimatedOpacity,
// content animations driven by a per-instance AnimationController.
// ─────────────────────────────────────────────────────────────────────────────

Widget _gradientOverlay() => IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
            stops: const [0.3, 1.0],
          ),
        ),
      ),
    );

class _AnimatedSlideCanvas extends StatefulWidget {
  const _AnimatedSlideCanvas({
    super.key,
    required this.slide,
    required this.kenBurnsController,
    required this.isActive,
  });
  final Slide slide;
  final AnimationController kenBurnsController;
  final bool isActive;

  @override
  State<_AnimatedSlideCanvas> createState() => _AnimatedSlideCanvasState();
}

class _AnimatedSlideCanvasState extends State<_AnimatedSlideCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  Duration get _dur => switch (widget.slide.contentAnimation) {
    SlideContentAnimation.none        => const Duration(milliseconds: 100),
    SlideContentAnimation.typewriter  => const Duration(milliseconds: 2800),
    SlideContentAnimation.slideUp ||
    SlideContentAnimation.slideIn     => const Duration(milliseconds: 1200),
    SlideContentAnimation.fadeStagger => const Duration(milliseconds: 2000),
    SlideContentAnimation.float       => const Duration(milliseconds: 2200),
    SlideContentAnimation.zoomPulse   => const Duration(milliseconds: 3000),
    SlideContentAnimation.wipeReveal  => const Duration(milliseconds: 2200),
  };

  bool get _looping =>
      widget.slide.contentAnimation == SlideContentAnimation.float ||
      widget.slide.contentAnimation == SlideContentAnimation.zoomPulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _dur);
    if (widget.isActive) _play();
  }

  @override
  void didUpdateWidget(_AnimatedSlideCanvas old) {
    super.didUpdateWidget(old);
    if (!old.isActive && widget.isActive) {
      _ctrl.duration = _dur;
      _play();
    } else if (old.isActive && !widget.isActive) {
      _ctrl.stop();
      if (!_looping) _ctrl.reset();
    }
  }

  void _play() {
    if (_looping) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Layer helpers ─────────────────────────────────────────────────────────

  Widget _layerText(TextLayer layer, String text) {
    final style = slideLayerTextStyle(
      layer.fontStyle,
      fontSize: layer.fontSize,
      color: layer.color.color,
      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 12)],
    );
    Widget content = Text(text, style: style, textAlign: TextAlign.center);
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
    return Transform.rotate(
      angle: layer.rotation * 3.14159265 / 180.0,
      child: content,
    );
  }

  Alignment _align(TextLayer l) => Alignment(
        (l.x * 2 - 1).clamp(-0.95, 0.95),
        (l.y * 2 - 1).clamp(-0.95, 0.92),
      );

  Widget _staticText(TextLayer l) => Positioned.fill(
        child: Align(alignment: _align(l), child: _layerText(l, l.text)),
      );

  Widget _staticPhoto(PhotoLayer pl) {
    const w = 1280.0, h = 720.0;
    return Stack(children: [
      Positioned(
        left: (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * w,
        top: (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * h,
        width: pl.widthFraction * w,
        height: pl.heightFraction * h,
        child: Transform.rotate(
          angle: pl.rotation * 3.14159265 / 180.0,
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
        ),
      ),
    ]);
  }

  // ── Sorted layer builder ──────────────────────────────────────────────────

  List<Widget> _buildLayers() {
    final slide = widget.slide;
    final items = <({int z, bool isText, Object layer})>[];
    for (final l in slide.textLayers) {
      items.add((z: l.zOrder, isText: true, layer: l));
    }
    for (final p in slide.photoLayers) {
      items.add((z: p.zOrder, isText: false, layer: p));
    }
    items.sort((a, b) => a.z.compareTo(b.z));
    return [
      for (int i = 0; i < items.length; i++)
        if (items[i].isText)
          _animText(items[i].layer as TextLayer, i)
        else
          _animPhoto(items[i].layer as PhotoLayer, i),
    ];
  }

  // ── Text animation ────────────────────────────────────────────────────────

  Widget _animText(TextLayer layer, int idx) {
    final anim = widget.slide.contentAnimation;
    switch (anim) {
      case SlideContentAnimation.none:
        return _staticText(layer);

      case SlideContentAnimation.typewriter:
        final tIdx = widget.slide.textLayers.indexOf(layer);
        final total = widget.slide.textLayers.length;
        final start = total <= 1 ? 0.0 : tIdx / total * 0.45;
        final end = (start + (total <= 1 ? 0.95 : 0.55)).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0);
            final n = (layer.text.length * t).round().clamp(0, layer.text.length);
            return Positioned.fill(
              child: Opacity(
                opacity: t > 0 ? 1.0 : 0.0,
                child: Align(
                  alignment: _align(layer),
                  child: _layerText(layer, layer.text.substring(0, n)),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.slideUp:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final start = idx * 0.14;
            final end = (start + 0.5).clamp(0.0, 1.0);
            final t = Curves.easeOutCubic.transform(
                ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0));
            return Positioned.fill(
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 100 * (1 - t)),
                  child: Align(alignment: _align(layer), child: _layerText(layer, layer.text)),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.slideIn:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final start = idx * 0.14;
            final end = (start + 0.5).clamp(0.0, 1.0);
            final t = Curves.easeOutCubic.transform(
                ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0));
            return Positioned.fill(
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(-200 * (1 - t), 0),
                  child: Align(alignment: _align(layer), child: _layerText(layer, layer.text)),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.fadeStagger:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final start = idx * 0.2;
            final end = (start + 0.4).clamp(0.0, 1.0);
            final t = ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0);
            return Positioned.fill(
              child: Opacity(
                opacity: t,
                child: Align(alignment: _align(layer), child: _layerText(layer, layer.text)),
              ),
            );
          },
        );

      case SlideContentAnimation.float:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            return Positioned.fill(
              child: Align(
                alignment: _align(layer),
                child: Transform.translate(
                  offset: Offset(0, -16 * t + 8),
                  child: _layerText(layer, layer.text),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.zoomPulse:
        return _staticText(layer);

      case SlideContentAnimation.wipeReveal:
        final tIdx = widget.slide.textLayers.indexOf(layer);
        final total = widget.slide.textLayers.length;
        final start = total <= 1 ? 0.0 : tIdx / total * 0.5;
        final end = (start + (total <= 1 ? 1.0 : 0.5 / total + 0.5)).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = Curves.easeOut.transform(
                ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0));
            return Positioned.fill(
              child: Align(
                alignment: _align(layer),
                child: ClipRect(
                  clipper: _WipeRevealClipper(t),
                  child: _layerText(layer, layer.text),
                ),
              ),
            );
          },
        );
    }
  }

  // ── Photo animation ───────────────────────────────────────────────────────

  Widget _animPhoto(PhotoLayer pl, int idx) {
    const w = 1280.0, h = 720.0;
    final left = (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * w;
    final top  = (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * h;
    final pw   = pl.widthFraction * w;
    final ph   = pl.heightFraction * h;

    final photo = Transform.rotate(
      angle: pl.rotation * 3.14159265 / 180.0,
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

    switch (widget.slide.contentAnimation) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.typewriter:
      case SlideContentAnimation.wipeReveal:
        return _staticPhoto(pl);

      case SlideContentAnimation.slideUp:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final start = idx * 0.14;
            final end = (start + 0.5).clamp(0.0, 1.0);
            final t = Curves.easeOutCubic.transform(
                ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0));
            return Stack(children: [
              Positioned(
                left: left, top: top + 100 * (1 - t),
                width: pw, height: ph,
                child: Opacity(opacity: t, child: child),
              ),
            ]);
          },
          child: photo,
        );

      case SlideContentAnimation.slideIn:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final start = idx * 0.14;
            final end = (start + 0.5).clamp(0.0, 1.0);
            final t = Curves.easeOutCubic.transform(
                ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0));
            return Stack(children: [
              Positioned(
                left: left - 200 * (1 - t), top: top,
                width: pw, height: ph,
                child: Opacity(opacity: t, child: child),
              ),
            ]);
          },
          child: photo,
        );

      case SlideContentAnimation.fadeStagger:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final start = idx * 0.2;
            final end = (start + 0.4).clamp(0.0, 1.0);
            final t = ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0);
            return Stack(children: [
              Positioned(
                left: left, top: top, width: pw, height: ph,
                child: Opacity(opacity: t, child: child),
              ),
            ]);
          },
          child: photo,
        );

      case SlideContentAnimation.float:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            final dy = -16 * t + 8;
            return Stack(children: [
              Positioned(
                left: left, top: top + dy, width: pw, height: ph,
                child: child!,
              ),
            ]);
          },
          child: photo,
        );

      case SlideContentAnimation.zoomPulse:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            final scale = 1.0 + 0.08 * t;
            final dw = pw * (scale - 1) / 2;
            final dh = ph * (scale - 1) / 2;
            return Stack(children: [
              Positioned(
                left: left - dw, top: top - dh,
                width: pw * scale, height: ph * scale,
                child: child!,
              ),
            ]);
          },
          child: photo,
        );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 1280,
              height: 720,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SlidePhotoLayer(
                    slide: widget.slide,
                    kenBurnsController: widget.kenBurnsController,
                  ),
                  _gradientOverlay(),
                  buildSlideOverlay(widget.slide.overlay),
                  ..._buildLayers(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WipeRevealClipper extends CustomClipper<Rect> {
  const _WipeRevealClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_WipeRevealClipper old) => old.progress != progress;
}

/// Handles single-photo (with ken-burns) and multi-photo strip animation.
class _SlidePhotoLayer extends StatefulWidget {
  const _SlidePhotoLayer({
    required this.slide,
    required this.kenBurnsController,
  });

  final Slide slide;
  final AnimationController kenBurnsController;

  @override
  State<_SlidePhotoLayer> createState() => _SlidePhotoLayerState();
}

class _SlidePhotoLayerState extends State<_SlidePhotoLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _stripController;

  @override
  void initState() {
    super.initState();
    _stripController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.slide.durationSeconds),
    );
    if (widget.slide.layout != SlideLayout.single) {
      _stripController.forward();
    }
  }

  @override
  void dispose() {
    _stripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;

    if (slide.imagePath == null && slide.layout == SlideLayout.single) {
      return ColoredBox(color: Color(slide.backgroundColor));
    }

    if (slide.layout != SlideLayout.single) {
      return _buildStrip(slide);
    }

    // Single layout
    return _buildSinglePhoto(slide);
  }

  Widget _buildSinglePhoto(Slide slide) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      Widget photo = buildShapedPhoto(
        imagePath: slide.imagePath,
        shape: slide.photoShape,
        frame: slide.photoFrame,
        fit: BoxFit.contain,
        colorFilter: slide.photoFilter.colorFilter,
      );

      Widget positioned = ColoredBox(
        color: Color(slide.backgroundColor),
        child: ClipRect(
          child: Transform.translate(
            offset: Offset(slide.photoOffsetX * w, slide.photoOffsetY * h),
            child: Transform.scale(scale: slide.photoScale, child: photo),
          ),
        ),
      );

      if (slide.transition == TransitionEffect.kenBurns) {
        return AnimatedBuilder(
          animation: widget.kenBurnsController,
          builder: (context, child) {
            final scale = 1.0 + 0.08 * widget.kenBurnsController.value;
            final dx = 0.03 * (widget.kenBurnsController.value - 0.5);
            return Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Transform.translate(
                  offset: Offset(dx * 200, 0), child: child),
            );
          },
          child: positioned,
        );
      }
      return positioned;
    });
  }

  Widget _buildStrip(Slide slide) {
    final photos = [slide.imagePath, slide.imagePath2];
    if (slide.layout == SlideLayout.strip3) photos.add(slide.imagePath3);
    final n = photos.length;

    return ClipRect(
      child: AnimatedBuilder(
        animation: _stripController,
        builder: (context, _) {
          return LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final offset = _stripController.value * (n - 1) * w;
            return Transform.translate(
              offset: Offset(-offset, 0),
              child: Row(
                children: photos.map((path) {
                  return SizedBox(
                    width: w,
                    height: h,
                    child: buildShapedPhoto(
                      imagePath: path,
                      shape: slide.photoShape,
                      frame: slide.photoFrame,
                      fit: BoxFit.cover,
                      colorFilter: slide.photoFilter.colorFilter,
                    ),
                  );
                }).toList(),
              ),
            );
          });
        },
      ),
    );
  }

}

