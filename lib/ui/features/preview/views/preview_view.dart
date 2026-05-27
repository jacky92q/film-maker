import 'dart:async';
import 'dart:ui' as ui;

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
  late AnimationController _transitionController;
  late AnimationController _kenBurnsController;
  Timer? _autoAdvanceTimer;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
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
    _transitionController.dispose();
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
    _transitionController.forward(from: 0);
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
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                final slide = widget.viewModel.currentSlide;
                if (slide == null) {
                  return const Center(
                    child: Text('No slides', style: TextStyle(color: AppTheme.subtleText)),
                  );
                }
                return _buildSlideView(slide);
              },
            ),
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

  Widget _buildSlideView(Slide slide) {
    final background = _SlidePhotoLayer(
      slide: slide,
      kenBurnsController: _kenBurnsController,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: _buildTransition(slide.transition),
      child: SizedBox.expand(
        key: ValueKey(slide.id),
        child: Stack(
          fit: StackFit.expand,
          children: [
            background,
            _buildGradientOverlay(),
            buildSlideOverlay(slide.overlay),
            _buildTextOverlay(slide),
            _buildPhotoLayers(slide),
          ],
        ),
      ),
    );
  }

  Widget _buildTextOverlay(Slide slide) {
    if (slide.textLayers.isEmpty) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: slide.textLayers.map((layer) {
        return Positioned.fill(
          child: Align(
            alignment: Alignment(
              (layer.x * 2 - 1).clamp(-0.92, 0.92),
              (layer.y * 2 - 1).clamp(-0.92, 0.92),
            ),
            child: _buildLayerText(layer),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLayerText(TextLayer layer) {
    final color = layer.color.color;
    final double fontSize = layer.fontSize;
    final shadows = [Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 12)];
    final style = slideLayerTextStyle(layer.fontStyle,
        fontSize: fontSize, color: color, shadows: shadows);

    final text = Text(layer.text, style: style, textAlign: TextAlign.center);

    Widget content;
    if (!layer.isSubtitle) {
      content = text;
    } else {
      content = IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: layer.barColor.color, width: 2.5)),
          ),
          child: text,
        ),
      );
    }

    return Transform.rotate(
      angle: layer.rotation * 3.14159265 / 180.0,
      child: content,
    );
  }

  Widget _buildPhotoLayers(Slide slide) {
    if (slide.photoLayers.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Stack(
        children: slide.photoLayers.map((pl) {
          return Positioned(
            left: (pl.x - pl.widthFraction / 2).clamp(0.0, 1.0) * w,
            top:  (pl.y - pl.heightFraction / 2).clamp(0.0, 1.0) * h,
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
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  AnimatedSwitcherTransitionBuilder _buildTransition(TransitionEffect effect) {
    switch (effect) {
      case TransitionEffect.fade:
      case TransitionEffect.kenBurns:
        return AnimatedSwitcher.defaultTransitionBuilder;

      case TransitionEffect.slideLeft:
        return (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
          return SlideTransition(position: offset, child: child);
        };

      case TransitionEffect.slideRight:
        return (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
          return SlideTransition(position: offset, child: child);
        };

      case TransitionEffect.zoomIn:
        return (child, animation) {
          final scale = Tween<double>(begin: 1.15, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          return ScaleTransition(
            scale: scale,
            child: FadeTransition(opacity: animation, child: child),
          );
        };

      case TransitionEffect.blurDissolve:
        return (child, animation) {
          final blurAnim = Tween<double>(begin: 14.0, end: 0.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          return AnimatedBuilder(
            animation: blurAnim,
            builder: (_, ch) => ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                  sigmaX: blurAnim.value, sigmaY: blurAnim.value),
              child: FadeTransition(opacity: animation, child: ch),
            ),
            child: child,
          );
        };

      case TransitionEffect.wipeLeft:
        return (child, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (_, ch) => ClipRect(
              clipper: _WipeClipper(animation.value, fromLeft: false),
              child: ch,
            ),
            child: child,
          );
        };

      case TransitionEffect.wipeRight:
        return (child, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (_, ch) => ClipRect(
              clipper: _WipeClipper(animation.value, fromLeft: true),
              child: ch,
            ),
            child: child,
          );
        };
    }
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
          stops: const [0.3, 1.0],
        ),
      ),
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
      return _buildGradientBg();
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

  Widget _buildGradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1208), Color(0xFF0D0D0D)],
        ),
      ),
    );
  }
}

class _WipeClipper extends CustomClipper<Rect> {
  const _WipeClipper(this.progress, {required this.fromLeft});
  final double progress;
  final bool fromLeft;

  @override
  Rect getClip(Size size) {
    if (fromLeft) {
      return Rect.fromLTWH(0, 0, size.width * progress, size.height);
    }
    return Rect.fromLTWH(
      size.width * (1 - progress), 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_WipeClipper old) => old.progress != progress;
}
