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

    final totalFrames =
        project.slides.fold<int>(0, (s, sl) => s + sl.durationSeconds * fps);

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
        if (boundary == null) {
          throw Exception('Render boundary lost during export.');
        }

        final image = await boundary.toImage(pixelRatio: res.pixelRatio);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();

        if (byteData == null) throw Exception('Failed to capture frame $f.');

        await service.addFrame(byteData.buffer.asUint8List());
        done++;
        if (mounted) {
          widget.viewModel.updateProgress(done / totalFrames * 0.7);
        }
      }
    }

    if (_cancelled) {
      await service.cancelExport();
      return;
    }

    if (mounted) widget.viewModel.updateProgress(0.85);

    final safeTitle = project.title.replaceAll(RegExp(r'[^\w가-힣]+'), '_');

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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Export Film'),
        backgroundColor: AppTheme.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isExporting) {
            return _buildExportingScreen();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
          );
        },
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final project = widget.viewModel.project;
    final dur = project.totalDurationSeconds;
    final durStr = dur >= 60 ? '${dur ~/ 60}m ${dur % 60}s' : '${dur}s';

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
                    const Text(
                      'Ready to export',
                      style: TextStyle(
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
                label: '${project.slideCount} slides',
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
        const Text(
          'Output Quality',
          style: TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the resolution for your exported video',
          style: TextStyle(
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
                        color: selected ? AppTheme.primary : Colors.transparent,
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
                        child: const Text(
                          'Recommended',
                          style: TextStyle(
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
        ExportResolution.hd => 'Good for sharing on mobile',
        ExportResolution.fullHd => 'Great for TV and displays',
        ExportResolution.fourK => 'Best for cinema-quality output',
      };

  // ── Export button ─────────────────────────────────────────────────────────

  Widget _buildExportButton() {
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_alt_outlined,
                size: 13, color: AppTheme.textMid.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              'Video will be saved to your device gallery',
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

  // ── Exporting (full-screen progress) ─────────────────────────────────────

  Widget _buildExportingScreen() {
    final pct = (widget.viewModel.progress * 100).round();
    final phase = _phaseLabel(widget.viewModel.progress);

    return Container(
      color: AppTheme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated ring progress
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
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
                      'done',
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
          const Text(
            'Rendering your wedding film',
            style: TextStyle(
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
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.viewModel.progress,
              minHeight: 8,
              backgroundColor: AppTheme.line,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 32),
          // Cancel
          TextButton(
            onPressed: () {
              _cancelled = true;
              widget.viewModel.reset();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.textMid),
            child: const Text(
              'Cancel Export',
              style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _phaseLabel(double p) {
    if (p < 0.2) return 'Capturing frames…';
    if (p < 0.6) return 'Compositing slides…';
    if (p < 0.75) return 'Sending to encoder…';
    if (p < 0.95) return 'Encoding to MP4…';
    return 'Saving to gallery…';
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
        const Text(
          'Export Complete!',
          style: TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your wedding film has been saved to your gallery',
          style: TextStyle(
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
                label: const Text('Share'),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Share: ${widget.viewModel.outputPath}',
                      style:
                          const TextStyle(fontFamily: AppTheme.fontTheme),
                    ),
                    backgroundColor: AppTheme.textDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Done'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.viewModel.reset,
          style: TextButton.styleFrom(foregroundColor: AppTheme.textMid),
          child: const Text(
            'Export Again',
            style: TextStyle(fontFamily: AppTheme.fontTheme, fontSize: 13),
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
          child: const Icon(Icons.error_outline,
              color: Color(0xFFE85D4A), size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Export Failed',
          style: TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.viewModel.error ?? 'An unexpected error occurred.',
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
            child: const Text('Try Again'),
          ),
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
