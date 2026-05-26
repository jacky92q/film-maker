import 'dart:io';

import 'package:film_maker/data/repositories/export_repository.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/app_routes.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/editor/view_models/editor_view_model.dart';
import 'package:film_maker/ui/features/export/view_models/export_view_model.dart';
import 'package:film_maker/ui/features/export/views/export_view.dart';
import 'package:film_maker/ui/features/preview/view_models/preview_view_model.dart';
import 'package:film_maker/ui/features/preview/views/preview_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Returns the appropriate TextStyle for a given font style.
TextStyle slideLayerTextStyle(
  SlideFontStyle font, {
  double fontSize = 20,
  Color color = Colors.white,
  FontWeight fontWeight = FontWeight.w600,
  List<Shadow>? shadows,
}) {
  switch (font) {
    case SlideFontStyle.serif:
      return GoogleFonts.playfairDisplay(
          fontSize: fontSize, color: color, fontWeight: fontWeight, shadows: shadows);
    case SlideFontStyle.sans:
      return GoogleFonts.lato(
          fontSize: fontSize, color: color, fontWeight: fontWeight, shadows: shadows);
    case SlideFontStyle.script:
      return GoogleFonts.dancingScript(
          fontSize: fontSize, color: color, fontWeight: fontWeight, shadows: shadows);
    case SlideFontStyle.display:
      return GoogleFonts.cinzel(
          fontSize: fontSize, color: color, fontWeight: fontWeight, shadows: shadows);
    case SlideFontStyle.elegant:
      return GoogleFonts.ebGaramond(
          fontSize: fontSize, color: color, fontWeight: fontWeight, shadows: shadows);
    case SlideFontStyle.modern:
      return GoogleFonts.montserrat(
          fontSize: fontSize, color: color, fontWeight: fontWeight, shadows: shadows);
  }
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
            style: GoogleFonts.playfairDisplay(color: AppTheme.cream)),
        content: Text('Save your film before leaving?',
            style: GoogleFonts.lato(color: AppTheme.subtleText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Discard',
                style: GoogleFonts.lato(color: AppTheme.subtleText)),
          ),
          TextButton(
            onPressed: () async {
              await widget.viewModel.saveProject();
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: Text('Save', style: GoogleFonts.lato(color: AppTheme.gold)),
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
                child: Text('No slides', style: TextStyle(color: AppTheme.subtleText)),
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
              style: GoogleFonts.playfairDisplay(color: AppTheme.cream, fontSize: 18),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              onSubmitted: (v) {
                widget.viewModel.updateProjectTitle(
                    v.trim().isEmpty ? widget.viewModel.project.title : v.trim());
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
                    style: GoogleFonts.playfairDisplay(color: AppTheme.cream, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, color: AppTheme.subtleText, size: 14),
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
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                        )
                      : const Icon(Icons.save_outlined, color: AppTheme.gold),
                  onPressed: widget.viewModel.isSaving ? null : () => widget.viewModel.saveProject(),
                ),
              TextButton(
                onPressed: _openPreview,
                child: Text('Preview', style: GoogleFonts.lato(color: AppTheme.gold, fontSize: 13)),
              ),
              TextButton(
                onPressed: _openExport,
                child: Text('Export', style: GoogleFonts.lato(color: AppTheme.cream, fontSize: 13)),
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
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 20),
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

class _SlideCanvas extends StatelessWidget {
  const _SlideCanvas({required this.viewModel});
  final EditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final slide = viewModel.selectedSlide!;
    final selectedLayerId = viewModel.selectedLayerId;

    Widget photo = slide.imagePath != null
        ? Image.file(File(slide.imagePath!),
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => _gradientBg())
        : _gradientBg();

    final filter = slide.photoFilter.colorFilter;
    if (filter != null) {
      photo = ColorFiltered(colorFilter: filter, child: photo);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return GestureDetector(
          // tap on empty canvas = deselect layer
          onTap: () => viewModel.selectLayer(null),
          child: Stack(
            fit: StackFit.expand,
            children: [
              photo,
              _gradientOverlay(),
              // Text layers — draggable
              for (final layer in slide.textLayers)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      (layer.x * 2 - 1).clamp(-0.95, 0.95),
                      (layer.y * 2 - 1).clamp(-0.95, 0.95),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => viewModel.selectLayer(layer.id),
                      onPanUpdate: (d) => viewModel.moveTextLayer(
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
              // Empty canvas hint
              if (slide.textLayers.isEmpty)
                IgnorePointer(
                  child: Center(
                    child: Text(
                      'Tap "+ Main" or "+ Sub" to add text',
                      style: GoogleFonts.lato(
                        color: AppTheme.subtleText.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              // Add photo chip
              if (slide.imagePath == null)
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: viewModel.pickImageForCurrentSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBg.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.gold, size: 14),
                          const SizedBox(width: 4),
                          Text('Add Photo', style: GoogleFonts.lato(color: AppTheme.gold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
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
    final fontSize = layer.isSubtitle ? layer.size.subFontSize : layer.size.mainFontSize;
    final shadows = [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10)];
    final style = slideLayerTextStyle(layer.fontStyle,
        fontSize: fontSize, color: color, shadows: shadows);

    Widget content = Text(layer.text, style: style, textAlign: TextAlign.center);

    if (layer.isSubtitle) {
      content = IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: layer.barColor.color, width: 2.5)),
          ),
          child: content,
        ),
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
  late TextLayer _layer;

  @override
  void initState() {
    super.initState();
    _layer = widget.layer;
    _ctrl = TextEditingController(text: _layer.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _update(TextLayer updated) {
    setState(() => _layer = updated);
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
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
                  _layer.isSubtitle ? 'Subtitle layer' : 'Main layer',
                  style: GoogleFonts.lato(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 13),
                        const SizedBox(width: 3),
                        Text('Delete', style: GoogleFonts.lato(color: const Color(0xFFFF6B6B), fontSize: 11)),
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
              style: const TextStyle(color: AppTheme.cream, fontSize: 14),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter text…',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => _update(_layer.copyWith(text: v)),
            ),
            const SizedBox(height: 10),
            // Type toggle (main / subtitle)
            Row(
              children: [
                _TypeButton(
                  label: 'Main',
                  icon: Icons.title,
                  selected: !_layer.isSubtitle,
                  onTap: () => _update(_layer.copyWith(isSubtitle: false)),
                ),
                const SizedBox(width: 6),
                _TypeButton(
                  label: 'Subtitle',
                  icon: Icons.short_text,
                  selected: _layer.isSubtitle,
                  onTap: () => _update(_layer.copyWith(isSubtitle: true)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Text color
            _Label('Text Color'),
            const SizedBox(height: 6),
            _ColorDots(
              current: _layer.color,
              onSelect: (c) => _update(_layer.copyWith(color: c)),
            ),
            // Bar color (only for subtitle)
            if (_layer.isSubtitle) ...[
              const SizedBox(height: 10),
              _Label('Bar Color'),
              const SizedBox(height: 6),
              _ColorDots(
                current: _layer.barColor,
                onSelect: (c) => _update(_layer.copyWith(barColor: c)),
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
                  final sel = _layer.fontStyle == f;
                  return GestureDetector(
                    onTap: () => _update(_layer.copyWith(fontStyle: f)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 7),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.gold.withValues(alpha: 0.15) : AppTheme.darkSurface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppTheme.gold : AppTheme.border, width: sel ? 1.5 : 1),
                      ),
                      child: Text(
                        f.label,
                        style: slideLayerTextStyle(f,
                            fontSize: 13,
                            color: sel ? AppTheme.gold : AppTheme.subtleText,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400),
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
                  final sel = _layer.size == s;
                  return GestureDetector(
                    onTap: () => _update(_layer.copyWith(size: s)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.darkSurface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? AppTheme.gold : AppTheme.border, width: sel ? 1.5 : 1),
                      ),
                      child: Center(
                        child: Text(
                          s.label,
                          style: GoogleFonts.lato(
                            color: sel ? AppTheme.gold : AppTheme.subtleText,
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
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
            // Photo filter strip
            _Label('Filter'),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PhotoFilter.values.map((filter) {
                  final sel = slide.photoFilter == filter;
                  return GestureDetector(
                    onTap: () => viewModel.updateSelectedSlide(slide.copyWith(photoFilter: filter)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: sel ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.darkSurface2,
                        border: Border.all(color: sel ? AppTheme.gold : AppTheme.border, width: sel ? 1.5 : 1),
                      ),
                      child: Text(
                        filter.label,
                        style: GoogleFonts.lato(
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
                    onTap: () => viewModel.updateSelectedSlide(slide.copyWith(transition: effect)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: sel ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.darkSurface2,
                        border: Border.all(color: sel ? AppTheme.gold : AppTheme.border, width: sel ? 1.5 : 1),
                      ),
                      child: Text(
                        effect.label,
                        style: GoogleFonts.lato(
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
            // Duration slider
            Row(
              children: [
                _Label('Duration'),
                const Spacer(),
                Text('${slide.durationSeconds}s',
                    style: GoogleFonts.lato(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            Slider(
              value: slide.durationSeconds.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              onChanged: (v) => viewModel.updateSelectedSlide(slide.copyWith(durationSeconds: v.round())),
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
        style: GoogleFonts.lato(
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
              border: Border.all(color: sel ? AppTheme.gold : AppTheme.border, width: sel ? 2.5 : 1),
              boxShadow: sel
                  ? [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
            child: sel
                ? Icon(Icons.check, size: 13,
                    color: c == SlideTextColor.white || c == SlideTextColor.cream
                        ? Colors.black
                        : Colors.white)
                : null,
          ),
        );
      }).toList(),
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
          color: selected ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.darkSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.gold : AppTheme.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? AppTheme.gold : AppTheme.subtleText),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.lato(
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
          color: highlighted ? AppTheme.gold.withValues(alpha: 0.15) : AppTheme.darkSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: highlighted ? AppTheme.gold.withValues(alpha: 0.4) : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: highlighted ? AppTheme.gold : AppTheme.subtleText, size: 14),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 70),
              child: Text(
                label,
                style: GoogleFonts.lato(
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
          gradient: const LinearGradient(colors: [Color(0xFF1A1208), Color(0xFF0D0D0D)]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (slide.imagePath != null)
                Image.file(File(slide.imagePath!),
                    fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              Positioned(
                bottom: 2, left: 0, right: 0,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.lato(
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
            color: musicName != null ? AppTheme.gold.withValues(alpha: 0.5) : AppTheme.border,
          ),
          color: musicName != null ? AppTheme.gold.withValues(alpha: 0.08) : AppTheme.darkSurface,
        ),
        child: Icon(Icons.music_note_outlined,
            color: musicName != null ? AppTheme.gold : AppTheme.subtleText, size: 20),
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
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Choose a Template',
              style: GoogleFonts.playfairDisplay(
                  color: AppTheme.cream, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Start with a pre-designed layout',
              style: GoogleFonts.lato(color: AppTheme.subtleText, fontSize: 13)),
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
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t.label,
                          style: GoogleFonts.lato(
                              color: AppTheme.cream, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(t.description,
                          style: GoogleFonts.lato(color: AppTheme.subtleText, fontSize: 9),
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
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Choose a Song',
                  style: GoogleFonts.playfairDisplay(
                      color: AppTheme.cream, fontSize: 20, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (currentMusicName != null)
                TextButton(
                  onPressed: () {
                    onRemove();
                    Navigator.of(context).pop();
                  },
                  child: Text('Remove',
                      style: GoogleFonts.lato(color: const Color(0xFFFF6B6B), fontSize: 13)),
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
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.darkSurface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(isSel ? Icons.music_note : Icons.music_note_outlined,
                    color: isSel ? AppTheme.gold : AppTheme.subtleText, size: 18),
              ),
              title: Text(song.$1,
                  style: GoogleFonts.lato(
                      color: AppTheme.cream,
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400)),
              subtitle: Text(song.$2,
                  style: GoogleFonts.lato(color: AppTheme.subtleText, fontSize: 12)),
              trailing: isSel
                  ? const Icon(Icons.check_circle, color: AppTheme.gold, size: 18)
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
