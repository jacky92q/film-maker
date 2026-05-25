import 'dart:async';
import 'dart:io';

import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/preview/view_models/preview_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
                    child: Text('No slides',
                        style: TextStyle(color: AppTheme.subtleText)),
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
    Widget background;

    if (slide.imagePath != null) {
      background = Image.file(
        File(slide.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildGradientBg(),
      );
    } else {
      background = _buildGradientBg();
    }

    if (slide.transition == TransitionEffect.kenBurns) {
      background = AnimatedBuilder(
        animation: _kenBurnsController,
        builder: (context, child) {
          final scale = 1.0 +
              0.08 * _kenBurnsController.value;
          final dx = 0.03 *
              (_kenBurnsController.value - 0.5);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scaleByDouble(scale)
              ..translateByDouble(dx * 200, 0, 0),
            child: child,
          );
        },
        child: background,
      );
    }

    Widget slideWidget = AnimatedSwitcher(
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
            _buildTextOverlay(slide),
          ],
        ),
      ),
    );

    return slideWidget;
  }

  AnimatedSwitcherTransitionBuilder _buildTransition(
      TransitionEffect effect) {
    switch (effect) {
      case TransitionEffect.fade:
      case TransitionEffect.kenBurns:
        return AnimatedSwitcher.defaultTransitionBuilder;

      case TransitionEffect.slideLeft:
        return (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeInOut));
          return SlideTransition(position: offset, child: child);
        };

      case TransitionEffect.slideRight:
        return (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeInOut));
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
    }
  }

  Widget _buildGradientBg() {
    final index = widget.viewModel.currentIndex;
    final gradients = [
      [const Color(0xFF1A1208), const Color(0xFF0D0D0D)],
      [const Color(0xFF0D1A18), const Color(0xFF0A1414)],
      [const Color(0xFF1A0D1A), const Color(0xFF0D0D0D)],
    ];
    final colors = gradients[index % gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }

  Widget _buildTextOverlay(Slide slide) {
    if (slide.title.isEmpty && slide.subtitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 100),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slide.title.isNotEmpty)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  slide.title,
                  key: ValueKey('title_${slide.id}'),
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (slide.title.isNotEmpty && slide.subtitle.isNotEmpty)
              const SizedBox(height: 6),
            if (slide.subtitle.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                        color: AppTheme.gold, width: 2),
                  ),
                ),
                child: Text(
                  slide.subtitle,
                  style: GoogleFonts.lato(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
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
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 16,
          bottom: 16,
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
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
                onTap: widget.viewModel.isFirstSlide
                    ? null
                    : widget.viewModel.previousSlide,
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
                onTap: widget.viewModel.isLastSlide
                    ? null
                    : widget.viewModel.nextSlide,
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
        color: onTap == null
            ? color.withValues(alpha: 0.3)
            : color.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
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
            color: isCurrent
                ? AppTheme.gold
                : Colors.white.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}
