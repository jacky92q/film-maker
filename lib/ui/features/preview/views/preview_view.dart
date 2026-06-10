import 'dart:async';

import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/core/film_canvas.dart';
import 'package:film_maker/ui/features/preview/view_models/preview_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PreviewView extends StatefulWidget {
  const PreviewView({super.key, required this.viewModel});

  final PreviewViewModel viewModel;

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  final _filmController = FilmCanvasController();
  bool _showControls = true;
  Timer? _hideControlsTimer;
  int _currentIndex = 0;
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _filmController.addListener(_onControllerChanged);
    _scheduleHideControls();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _filmController.removeListener(_onControllerChanged);
    _filmController.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() => _currentIndex = _filmController.currentIndex);
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
    _filmController.toggle();
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.viewModel.project.slides.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTapScreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.viewModel.project.orientation.aspectRatio,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: FilmCanvas(
                    project: widget.viewModel.project,
                    controller: _filmController,
                    autoPlay: true,
                    onSlideChanged: (i) {
                      if (mounted) setState(() => _currentIndex = i);
                    },
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildControls(total),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(int total) {
    return Stack(
      children: [
        _buildTopBar(),
        _buildCenterControls(),
        _buildBottomBar(total),
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
                  color: AppTheme.primary,
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
      listenable: _filmController,
      builder: (context, _) => Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavButton(
              icon: Icons.skip_previous_rounded,
              onTap: _filmController.isFirst ? null : _filmController.previous,
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
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _filmController.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 38,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 32),
            _buildNavButton(
              icon: Icons.skip_next_rounded,
              onTap: _filmController.isLast ? null : _filmController.next,
            ),
          ],
        ),
      ),
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

  Widget _buildBottomBar(int total) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.88),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 40,
        ),
        child: ListenableBuilder(
          listenable: _filmController,
          builder: (context, _) {
            final totalSec = _filmController.totalSeconds;
            final rawElapsed = _isDragging ? _dragValue : _filmController.elapsedSeconds;
            final elapsed = totalSec > 0 ? rawElapsed.clamp(0.0, totalSec) : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Slide indicator dots
                _buildSlideIndicators(total),
                const SizedBox(height: 6),
                // Scrubber row: [elapsed] ----●---- [total]
                Row(
                  children: [
                    _buildTimeLabel(elapsed),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16),
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.22),
                          thumbColor: AppTheme.primary,
                          overlayColor:
                              AppTheme.primary.withValues(alpha: 0.25),
                        ),
                        child: Slider(
                          value: elapsed,
                          min: 0,
                          max: totalSec > 0 ? totalSec : 1,
                          onChanged: totalSec > 0
                              ? (v) {
                                  _hideControlsTimer?.cancel();
                                  setState(() {
                                    _isDragging = true;
                                    _dragValue = v;
                                  });
                                }
                              : null,
                          onChangeEnd: totalSec > 0
                              ? (v) {
                                  _filmController.seekToSeconds(v);
                                  setState(() => _isDragging = false);
                                  _scheduleHideControls();
                                }
                              : null,
                        ),
                      ),
                    ),
                    _buildTimeLabel(totalSec),
                  ],
                ),
                const SizedBox(height: 2),
                // Slide counter
                Text(
                  '${_currentIndex + 1} / $total',
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: Colors.white.withValues(alpha: 0.4),
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

  Widget _buildTimeLabel(double seconds) {
    final s = seconds.round().clamp(0, 5999);
    final m = s ~/ 60;
    final sec = s % 60;
    return SizedBox(
      width: 36,
      child: Text(
        '$m:${sec.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontFamily: AppTheme.fontTheme,
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSlideIndicators(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isCurrent = i == _currentIndex;
        return GestureDetector(
          onTap: () {
            _filmController.seekToSlide(i);
            setState(() => _showControls = true);
            _scheduleHideControls();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isCurrent ? 24 : 6,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCurrent
                  ? AppTheme.primary
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
        );
      }),
    );
  }
}
