import 'dart:ui' as ui;

import 'package:film_maker/data/services/video_export_service.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/export/view_models/export_view_model.dart';
import 'package:film_maker/ui/features/export/widgets/export_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class ExportView extends StatefulWidget {
  const ExportView({super.key, required this.viewModel});

  final ExportViewModel viewModel;

  @override
  State<ExportView> createState() => _ExportViewState();
}

class _ExportViewState extends State<ExportView> {
  final _captureKey = GlobalKey();
  final _renderNotifier = ValueNotifier<(Slide, double)>(_kDummy);
  OverlayEntry? _canvasOverlay;
  bool _cancelled = false;

  // Dummy placeholder before the first slide is set.
  static final _kDummy = (const Slide(id: '_'), 0.0);

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onVmChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onVmChange);
    _canvasOverlay?.remove();
    _renderNotifier.dispose();
    super.dispose();
  }

  void _onVmChange() {
    if (widget.viewModel.isExporting && _canvasOverlay == null) {
      _startExport();
    }
  }

  // ── Off-screen canvas overlay ─────────────────────────────────────────────

  void _installCanvas() {
    _canvasOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: -99999,
        top: -99999,
        width: ExportCanvas.kWidth,
        height: ExportCanvas.kHeight,
        child: Material(
          child: _RenderCanvas(
            captureKey: _captureKey,
            notifier: _renderNotifier,
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

  // ── Export loop ───────────────────────────────────────────────────────────

  Future<void> _startExport() async {
    _cancelled = false;
    final project = widget.viewModel.project;
    if (project.slides.isEmpty) {
      widget.viewModel.failExport('No slides to export.');
      return;
    }

    _renderNotifier.value = (project.slides.first, 0.0);
    _installCanvas();

    // One frame so the canvas paints before we start capturing.
    await SchedulerBinding.instance.endOfFrame;

    try {
      await _runExportLoop();
    } catch (e) {
      if (mounted) widget.viewModel.failExport(e.toString());
    } finally {
      _removeCanvas();
    }
  }

  Future<void> _runExportLoop() async {
    final project = widget.viewModel.project;
    final res = widget.viewModel.resolution;
    const fps = 30;

    final service = VideoExportService();
    await service.startEncoder(
      width: res.width,
      height: res.height,
      fps: fps,
      bitrateBps: res.bitrateBps,
    );

    final totalFrames = project.slides
        .fold<int>(0, (s, sl) => s + sl.durationSeconds * fps);

    int done = 0;

    for (final slide in project.slides) {
      if (_cancelled) break;
      final slideFrames = slide.durationSeconds * fps;

      for (int f = 0; f < slideFrames; f++) {
        if (_cancelled) break;
        final t = f / fps.toDouble();

        _renderNotifier.value = (slide, t);
        await SchedulerBinding.instance.endOfFrame;

        final boundary = _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) throw Exception('Render boundary lost during export.');

        final image = await boundary.toImage(pixelRatio: res.pixelRatio);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();

        if (byteData == null) throw Exception('Failed to capture frame $f.');

        // 70 % budget for capture, 30 % for native finalize
        await service.addFrame(byteData.buffer.asUint8List());
        done++;
        if (mounted) widget.viewModel.updateProgress(done / totalFrames * 0.7);
      }
    }

    if (_cancelled) {
      await service.cancelExport();
      return;
    }

    if (mounted) widget.viewModel.updateProgress(0.85);

    final safeTitle =
        project.title.replaceAll(RegExp(r'[^\w가-힣]+'), '_');

    final path = await service.finalize(
      musicPath: project.musicPath,
      outputName: safeTitle,
    );

    if (mounted) widget.viewModel.completeExport(path);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Export Film',
          style: TextStyle(
              fontFamily: AppTheme.fontTheme, color: AppTheme.cream),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(),
                const SizedBox(height: 28),
                if (widget.viewModel.status == ExportStatus.idle) ...[
                  _buildResolutionPicker(),
                  const SizedBox(height: 32),
                  _buildExportButton(context),
                ] else if (widget.viewModel.isExporting) ...[
                  _buildExporting(),
                ] else if (widget.viewModel.isDone) ...[
                  _buildDone(context),
                ] else if (widget.viewModel.status == ExportStatus.error) ...[
                  _buildError(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    final project = widget.viewModel.project;
    final dur = project.totalDurationSeconds;
    final durStr = dur >= 60
        ? '${dur ~/ 60}m ${dur % 60}s'
        : '${dur}s';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_creation_outlined,
                  color: AppTheme.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project.title,
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 14),
          Row(
            children: [
              _Chip(icon: Icons.photo_library_outlined,
                  label: '${project.slideCount} slides'),
              const SizedBox(width: 10),
              _Chip(icon: Icons.timer_outlined, label: durStr),
              if (project.musicName != null) ...[
                const SizedBox(width: 10),
                _Chip(
                    icon: Icons.music_note_outlined,
                    label: project.musicName!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 18, color: AppTheme.gold),
            const SizedBox(width: 10),
            Text(
              'Output Quality',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.cream,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...ExportResolution.values.map((res) {
          final selected = widget.viewModel.resolution == res;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => widget.viewModel.setResolution(res),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.gold.withValues(alpha: 0.1)
                      : AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppTheme.gold : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppTheme.gold
                              : AppTheme.subtleText,
                          width: 2,
                        ),
                        color: selected
                            ? AppTheme.gold
                            : Colors.transparent,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: AppTheme.darkBg, size: 12)
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
                                color: AppTheme.cream,
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400),
                          ),
                          Text(
                            _resDesc(res),
                            style: TextStyle(
                                fontFamily: AppTheme.fontTheme,
                                color: AppTheme.subtleText,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (res == ExportResolution.fullHd)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Recommended',
                          style: TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.gold,
                              fontSize: 10),
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
        ExportResolution.hd => 'Good for sharing on mobile',
        ExportResolution.fullHd => 'Great for TV and displays',
        ExportResolution.fourK => 'Best for cinema-quality output',
      };

  Widget _buildExportButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            icon: const Icon(Icons.movie_creation_outlined, size: 20),
            label: const Text('Export to MP4'),
            onPressed: widget.viewModel.startExport,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The video will be saved to your device',
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.subtleText,
              fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExporting() {
    final pct = (widget.viewModel.progress * 100).round();
    final phase = _phaseLabel(widget.viewModel.progress);
    return Column(
      children: [
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: widget.viewModel.progress,
                strokeWidth: 6,
                backgroundColor: AppTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.gold),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.cream,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Rendering your wedding film…',
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.cream,
              fontSize: 18,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          phase,
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.subtleText,
              fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.viewModel.progress,
            minHeight: 6,
            backgroundColor: AppTheme.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.gold),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            _cancelled = true;
            widget.viewModel.reset();
          },
          child: Text('Cancel',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.subtleText)),
        ),
      ],
    );
  }

  String _phaseLabel(double p) {
    if (p < 0.2) return 'Capturing frames…';
    if (p < 0.6) return 'Compositing slides…';
    if (p < 0.75) return 'Sending to encoder…';
    if (p < 0.95) return 'Encoding to MP4…';
    return 'Saving to gallery…';
  }

  Widget _buildDone(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.gold.withValues(alpha: 0.15),
            border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.4), width: 2),
          ),
          child:
              const Icon(Icons.check_rounded, color: AppTheme.gold, size: 52),
        ),
        const SizedBox(height: 20),
        Text(
          'Export Complete!',
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.cream,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your wedding film is ready',
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.subtleText,
              fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (widget.viewModel.outputPath != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined,
                    color: AppTheme.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.viewModel.outputPath!,
                    style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.subtleText,
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share'),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share: ${widget.viewModel.outputPath}',
                        style: TextStyle(fontFamily: AppTheme.fontTheme)),
                    backgroundColor: AppTheme.darkSurface,
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.save_alt_outlined, size: 18),
                label: const Text('Done'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.viewModel.reset,
          child: Text('Export Again',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.subtleText)),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.error_outline,
            color: Color(0xFFFF6B6B), size: 64),
        const SizedBox(height: 16),
        Text(
          widget.viewModel.error ?? 'Export failed',
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.cream,
              fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.viewModel.reset,
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

// ── Off-screen render canvas ──────────────────────────────────────────────────

class _RenderCanvas extends StatefulWidget {
  const _RenderCanvas({required this.captureKey, required this.notifier});

  final GlobalKey captureKey;
  final ValueNotifier<(Slide, double)> notifier;

  @override
  State<_RenderCanvas> createState() => _RenderCanvasState();
}

class _RenderCanvasState extends State<_RenderCanvas> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotify);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final (slide, t) = widget.notifier.value;
    return RepaintBoundary(
      key: widget.captureKey,
      child: ExportCanvas(slide: slide, slideTimeSeconds: t),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.gold, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.subtleText,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
