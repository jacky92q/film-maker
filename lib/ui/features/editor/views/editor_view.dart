import 'dart:io';

import 'package:film_maker/data/repositories/export_repository.dart';
import 'package:film_maker/ui/core/photo_frame_widget.dart';
import 'package:film_maker/ui/core/slide_overlay.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/app_routes.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/editor/view_models/editor_view_model.dart';
import 'package:film_maker/ui/features/export/view_models/export_view_model.dart';
import 'package:film_maker/ui/features/export/views/export_view.dart';
import 'package:film_maker/ui/features/preview/view_models/preview_view_model.dart';
import 'package:film_maker/ui/features/preview/views/preview_view.dart';
import 'package:flutter/material.dart';

// Returns the appropriate TextStyle for a given font style using bundled fonts.
TextStyle slideLayerTextStyle(
  SlideFontStyle font, {
  double fontSize = 20,
  Color color = Colors.white,
  FontWeight fontWeight = FontWeight.w600,
  List<Shadow>? shadows,
}) {
  final String family;
  final String koreanFamily;
  switch (font) {
    case SlideFontStyle.serif:
      family = 'PlayfairDisplay';
      koreanFamily = 'NotoSerifKR';
    case SlideFontStyle.sans:
      family = 'Lato';
      koreanFamily = 'NotoSansKR';
    case SlideFontStyle.script:
      family = 'DancingScript';
      koreanFamily = 'Gaegu';
    case SlideFontStyle.display:
      family = 'Cinzel';
      koreanFamily = 'BlackHanSans';
    case SlideFontStyle.elegant:
      family = 'EBGaramond';
      koreanFamily = 'GowunBatang';
    case SlideFontStyle.modern:
      family = 'Montserrat';
      koreanFamily = 'DoHyeon';
  }
  return TextStyle(
    fontFamily: family,
    fontFamilyFallback: [koreanFamily],
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    shadows: shadows,
  );
}

class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.viewModel,
    required this.exportRepository,
  });

  final EditorViewModel viewModel;
  final ExportRepository exportRepository;

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final _titleController = TextEditingController();
  bool _editingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.viewModel.project.title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!widget.viewModel.hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unsaved Changes',
            style: TextStyle(
                fontFamily: AppTheme.fontTheme, color: AppTheme.cream)),
        content: Text('Save your film before leaving?',
            style: TextStyle(
                fontFamily: AppTheme.fontTheme, color: AppTheme.subtleText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Discard',
                style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.subtleText)),
          ),
          TextButton(
            onPressed: () async {
              await widget.viewModel.saveProject();
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: Text('Save',
                style: TextStyle(
                    fontFamily: AppTheme.fontTheme, color: AppTheme.gold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openPreview() {
    Navigator.of(context).push(
      SlideUpPageRoute(
        builder: (_) => PreviewView(
          viewModel: PreviewViewModel(project: widget.viewModel.project),
        ),
      ),
    );
  }

  void _openExport() {
    Navigator.of(context).push(
      SlideUpPageRoute(
        builder: (_) => ExportView(
          viewModel: ExportViewModel(
            project: widget.viewModel.project,
            exportRepository: widget.exportRepository,
          ),
        ),
      ),
    );
  }

  void _showTemplatePickerForNewSlide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TemplatePicker(
        onSelect: (template) {
          widget.viewModel.addSlide(template: template);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showMusicPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MusicPickerSheet(
        currentMusicName: widget.viewModel.project.musicName,
        onSelect: (name) => widget.viewModel.setMusic('music_path', name),
        onRemove: () => widget.viewModel.setMusic(null, null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await _onWillPop();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop(widget.viewModel.project);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: _buildAppBar(),
        body: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final slide = widget.viewModel.selectedSlide;
            if (slide == null) {
              return const Center(
                child: Text('No slides',
                    style: TextStyle(color: AppTheme.subtleText)),
              );
            }
            return Column(
              children: [
                // 16:9 interactive canvas
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _SlideCanvas(viewModel: widget.viewModel),
                ),
                // Control row: photo, add text, music, delete slide
                _buildControlsRow(slide),
                // Adaptive edit panel (layer vs. slide level)
                Expanded(child: _buildEditPanel()),
                // Timeline
                _buildTimeline(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkBg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18),
        onPressed: () async {
          final canLeave = await _onWillPop();
          if (canLeave && mounted) {
            Navigator.of(context).pop(widget.viewModel.project);
          }
        },
      ),
      title: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (_editingTitle) {
            return TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.cream,
                  fontSize: 18),
              decoration: const InputDecoration(
                  border: InputBorder.none, contentPadding: EdgeInsets.zero),
              onSubmitted: (v) {
                widget.viewModel.updateProjectTitle(v.trim().isEmpty
                    ? widget.viewModel.project.title
                    : v.trim());
                setState(() => _editingTitle = false);
              },
            );
          }
          return GestureDetector(
            onTap: () {
              _titleController.text = widget.viewModel.project.title;
              setState(() => _editingTitle = true);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.viewModel.project.title.isEmpty
                        ? 'Untitled Film'
                        : widget.viewModel.project.title,
                    style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.cream,
                        fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined,
                    color: AppTheme.subtleText, size: 14),
              ],
            ),
          );
        },
      ),
      actions: [
        ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.viewModel.hasUnsavedChanges)
                IconButton(
                  tooltip: 'Save',
                  icon: widget.viewModel.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.gold),
                        )
                      : const Icon(Icons.save_outlined, color: AppTheme.gold),
                  onPressed: widget.viewModel.isSaving
                      ? null
                      : () => widget.viewModel.saveProject(),
                ),
              TextButton(
                onPressed: _openPreview,
                child: Text('Preview',
                    style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.gold,
                        fontSize: 13)),
              ),
              TextButton(
                onPressed: _openExport,
                child: Text('Export',
                    style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.cream,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Controls row ──────────────────────────────────────────────────────────

  Widget _buildControlsRow(Slide slide) {
    return Container(
      color: AppTheme.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _ControlButton(
            icon: Icons.photo_camera_outlined,
            label: 'Photo',
            onTap: widget.viewModel.pickImageForCurrentSlide,
          ),
          const SizedBox(width: 6),
          _ControlButton(
            icon: Icons.title,
            label: '+ Main',
            onTap: () => widget.viewModel.addTextLayer(isSubtitle: false),
          ),
          const SizedBox(width: 6),
          _ControlButton(
            icon: Icons.short_text,
            label: '+ Sub',
            onTap: () => widget.viewModel.addTextLayer(isSubtitle: true),
          ),
          const SizedBox(width: 6),
          _ControlButton(
            icon: Icons.music_note_outlined,
            label: widget.viewModel.project.musicName ?? 'Music',
            onTap: _showMusicPicker,
            highlighted: widget.viewModel.project.musicName != null,
          ),
          const Spacer(),
          if (widget.viewModel.project.slides.length > 1)
            IconButton(
              onPressed: widget.viewModel.deleteSelectedSlide,
              tooltip: 'Delete slide',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFFF6B6B), size: 20),
            ),
        ],
      ),
    );
  }

  // ── Adaptive edit panel ───────────────────────────────────────────────────

  Widget _buildEditPanel() {
    final layer = widget.viewModel.selectedLayer;
    if (layer != null) {
      return _LayerEditPanel(
        key: ValueKey(layer.id),
        layer: layer,
        onUpdate: widget.viewModel.updateTextLayer,
        onDelete: () => widget.viewModel.deleteTextLayer(layer.id),
      );
    }
    final slide = widget.viewModel.selectedSlide;
    if (slide == null) return const SizedBox.shrink();
    return _SlideEditPanel(slide: slide, viewModel: widget.viewModel);
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    return Container(
      height: 88,
      color: AppTheme.darkBg,
      child: Row(
        children: [
          _MusicTimelineButton(
            musicName: widget.viewModel.project.musicName,
            onTap: _showMusicPicker,
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              itemCount: widget.viewModel.project.slides.length + 1,
              itemBuilder: (context, index) {
                if (index == widget.viewModel.project.slides.length) {
                  return _AddSlideButton(onTap: _showTemplatePickerForNewSlide);
                }
                final slide = widget.viewModel.project.slides[index];
                return _SlideThumbnail(
                  slide: slide,
                  index: index,
                  isSelected: index == widget.viewModel.selectedSlideIndex,
                  onTap: () => widget.viewModel.selectSlide(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive slide canvas
// ─────────────────────────────────────────────────────────────────────────────

class _SlideCanvas extends StatefulWidget {
  const _SlideCanvas({required this.viewModel});
  final EditorViewModel viewModel;

  @override
  State<_SlideCanvas> createState() => _SlideCanvasState();
}

class _SlideCanvasState extends State<_SlideCanvas> {
  // Saved at gesture start so we compute absolute (not cumulative) deltas.
  double _scaleStart = 1.0;
  double _offsetXStart = 0.0;
  double _offsetYStart = 0.0;
  Offset _focalStart = Offset.zero;

  void _onPhotoScaleStart(ScaleStartDetails d) {
    final slide = widget.viewModel.selectedSlide!;
    _scaleStart = slide.photoScale;
    _offsetXStart = slide.photoOffsetX;
    _offsetYStart = slide.photoOffsetY;
    _focalStart = d.localFocalPoint;
  }

  void _onPhotoScaleUpdate(ScaleUpdateDetails d, double w, double h) {
    final newScale = (_scaleStart * d.scale).clamp(0.1, 4.0);
    final delta = d.localFocalPoint - _focalStart;
    widget.viewModel.updatePhotoTransform(
      scale: newScale,
      offsetX: _offsetXStart + delta.dx / w,
      offsetY: _offsetYStart + delta.dy / h,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.viewModel.selectedSlide!;
    final selectedLayerId = widget.viewModel.selectedLayerId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Build photo widget with pan/zoom transform applied.
        Widget background;
        bool hasPhoto = slide.imagePath != null;
        if (hasPhoto) {
          Widget photoContent;
          if (slide.layout != SlideLayout.single) {
            // Editor canvas strip preview (static, no animation)
            photoContent = ClipRect(
              child: Row(
                children: [
                  Expanded(child: buildShapedPhoto(
                    imagePath: slide.imagePath,
                    shape: slide.photoShape,
                    frame: slide.photoFrame,
                    colorFilter: slide.photoFilter.colorFilter,
                  )),
                  if (slide.layout == SlideLayout.strip2 || slide.layout == SlideLayout.strip3)
                    Expanded(child: buildShapedPhoto(
                      imagePath: slide.imagePath2,
                      shape: slide.photoShape,
                      frame: slide.photoFrame,
                      colorFilter: slide.photoFilter.colorFilter,
                    )),
                  if (slide.layout == SlideLayout.strip3)
                    Expanded(child: buildShapedPhoto(
                      imagePath: slide.imagePath3,
                      shape: slide.photoShape,
                      frame: slide.photoFrame,
                      colorFilter: slide.photoFilter.colorFilter,
                    )),
                ],
              ),
            );
          } else {
            final photoWidget = buildShapedPhoto(
              imagePath: slide.imagePath,
              shape: slide.photoShape,
              frame: slide.photoFrame,
              fit: BoxFit.contain,
              colorFilter: slide.photoFilter.colorFilter,
            );
            photoContent = ColoredBox(
              color: Color(slide.backgroundColor),
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(slide.photoOffsetX * w, slide.photoOffsetY * h),
                  child: Transform.scale(scale: slide.photoScale, child: photoWidget),
                ),
              ),
            );
          }

          // Photo acts as the interactive background: tap=deselect, drag/pinch=move+zoom.
          background = GestureDetector(
            onTap: () => widget.viewModel.selectLayer(null),
            onScaleStart: slide.layout == SlideLayout.single ? _onPhotoScaleStart : null,
            onScaleUpdate: slide.layout == SlideLayout.single
                ? (d) => _onPhotoScaleUpdate(d, w, h)
                : null,
            child: SizedBox.expand(child: photoContent),
          );
        } else {
          background = GestureDetector(
            onTap: () => widget.viewModel.selectLayer(null),
            child: _gradientBg(),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            background,
            _gradientOverlay(),
            buildSlideOverlay(slide.overlay),
            // Text layers — draggable, opaque (intercept their own touches before photo GD).
            for (final layer in slide.textLayers)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(
                    (layer.x * 2 - 1).clamp(-0.95, 0.95),
                    (layer.y * 2 - 1).clamp(-0.95, 0.95),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.viewModel.selectLayer(layer.id),
                    onPanUpdate: (d) => widget.viewModel.moveTextLayer(
                      layer.id,
                      (layer.x + d.delta.dx / w).clamp(0.05, 0.95),
                      (layer.y + d.delta.dy / h).clamp(0.05, 0.95),
                    ),
                    child: _LayerWidget(
                      layer: layer,
                      selected: layer.id == selectedLayerId,
                    ),
                  ),
                ),
              ),
            // Drag/pinch hint — shown on photo slides when no text layer is selected.
            if (hasPhoto && selectedLayerId == null)
              Positioned(
                bottom: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_with,
                            color: Colors.white54, size: 10),
                        const SizedBox(width: 3),
                        Text('drag · pinch to zoom',
                            style: TextStyle(
                                fontFamily: AppTheme.fontTheme,
                                color: Colors.white54,
                                fontSize: 8)),
                      ],
                    ),
                  ),
                ),
              ),
            // Empty canvas hint.
            if (slide.textLayers.isEmpty)
              IgnorePointer(
                child: Center(
                  child: Text(
                    'Tap "+ Main" or "+ Sub" to add text',
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.subtleText.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            // Add photo chip.
            if (!hasPhoto)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: widget.viewModel.pickImageForCurrentSlide,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: AppTheme.gold, size: 14),
                        const SizedBox(width: 4),
                        Text('Add Photo',
                            style: TextStyle(
                                fontFamily: AppTheme.fontTheme,
                                color: AppTheme.gold,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _gradientBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1208), Color(0xFF0D0D0D)],
          ),
        ),
      );

  Widget _gradientOverlay() => IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45)
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
      );
}

class _LayerWidget extends StatelessWidget {
  const _LayerWidget({required this.layer, required this.selected});
  final TextLayer layer;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = layer.color.color;
    final fontSize =
        layer.isSubtitle ? layer.size.subFontSize : layer.size.mainFontSize;
    final style = slideLayerTextStyle(
      layer.fontStyle,
      fontSize: fontSize,
      color: color,
      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10)],
    ).copyWith(letterSpacing: layer.letterSpacing);

    // Build text content — optionally with stroke outline
    Widget textWidget;
    if (layer.strokeWidth > 0) {
      final strokeStyle = style.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer.strokeWidth * 2.2
          ..color = Colors.black.withValues(alpha: 0.9),
        shadows: null,
      );
      textWidget = Stack(
        children: [
          Text(layer.text, style: strokeStyle, textAlign: TextAlign.center),
          Text(layer.text, style: style, textAlign: TextAlign.center),
        ],
      );
    } else {
      textWidget = Text(layer.text, style: style, textAlign: TextAlign.center);
    }

    Widget content = textWidget;

    // Subtitle bar decoration
    if (layer.isSubtitle) {
      content = IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(color: layer.barColor.color, width: 2.5)),
          ),
          child: content,
        ),
      );
    }

    // Text background
    if (layer.textBg != SlideTextBg.none) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: layer.textBg == SlideTextBg.pill
              ? BorderRadius.circular(20)
              : BorderRadius.circular(4),
        ),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: selected
          ? BoxDecoration(
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.7),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
              color: AppTheme.gold.withValues(alpha: 0.05),
            )
          : null,
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layer edit panel (shown when a text layer is selected)
// ─────────────────────────────────────────────────────────────────────────────

class _LayerEditPanel extends StatefulWidget {
  const _LayerEditPanel({
    super.key,
    required this.layer,
    required this.onUpdate,
    required this.onDelete,
  });
  final TextLayer layer;
  final void Function(TextLayer) onUpdate;
  final VoidCallback onDelete;

  @override
  State<_LayerEditPanel> createState() => _LayerEditPanelState();
}

class _LayerEditPanelState extends State<_LayerEditPanel> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.layer.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Always base every write on widget.layer (live ViewModel state) so that
  // drag-repositioned text is never overwritten by stale local position values.
  void _applyStyle(TextLayer Function(TextLayer) fn) {
    widget.onUpdate(fn(widget.layer.copyWith(text: _ctrl.text)));
  }

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    return Container(
      color: AppTheme.darkSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: "Editing text" + delete
            Row(
              children: [
                const Icon(Icons.text_fields, color: AppTheme.gold, size: 14),
                const SizedBox(width: 6),
                Text(
                  layer.isSubtitle ? 'Subtitle layer' : 'Main layer',
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              const Color(0xFFFF6B6B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline,
                            color: Color(0xFFFF6B6B), size: 13),
                        const SizedBox(width: 3),
                        Text('Delete',
                            style: TextStyle(
                                fontFamily: AppTheme.fontTheme,
                                color: const Color(0xFFFF6B6B),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Text input
            TextField(
              controller: _ctrl,
              style: slideLayerTextStyle(layer.fontStyle,
                  fontSize: 16,
                  color: AppTheme.cream,
                  fontWeight: FontWeight.normal),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter text…',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => widget.onUpdate(widget.layer.copyWith(text: v)),
            ),
            const SizedBox(height: 10),
            // Type toggle (main / subtitle)
            Row(
              children: [
                _TypeButton(
                  label: 'Main',
                  icon: Icons.title,
                  selected: !layer.isSubtitle,
                  onTap: () =>
                      _applyStyle((l) => l.copyWith(isSubtitle: false)),
                ),
                const SizedBox(width: 6),
                _TypeButton(
                  label: 'Subtitle',
                  icon: Icons.short_text,
                  selected: layer.isSubtitle,
                  onTap: () => _applyStyle((l) => l.copyWith(isSubtitle: true)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Text color
            _Label('Text Color'),
            const SizedBox(height: 6),
            _ColorDots(
              current: layer.color,
              onSelect: (c) => _applyStyle((l) => l.copyWith(color: c)),
            ),
            // Bar color (only for subtitle)
            if (layer.isSubtitle) ...[
              const SizedBox(height: 10),
              _Label('Bar Color'),
              const SizedBox(height: 6),
              _ColorDots(
                current: layer.barColor,
                onSelect: (c) => _applyStyle((l) => l.copyWith(barColor: c)),
              ),
            ],
            const SizedBox(height: 10),
            // Font picker
            _Label('Font'),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SlideFontStyle.values.map((f) {
                  final sel = layer.fontStyle == f;
                  return GestureDetector(
                    onTap: () => _applyStyle((l) => l.copyWith(fontStyle: f)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.gold.withValues(alpha: 0.15)
                            : AppTheme.darkSurface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppTheme.gold : AppTheme.border,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Text(
                        f.label,
                        style: slideLayerTextStyle(f,
                            fontSize: 13,
                            color: sel ? AppTheme.gold : AppTheme.subtleText,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w400),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Size picker
            Row(
              children: [
                _Label('Size'),
                const SizedBox(width: 12),
                ...SlideTextSize.values.map((s) {
                  final sel = layer.size == s;
                  return GestureDetector(
                    onTap: () => _applyStyle((l) => l.copyWith(size: s)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.gold.withValues(alpha: 0.2)
                            : AppTheme.darkSurface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel ? AppTheme.gold : AppTheme.border,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Center(
                        child: Text(
                          s.label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontTheme,
                            color: sel ? AppTheme.gold : AppTheme.subtleText,
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            // Text background
            _Label('Text Bg'),
            const SizedBox(height: 6),
            Row(
              children: SlideTextBg.values.map((bg) {
                final sel = widget.layer.textBg == bg;
                return GestureDetector(
                  onTap: () => _applyStyle((l) => l.copyWith(textBg: bg)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.gold.withValues(alpha: 0.2)
                          : AppTheme.darkSurface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel ? AppTheme.gold : AppTheme.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Center(
                      child: Text(
                        bg.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.gold : AppTheme.subtleText,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Stroke width
            _Label('Outline'),
            const SizedBox(height: 6),
            Row(
              children: [0.0, 1.0, 2.0, 3.0].map((w) {
                final sel = widget.layer.strokeWidth == w;
                final label = w == 0 ? 'Off' : w == 1 ? 'Thin' : w == 2 ? 'Med' : 'Bold';
                return GestureDetector(
                  onTap: () => _applyStyle((l) => l.copyWith(strokeWidth: w)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.gold.withValues(alpha: 0.2)
                          : AppTheme.darkSurface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel ? AppTheme.gold : AppTheme.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.gold : AppTheme.subtleText,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Letter spacing
            _Label('Spacing'),
            const SizedBox(height: 6),
            Row(
              children: [
                (0.0, 'Normal'),
                (1.0, 'Wide'),
                (3.0, 'Wider'),
                (6.0, 'Max'),
              ].map(((double, String) entry) {
                final (sp, label) = entry;
                final sel = widget.layer.letterSpacing == sp;
                return GestureDetector(
                  onTap: () => _applyStyle((l) => l.copyWith(letterSpacing: sp)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 52,
                    height: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.gold.withValues(alpha: 0.2)
                          : AppTheme.darkSurface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel ? AppTheme.gold : AppTheme.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.gold : AppTheme.subtleText,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide edit panel (shown when no layer is selected)
// ─────────────────────────────────────────────────────────────────────────────

class _SlideEditPanel extends StatelessWidget {
  const _SlideEditPanel({required this.slide, required this.viewModel});
  final Slide slide;
  final EditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo scale + reset (only when a photo is present)
            if (slide.imagePath != null) ...[
              Row(
                children: [
                  _Label('Photo Zoom'),
                  const Spacer(),
                  Text(
                    '${slide.photoScale.toStringAsFixed(1)}×',
                    style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => viewModel.updatePhotoTransform(
                        scale: 1.0, offsetX: 0.0, offsetY: 0.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text('Reset',
                          style: TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.subtleText,
                              fontSize: 11)),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.zoom_out,
                      color: AppTheme.subtleText, size: 16),
                  Expanded(
                    child: Slider(
                      value: slide.photoScale.clamp(0.1, 4.0),
                      min: 0.1,
                      max: 4.0,
                      onChanged: (v) => viewModel.updatePhotoTransform(
                        scale: v,
                        offsetX: slide.photoOffsetX,
                        offsetY: slide.photoOffsetY,
                      ),
                    ),
                  ),
                  const Icon(Icons.zoom_in,
                      color: AppTheme.subtleText, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              _Label('Background Color'),
              const SizedBox(height: 6),
              _BackgroundColorPicker(
                current: slide.backgroundColor,
                onSelect: (c) => viewModel
                    .updateSelectedSlide(slide.copyWith(backgroundColor: c)),
              ),
              const SizedBox(height: 6),
            ],
            // Photo filter strip
            _Label('Filter'),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PhotoFilter.values.map((filter) {
                  final sel = slide.photoFilter == filter;
                  return GestureDetector(
                    onTap: () => viewModel.updateSelectedSlide(
                        slide.copyWith(photoFilter: filter)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: sel
                            ? AppTheme.gold.withValues(alpha: 0.2)
                            : AppTheme.darkSurface2,
                        border: Border.all(
                            color: sel ? AppTheme.gold : AppTheme.border,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Text(
                        filter.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.gold : AppTheme.subtleText,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Transition chips
            _Label('Transition'),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TransitionEffect.values.map((effect) {
                  final sel = slide.transition == effect;
                  return GestureDetector(
                    onTap: () => viewModel.updateSelectedSlide(
                        slide.copyWith(transition: effect)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: sel
                            ? AppTheme.gold.withValues(alpha: 0.2)
                            : AppTheme.darkSurface2,
                        border: Border.all(
                            color: sel ? AppTheme.gold : AppTheme.border,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Text(
                        effect.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.gold : AppTheme.subtleText,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Overlay picker
            _Label('Overlay'),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SlideOverlay.values.map((ov) {
                  final sel = slide.overlay == ov;
                  return GestureDetector(
                    onTap: () => viewModel.updateSelectedSlide(
                        slide.copyWith(overlay: ov)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: sel
                            ? AppTheme.gold.withValues(alpha: 0.2)
                            : AppTheme.darkSurface2,
                        border: Border.all(
                            color: sel ? AppTheme.gold : AppTheme.border,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Text(
                        ov.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.gold : AppTheme.subtleText,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Layout picker
            _Label('Layout'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: SlideLayout.values.map((lay) {
                final selected = slide.layout == lay;
                return ChoiceChip(
                  label: Text(lay.label),
                  selected: selected,
                  onSelected: (_) {
                    viewModel.updateSelectedSlide(slide.copyWith(layout: lay));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (slide.layout != SlideLayout.single) ...[
              _Label('Photos'),
              const SizedBox(height: 6),
              // Photo 1 already handled by the main photo picker button above
              // Photo 2
              OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(slide.imagePath2 != null ? 'Photo 2 ✓' : 'Add Photo 2'),
                onPressed: () => viewModel.pickImageForSlot(2),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              if (slide.layout == SlideLayout.strip3)
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(slide.imagePath3 != null ? 'Photo 3 ✓' : 'Add Photo 3'),
                  onPressed: () => viewModel.pickImageForSlot(3),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            // Shape picker
            _Label('Shape'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PhotoShape.values.map((sh) {
                final selected = slide.photoShape == sh;
                return ChoiceChip(
                  label: Text(sh.label),
                  selected: selected,
                  onSelected: (_) {
                    viewModel.updateSelectedSlide(slide.copyWith(photoShape: sh));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Frame picker
            _Label('Frame'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PhotoFrame.values.map((fr) {
                final selected = slide.photoFrame == fr;
                return ChoiceChip(
                  label: Text(fr.label),
                  selected: selected,
                  onSelected: (_) {
                    viewModel.updateSelectedSlide(slide.copyWith(photoFrame: fr));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Duration slider
            Row(
              children: [
                _Label('Duration'),
                const Spacer(),
                Text('${slide.durationSeconds}s',
                    style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            Slider(
              value: slide.durationSeconds.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              onChanged: (v) => viewModel.updateSelectedSlide(
                  slide.copyWith(durationSeconds: v.round())),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontTheme,
          color: AppTheme.subtleText,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.current, required this.onSelect});
  final SlideTextColor current;
  final void Function(SlideTextColor) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SlideTextColor.values.map((c) {
        final sel = c == current;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.color,
              border: Border.all(
                  color: sel ? AppTheme.gold : AppTheme.border,
                  width: sel ? 2.5 : 1),
              boxShadow: sel
                  ? [
                      BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.5),
                          blurRadius: 6)
                    ]
                  : null,
            ),
            child: sel
                ? Icon(Icons.check,
                    size: 13,
                    color:
                        c == SlideTextColor.white || c == SlideTextColor.cream
                            ? Colors.black
                            : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _BackgroundColorPicker extends StatefulWidget {
  const _BackgroundColorPicker({required this.current, required this.onSelect});
  final int current;
  final void Function(int argb) onSelect;

  @override
  State<_BackgroundColorPicker> createState() => _BackgroundColorPickerState();
}

class _BackgroundColorPickerState extends State<_BackgroundColorPicker> {
  late final TextEditingController _hex;

  static const _presets = <int>[
    0xFF000000,
    0xFF1A1A1A,
    0xFF0D0D0D,
    0xFFFFFFFF,
    0xFFF5F0E8,
    0xFFE8B4B8,
  ];

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(text: _toHex(widget.current));
  }

  @override
  void didUpdateWidget(_BackgroundColorPicker old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _hex.text = _toHex(widget.current);
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  static String _toHex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  int? _parseHex(String raw) {
    final s = raw.replaceAll('#', '').trim();
    if (s.length != 6) return null;
    final v = int.tryParse(s, radix: 16);
    return v != null ? (0xFF000000 | v) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: _presets.map((c) {
            final sel = c == widget.current;
            return GestureDetector(
              onTap: () {
                widget.onSelect(c);
                _hex.text = _toHex(c);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(c),
                  border: Border.all(
                    color: sel ? AppTheme.gold : AppTheme.border,
                    width: sel ? 2.5 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: AppTheme.gold.withValues(alpha: 0.4),
                              blurRadius: 5)
                        ]
                      : null,
                ),
                child: sel
                    ? Icon(Icons.check,
                        size: 12,
                        color: (c == 0xFFFFFFFF || c == 0xFFF5F0E8)
                            ? Colors.black
                            : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: TextField(
            controller: _hex,
            style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.cream,
                fontSize: 12),
            decoration: const InputDecoration(
              hintText: '#000000',
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              prefixIcon: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.palette_outlined,
                    size: 14, color: AppTheme.subtleText),
              ),
            ),
            onSubmitted: (raw) {
              final color = _parseHex(raw);
              if (color != null) widget.onSelect(color);
            },
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.gold.withValues(alpha: 0.2)
              : AppTheme.darkSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppTheme.gold : AppTheme.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? AppTheme.gold : AppTheme.subtleText),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: selected ? AppTheme.gold : AppTheme.subtleText,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: highlighted
              ? AppTheme.gold.withValues(alpha: 0.15)
              : AppTheme.darkSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: highlighted
                  ? AppTheme.gold.withValues(alpha: 0.4)
                  : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: highlighted ? AppTheme.gold : AppTheme.subtleText,
                size: 14),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 70),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: highlighted ? AppTheme.gold : AppTheme.subtleText,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SlideThumbnail extends StatelessWidget {
  const _SlideThumbnail({
    required this.slide,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final Slide slide;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.gold : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          gradient: const LinearGradient(
              colors: [Color(0xFF1A1208), Color(0xFF0D0D0D)]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (slide.imagePath != null)
                Image.file(File(slide.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: isSelected ? AppTheme.gold : AppTheme.subtleText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSlideButton extends StatelessWidget {
  const _AddSlideButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
          color: AppTheme.gold.withValues(alpha: 0.08),
        ),
        child: const Icon(Icons.add, color: AppTheme.gold, size: 22),
      ),
    );
  }
}

class _MusicTimelineButton extends StatelessWidget {
  const _MusicTimelineButton({required this.musicName, required this.onTap});
  final String? musicName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        margin: const EdgeInsets.only(left: 8, right: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: musicName != null
                ? AppTheme.gold.withValues(alpha: 0.5)
                : AppTheme.border,
          ),
          color: musicName != null
              ? AppTheme.gold.withValues(alpha: 0.08)
              : AppTheme.darkSurface,
        ),
        child: Icon(Icons.music_note_outlined,
            color: musicName != null ? AppTheme.gold : AppTheme.subtleText,
            size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheets
// ─────────────────────────────────────────────────────────────────────────────

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({required this.onSelect});
  final void Function(SlideTemplate) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Choose a Template',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Start with a pre-designed layout',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.subtleText,
                  fontSize: 13)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            physics: const NeverScrollableScrollPhysics(),
            children: SlideTemplate.values.map((t) {
              return GestureDetector(
                onTap: () => onSelect(t),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface2,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t.label,
                          style: TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.cream,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(t.description,
                          style: TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.subtleText,
                              fontSize: 9),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MusicPickerSheet extends StatelessWidget {
  const _MusicPickerSheet({
    required this.currentMusicName,
    required this.onSelect,
    required this.onRemove,
  });

  final String? currentMusicName;
  final void Function(String name) onSelect;
  final VoidCallback onRemove;

  static const _songs = [
    ('A Thousand Years', 'Christina Perri'),
    ('Perfect', 'Ed Sheeran'),
    ('All of Me', 'John Legend'),
    ("Can't Help Falling in Love", 'Elvis Presley'),
    ('Marry Me', 'Train'),
    ('Make You Feel My Love', 'Adele'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Choose a Song',
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (currentMusicName != null)
                TextButton(
                  onPressed: () {
                    onRemove();
                    Navigator.of(context).pop();
                  },
                  child: Text('Remove',
                      style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: const Color(0xFFFF6B6B),
                          fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ..._songs.map((song) {
            final isSel = currentMusicName == song.$1;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSel
                      ? AppTheme.gold.withValues(alpha: 0.2)
                      : AppTheme.darkSurface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                    isSel ? Icons.music_note : Icons.music_note_outlined,
                    color: isSel ? AppTheme.gold : AppTheme.subtleText,
                    size: 18),
              ),
              title: Text(song.$1,
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.cream,
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400)),
              subtitle: Text(song.$2,
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.subtleText,
                      fontSize: 12)),
              trailing: isSel
                  ? const Icon(Icons.check_circle,
                      color: AppTheme.gold, size: 18)
                  : null,
              onTap: () {
                onSelect(song.$1);
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
    );
  }
}
