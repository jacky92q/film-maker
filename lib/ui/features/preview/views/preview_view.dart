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
    if (_showControls) {
      _hideControlsTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      setState(() => _showControls = true);
      _scheduleHideControls();
    }
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
                isPlaying: widget.viewModel.isPlaying,
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
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 4, right: 16, bottom: 24,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                widget.viewModel.project.title,
                style: const TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        final isPlaying = widget.viewModel.isPlaying;
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavButton(
                icon: Icons.skip_previous_rounded,
                onTap: widget.viewModel.isFirstSlide
                    ? null
                    : widget.viewModel.previousSlide,
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: _onPlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(color: AppTheme.gold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 38,
                    color: AppTheme.gold,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              _buildNavButton(
                icon: Icons.skip_next_rounded,
                onTap: widget.viewModel.isLastSlide
                    ? null
                    : widget.viewModel.nextSlide,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.3 : 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.25),
        ),
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
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        padding: EdgeInsets.only(
          left: 28, right: 28,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          top: 40,
        ),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final current = widget.viewModel.currentIndex + 1;
            final total = widget.viewModel.project.slides.length;
            return Column(
              children: [
                _buildSlideIndicators(),
                const SizedBox(height: 14),
                _buildProgressBar(),
                const SizedBox(height: 8),
                Text(
                  '$current / $total',
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: widget.viewModel.progress,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
        minHeight: 4,
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
          duration: const Duration(milliseconds: 250),
          width: isCurrent ? 24 : 6,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isCurrent
                ? AppTheme.gold
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated slide canvas — pre-rendered, visibility driven by AnimatedOpacity.
// Each layer widget has its own AnimationController for independent animations.
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

Duration _durForAnim(SlideContentAnimation a) => switch (a) {
  SlideContentAnimation.none        => const Duration(milliseconds: 100),
  SlideContentAnimation.typewriter  => const Duration(milliseconds: 2800),
  SlideContentAnimation.slideUp ||
  SlideContentAnimation.slideIn     => const Duration(milliseconds: 1200),
  SlideContentAnimation.fadeStagger => const Duration(milliseconds: 2000),
  SlideContentAnimation.float       => const Duration(milliseconds: 2200),
  SlideContentAnimation.zoomPulse   => const Duration(milliseconds: 3000),
  SlideContentAnimation.wipeReveal  => const Duration(milliseconds: 2200),
};

Alignment _textLayerAlign(TextLayer l) => Alignment(
  (l.x * 2 - 1).clamp(-0.95, 0.95),
  (l.y * 2 - 1).clamp(-0.95, 0.92),
);

Widget _buildLayerText(TextLayer layer, {String? text}) {
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
  return Transform.rotate(
    angle: layer.rotation * 3.14159265 / 180.0,
    child: content,
  );
}

class _AnimatedSlideCanvas extends StatelessWidget {
  const _AnimatedSlideCanvas({
    super.key,
    required this.slide,
    required this.kenBurnsController,
    required this.isActive,
    required this.isPlaying,
  });
  final Slide slide;
  final AnimationController kenBurnsController;
  final bool isActive;
  final bool isPlaying;

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
          _AnimatedTextLayer(
            key: ValueKey((item.layer as TextLayer).id),
            layer: item.layer as TextLayer,
            isActive: isActive,
            isPlaying: isPlaying,
          )
        else
          _AnimatedPhotoLayer(
            key: ValueKey((item.layer as PhotoLayer).id),
            pl: item.layer as PhotoLayer,
            isActive: isActive,
            isPlaying: isPlaying,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.0,
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
                  _SlidePhotoLayer(slide: slide, kenBurnsController: kenBurnsController, isActive: isActive, isPlaying: isPlaying),
                  _gradientOverlay(),
                  buildSlideOverlay(slide.overlay),
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

// ── Per-layer animated text widget ───────────────────────────────────────────

class _AnimatedTextLayer extends StatefulWidget {
  const _AnimatedTextLayer({super.key, required this.layer, required this.isActive, required this.isPlaying});
  final TextLayer layer;
  final bool isActive;
  final bool isPlaying;

  @override
  State<_AnimatedTextLayer> createState() => _AnimatedTextLayerState();
}

class _AnimatedTextLayerState extends State<_AnimatedTextLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  bool get _looping => widget.layer.contentAnimation == SlideContentAnimation.float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _durForAnim(widget.layer.contentAnimation));
  }

  @override
  void didUpdateWidget(_AnimatedTextLayer old) {
    super.didUpdateWidget(old);
    final wasGoing = old.isActive && old.isPlaying;
    final isGoing = widget.isActive && widget.isPlaying;
    if (!wasGoing && isGoing) {
      _ctrl.duration = _durForAnim(widget.layer.contentAnimation);
      _play();
    } else if (wasGoing && !isGoing) {
      _ctrl.stop();
      if (!_looping) _ctrl.reset();
    }
  }

  void _play() => _looping ? _ctrl.repeat(reverse: true) : _ctrl.forward(from: 0);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    switch (layer.contentAnimation) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.zoomPulse:
        return Positioned.fill(
          child: Align(alignment: _textLayerAlign(layer), child: _buildLayerText(layer)),
        );

      case SlideContentAnimation.typewriter:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            final n = (layer.text.length * t).round().clamp(0, layer.text.length);
            return Positioned.fill(
              child: Opacity(
                opacity: t > 0 ? 1.0 : 0.0,
                child: Align(
                  alignment: _textLayerAlign(layer),
                  child: _buildLayerText(layer, text: layer.text.substring(0, n)),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.slideUp:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = Curves.easeOutCubic.transform(_ctrl.value);
            return Positioned.fill(
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 100 * (1 - t)),
                  child: Align(alignment: _textLayerAlign(layer), child: _buildLayerText(layer)),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.slideIn:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = Curves.easeOutCubic.transform(_ctrl.value);
            return Positioned.fill(
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(-200 * (1 - t), 0),
                  child: Align(alignment: _textLayerAlign(layer), child: _buildLayerText(layer)),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.fadeStagger:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Positioned.fill(
            child: Opacity(
              opacity: _ctrl.value,
              child: Align(alignment: _textLayerAlign(layer), child: _buildLayerText(layer)),
            ),
          ),
        );

      case SlideContentAnimation.float:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            return Positioned.fill(
              child: Align(
                alignment: _textLayerAlign(layer),
                child: Transform.translate(
                  offset: Offset(0, -16 * t + 8),
                  child: _buildLayerText(layer),
                ),
              ),
            );
          },
        );

      case SlideContentAnimation.wipeReveal:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = Curves.easeOut.transform(_ctrl.value);
            return Positioned.fill(
              child: Align(
                alignment: _textLayerAlign(layer),
                child: ClipRect(
                  clipper: _WipeRevealClipper(t),
                  child: _buildLayerText(layer),
                ),
              ),
            );
          },
        );
    }
  }
}

// ── Per-layer animated photo widget ──────────────────────────────────────────

class _AnimatedPhotoLayer extends StatefulWidget {
  const _AnimatedPhotoLayer({super.key, required this.pl, required this.isActive, required this.isPlaying});
  final PhotoLayer pl;
  final bool isActive;
  final bool isPlaying;

  @override
  State<_AnimatedPhotoLayer> createState() => _AnimatedPhotoLayerState();
}

class _AnimatedPhotoLayerState extends State<_AnimatedPhotoLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  bool get _looping =>
      widget.pl.contentAnimation == SlideContentAnimation.float ||
      widget.pl.contentAnimation == SlideContentAnimation.zoomPulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _durForAnim(widget.pl.contentAnimation));
  }

  @override
  void didUpdateWidget(_AnimatedPhotoLayer old) {
    super.didUpdateWidget(old);
    final wasGoing = old.isActive && old.isPlaying;
    final isGoing = widget.isActive && widget.isPlaying;
    if (!wasGoing && isGoing) {
      _ctrl.duration = _durForAnim(widget.pl.contentAnimation);
      _play();
    } else if (wasGoing && !isGoing) {
      _ctrl.stop();
      if (!_looping) _ctrl.reset();
    }
  }

  void _play() => _looping ? _ctrl.repeat(reverse: true) : _ctrl.forward(from: 0);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _photoWidget() {
    final pl = widget.pl;
    return Transform.rotate(
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
  }

  @override
  Widget build(BuildContext context) {
    final pl = widget.pl;
    const w = 1280.0, h = 720.0;
    final left = (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * w;
    final top  = (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * h;
    final pw   = pl.widthFraction * w;
    final ph   = pl.heightFraction * h;

    switch (pl.contentAnimation) {
      case SlideContentAnimation.none:
      case SlideContentAnimation.typewriter:
      case SlideContentAnimation.wipeReveal:
        return Stack(children: [
          Positioned(left: left, top: top, width: pw, height: ph, child: _photoWidget()),
        ]);

      case SlideContentAnimation.slideUp:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final t = Curves.easeOutCubic.transform(_ctrl.value);
            return Stack(children: [
              Positioned(
                left: left, top: top + 100 * (1 - t), width: pw, height: ph,
                child: Opacity(opacity: t, child: child),
              ),
            ]);
          },
          child: _photoWidget(),
        );

      case SlideContentAnimation.slideIn:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final t = Curves.easeOutCubic.transform(_ctrl.value);
            return Stack(children: [
              Positioned(
                left: left - 200 * (1 - t), top: top, width: pw, height: ph,
                child: Opacity(opacity: t, child: child),
              ),
            ]);
          },
          child: _photoWidget(),
        );

      case SlideContentAnimation.fadeStagger:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Stack(children: [
            Positioned(
              left: left, top: top, width: pw, height: ph,
              child: Opacity(opacity: _ctrl.value, child: child),
            ),
          ]),
          child: _photoWidget(),
        );

      case SlideContentAnimation.float:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final dy = -16 * Curves.easeInOut.transform(_ctrl.value) + 8;
            return Stack(children: [
              Positioned(left: left, top: top + dy, width: pw, height: ph, child: child!),
            ]);
          },
          child: _photoWidget(),
        );

      case SlideContentAnimation.zoomPulse:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final scale = 1.0 + 0.08 * Curves.easeInOut.transform(_ctrl.value);
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
          child: _photoWidget(),
        );
    }
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
    required this.isActive,
    required this.isPlaying,
  });

  final Slide slide;
  final AnimationController kenBurnsController;
  final bool isActive;
  final bool isPlaying;

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
  }

  @override
  void didUpdateWidget(_SlidePhotoLayer old) {
    super.didUpdateWidget(old);
    if (widget.slide.layout == SlideLayout.single) return;
    final wasGoing = old.isActive && old.isPlaying;
    final isGoing = widget.isActive && widget.isPlaying;
    if (!wasGoing && isGoing) {
      _stripController.forward();
    } else if (wasGoing && !isGoing) {
      _stripController.stop();
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

