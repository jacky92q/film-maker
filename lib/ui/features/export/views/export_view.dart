import 'dart:io';
import 'dart:ui' as ui;

import 'package:film_maker/data/services/video_export_service.dart';
import 'package:film_maker/l10n/app_strings.dart';
import 'package:film_maker/l10n/locale_controller.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/core/film_canvas.dart';
import 'package:film_maker/ui/core/responsive.dart';
import 'package:film_maker/ui/features/export/view_models/export_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class ExportView extends StatefulWidget {
  const ExportView({super.key, required this.viewModel});

  final ExportViewModel viewModel;

  @override
  State<ExportView> createState() => _ExportViewState();
}

class _ExportViewState extends State<ExportView> with TickerProviderStateMixin {
  // ── Capture state ─────────────────────────────────────────────────────────
  final _captureKey    = GlobalKey();
  final _filmController = FilmCanvasController();
  OverlayEntry? _canvasOverlay;

  Ticker?            _exportTicker;
  VideoExportService? _exportService;

  bool _cancelled  = false;
  bool _filmDone   = false;
  bool _finalizing = false;
  bool _capturing  = false;

  int _lastCapturedFrame = -1;
  int _totalFrames       = 0;
  int _doneFrames        = 0;

  static const _fps = 30;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onVmChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onVmChange);
    _exportTicker?.stop();
    _exportService?.cancelExport();
    _canvasOverlay?.remove();
    _filmController.dispose();
    super.dispose();
  }

  void _onVmChange() {
    if (widget.viewModel.isExporting && _canvasOverlay == null) {
      _startExport();
    }
  }

  // ── Off-screen canvas ─────────────────────────────────────────────────────

  void _installCanvas() {
    final orientation = widget.viewModel.project.orientation;
    _canvasOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: -99999,
        top: -99999,
        width: orientation.canvasWidth,
        height: orientation.canvasHeight,
        child: Material(
          child: RepaintBoundary(
            key: _captureKey,
            child: FilmCanvas(
              project: widget.viewModel.project,
              controller: _filmController,
              autoPlay: false,
              onComplete: _onFilmComplete,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_canvasOverlay!);
  }

  void _removeCanvas() {
    _canvasOverlay?.remove();
    _canvasOverlay = null;
  }

  // ── Export entry point ────────────────────────────────────────────────────

  Future<void> _startExport() async {
    _cancelled  = false;
    _filmDone   = false;
    _finalizing = false;
    _capturing  = false;
    _lastCapturedFrame = -1;
    _doneFrames        = 0;

    final project = widget.viewModel.project;
    if (project.slides.isEmpty) {
      widget.viewModel.failExport(L10n.s.noSlidesToExport);
      return;
    }

    _totalFrames = project.slides.fold<int>(
      0, (s, sl) => s + sl.durationSeconds * _fps,
    );

    try {
      final res = widget.viewModel.resolution;
      // Portrait swaps the encoder dimensions so the output matches the canvas:
      // the captured frame is (canvasW × pixelRatio) by (canvasH × pixelRatio).
      final portrait = project.orientation.isPortrait;
      _exportService = VideoExportService();
      await _exportService!.startEncoder(
        width: portrait ? res.height : res.width,
        height: portrait ? res.width : res.height,
        fps: _fps,
        bitrateBps: res.bitrateBps,
      );

      _installCanvas();
      await SchedulerBinding.instance.endOfFrame; // one render pass

      // Decode every photo up front so the very first captured frames are sharp
      // (no late-loading flicker on slide 0). The off-screen canvas keeps the
      // rest warm; this guarantees the cache is primed before capture begins.
      await _precacheAllImages();
      if (_cancelled || !mounted) {
        _removeCanvas();
        return;
      }
      await SchedulerBinding.instance.endOfFrame;

      _filmController.play();
      _exportTicker = createTicker(_onExportTick);
      _exportTicker!.start();
    } catch (e) {
      _removeCanvas();
      if (mounted) widget.viewModel.failExport(e.toString());
    }
  }

  // ── Ticker callback ───────────────────────────────────────────────────────

  void _onExportTick(Duration elapsed) {
    if (_cancelled) {
      _exportTicker?.stop();
      return;
    }

    if (_filmDone && !_capturing && !_finalizing) {
      _exportTicker?.stop();
      _exportTicker = null;
      _finalizing = true;
      _doFinalize();
      return;
    }

    if (_capturing || _filmDone) return;

    final targetFrame = (elapsed.inMicroseconds * _fps / 1e6).floor();
    if (targetFrame <= _lastCapturedFrame) return;

    _capturing = true;
    _doCapture().then((_) {
      _lastCapturedFrame = targetFrame;
      _doneFrames++;
      _capturing = false;
      if (mounted && _totalFrames > 0) {
        widget.viewModel.updateProgress(_doneFrames / _totalFrames * 0.85);
      }
    }).catchError((Object e) {
      _capturing = false;
      if (!_cancelled && mounted) {
        _cancelled = true;
        _exportTicker?.stop();
        _removeCanvas();
        widget.viewModel.failExport(e.toString());
      }
    });
  }

  Future<void> _doCapture() async {
    final boundary = _captureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final res = widget.viewModel.resolution;
    final image = await boundary.toImage(pixelRatio: res.pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData != null) {
      await _exportService!.addFrame(byteData.buffer.asUint8List());
    }
  }

  void _onFilmComplete() => _filmDone = true;

  // Pre-decode every image used in the film into Flutter's image cache so the
  // FilmCanvas paints each photo instantly the moment its slide appears.
  Future<void> _precacheAllImages() async {
    final paths = <String>{};
    for (final slide in widget.viewModel.project.slides) {
      for (final p in [slide.imagePath, slide.imagePath2, slide.imagePath3]) {
        if (p != null && p.isNotEmpty) paths.add(p);
      }
      for (final pl in slide.photoLayers) {
        final p = pl.imagePath;
        if (p != null && p.isNotEmpty) paths.add(p);
      }
    }
    if (paths.isEmpty || !mounted) return;
    await Future.wait(paths.map((p) async {
      try {
        await precacheImage(FileImage(File(p)), context);
      } catch (_) {
        // Missing/unreadable file — skip; FilmCanvas shows its placeholder.
      }
    }));
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  Future<void> _shareVideo() async {
    final path = widget.viewModel.outputPath;
    if (path == null) return;
    try {
      await VideoExportService().shareVideo(
        path: path,
        title: widget.viewModel.project.title,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.s.shareError,
            style: const TextStyle(fontFamily: AppTheme.fontTheme),
          ),
          backgroundColor: AppTheme.textDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _doFinalize() async {
    try {
      if (mounted) widget.viewModel.updateProgress(0.9);
      final project  = widget.viewModel.project;
      final safeTitle = project.title.replaceAll(RegExp(r'[^\w가-힣]+'), '_');
      final path = await _exportService!.finalize(
        musicPath: project.musicPath,
        outputName: safeTitle,
      );
      _exportService = null;
      _removeCanvas();
      if (mounted) widget.viewModel.completeExport(path);
    } catch (e) {
      _removeCanvas();
      if (mounted) widget.viewModel.failExport(e.toString());
    }
  }

  void _cancelExport() {
    _cancelled = true;
    _exportTicker?.stop();
    _exportTicker = null;
    _exportService?.cancelExport();
    _exportService = null;
    _removeCanvas();
    widget.viewModel.reset();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(L10n.s.exportFilm),
        backgroundColor: AppTheme.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isExporting) return _buildExportingScreen();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: ResponsiveCenter(
              maxWidth: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  if (widget.viewModel.status == ExportStatus.idle) ...[
                    _buildResolutionPicker(),
                    const SizedBox(height: 32),
                    _buildExportButton(),
                  ] else if (widget.viewModel.isDone) ...[
                    _buildDone(context),
                  ] else if (widget.viewModel.status == ExportStatus.error) ...[
                    _buildError(context),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final project = widget.viewModel.project;
    final dur     = project.totalDurationSeconds;
    final durStr  = L10n.s.durationLabel(dur);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.movie_creation_outlined,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      L10n.s.readyToExport,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.textMid,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.line, height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.photo_library_outlined,
                label: L10n.s.slidesCount(project.slideCount),
              ),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: durStr,
              ),
              if (project.musicName != null)
                _InfoChip(
                  icon: Icons.music_note_outlined,
                  label: project.musicName!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Resolution picker ─────────────────────────────────────────────────────

  Widget _buildResolutionPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.s.outputQuality,
          style: const TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          L10n.s.outputQualitySub,
          style: const TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textMid,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        ...ExportResolution.values.map((res) {
          final selected = widget.viewModel.resolution == res;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => widget.viewModel.setResolution(res),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.07)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.line,
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textMid.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        color:
                            selected ? AppTheme.primary : Colors.transparent,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.label,
                            style: TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.textDark,
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _resDesc(res),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.textMid,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (res == ExportResolution.fullHd)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          L10n.s.recommended,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontTheme,
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _resDesc(ExportResolution res) => switch (res) {
        ExportResolution.hd     => L10n.s.resHdDesc,
        ExportResolution.fullHd => L10n.s.resFullHdDesc,
        ExportResolution.fourK  => L10n.s.res4kDesc,
      };

  // ── Export button ─────────────────────────────────────────────────────────

  Widget _buildExportButton() {
    final totalSec = widget.viewModel.project.totalDurationSeconds;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            icon: const Icon(Icons.movie_creation_outlined, size: 20),
            label: Text(L10n.s.exportToMp4),
            onPressed: widget.viewModel.startExport,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  color: AppTheme.primary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  L10n.s.estimatedTime(totalSec),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.textMid,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_alt_outlined,
                size: 13,
                color: AppTheme.textMid.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              L10n.s.savedToGallery,
              style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.textMid.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Exporting screen ──────────────────────────────────────────────────────

  Widget _buildExportingScreen() {
    final pct   = (widget.viewModel.progress * 100).round();
    final phase = _phaseLabel(widget.viewModel.progress);

    return Container(
      color: AppTheme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 148,
            height: 148,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: widget.viewModel.progress,
                    strokeWidth: 7,
                    backgroundColor: AppTheme.line,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.textDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      L10n.s.doneLabel,
                      style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.textMid.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text(
            L10n.s.renderingTitle,
            style: const TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phase,
            style: const TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.textMid,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.viewModel.progress,
              minHeight: 8,
              backgroundColor: AppTheme.line,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _cancelExport,
            style: TextButton.styleFrom(foregroundColor: AppTheme.textMid),
            child: Text(
              L10n.s.cancelExport,
              style: const TextStyle(fontFamily: AppTheme.fontTheme, fontSize: 14),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _phaseLabel(double p) {
    if (p < 0.4)  return L10n.s.phaseCapturing;
    if (p < 0.75) return L10n.s.phaseCompositing;
    if (p < 0.9)  return L10n.s.phaseEncoding;
    return L10n.s.phaseSaving;
  }

  // ── Done ──────────────────────────────────────────────────────────────────

  Widget _buildDone(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.12),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.35), width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppTheme.primary, size: 44),
        ),
        const SizedBox(height: 20),
        Text(
          L10n.s.exportComplete,
          style: const TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          L10n.s.exportCompleteSub,
          style: const TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textMid,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.viewModel.outputPath != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined,
                    color: AppTheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.viewModel.outputPath!,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.textMid,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(L10n.s.share),
                onPressed: _shareVideo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(L10n.s.doneButton),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.viewModel.reset,
          style: TextButton.styleFrom(foregroundColor: AppTheme.textMid),
          child: Text(
            L10n.s.exportAgain,
            style: const TextStyle(fontFamily: AppTheme.fontTheme, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE85D4A).withValues(alpha: 0.1),
            border: Border.all(
                color: const Color(0xFFE85D4A).withValues(alpha: 0.3),
                width: 2),
          ),
          child:
              const Icon(Icons.error_outline, color: Color(0xFFE85D4A), size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          L10n.s.exportFailed,
          style: const TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.viewModel.error ?? L10n.s.exportFailedDefault,
          style: const TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textMid,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: widget.viewModel.reset,
            child: Text(L10n.s.tryAgain),
          ),
        ),
      ],
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.textMid,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
