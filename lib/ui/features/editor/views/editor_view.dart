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

enum _EditSection { slide, photo, text, music }

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
  _EditSection _section = _EditSection.slide;
  bool _isPortraitLayout = true;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.viewModel.project.title;
    widget.viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChange);
    _titleController.dispose();
    super.dispose();
  }

  // Auto-switch the section tab when a layer is tapped on the canvas.
  void _onViewModelChange() {
    if (!_isPortraitLayout) return;
    final photo = widget.viewModel.selectedPhotoLayer;
    final text = widget.viewModel.selectedLayer;
    if (photo != null && _section != _EditSection.photo) {
      setState(() => _section = _EditSection.photo);
    } else if (text != null && photo == null && _section != _EditSection.text) {
      setState(() => _section = _EditSection.text);
    }
  }

  void _switchSection(_EditSection s) {
    if (s == _section) return;
    setState(() => _section = s);
    if (s == _EditSection.slide || s == _EditSection.music) {
      widget.viewModel.selectLayer(null);
      widget.viewModel.selectPhotoLayer(null);
    }
  }

  Future<bool> _onWillPop() async {
    if (!widget.viewModel.hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unsaved Changes',
            style: TextStyle(
                fontFamily: AppTheme.fontTheme, color: AppTheme.textDark)),
        content: Text('Save your film before leaving?',
            style: TextStyle(
                fontFamily: AppTheme.fontTheme, color: AppTheme.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Discard',
                style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.textMid)),
          ),
          TextButton(
            onPressed: () async {
              await widget.viewModel.saveProject();
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: Text('Save',
                style: TextStyle(
                    fontFamily: AppTheme.fontTheme, color: AppTheme.primary)),
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
      backgroundColor: AppTheme.surface,
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

  // In portrait the timeline ♪ button switches to the Music tab; in
  // landscape/wide it opens a modal (no inline panel available there).
  void _onMusicTimelineButtonTap() {
    if (_isPortraitLayout) {
      _switchSection(_EditSection.music);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 14, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Music',
                      style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _MusicPanel(
                    currentMusicName: widget.viewModel.project.musicName,
                    onSelect: (name) => widget.viewModel.setMusic('music_path', name),
                    onRemove: () => widget.viewModel.setMusic(null, null),
                    closeOnSelect: true,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
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
        backgroundColor: AppTheme.bg,
        appBar: _buildAppBar(),
        body: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final slide = widget.viewModel.selectedSlide;
            if (slide == null) {
              return const Center(
                child: Text('No slides',
                    style: TextStyle(color: AppTheme.textMid)),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isLandscape =
                    !isWide && constraints.maxWidth > constraints.maxHeight + 60;
                if (isWide) return _buildWideLayout(constraints, slide);
                if (isLandscape) return _buildLandscapeLayout(constraints, slide);
                return _buildPortraitLayout(constraints, slide);
              },
            );
          },
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.bg,
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
                  color: AppTheme.textDark,
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
                        color: AppTheme.textDark,
                        fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined,
                    color: AppTheme.textMid, size: 14),
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        )
                      : const Icon(Icons.save_outlined, color: AppTheme.primary),
                  onPressed: widget.viewModel.isSaving ? null : () => widget.viewModel.saveProject(),
                ),
              TextButton(
                onPressed: _openPreview,
                child: Text('Preview',
                    style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.primary, fontSize: 13)),
              ),
              TextButton(
                onPressed: _openExport,
                child: Text('Export',
                    style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textDark, fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Adaptive edit panel ───────────────────────────────────────────────────

  Widget _buildEditPanel() {
    final photoLayer = widget.viewModel.selectedPhotoLayer;
    if (photoLayer != null) {
      return _PhotoLayerTabs(
        key: ValueKey(photoLayer.id),
        vm: widget.viewModel,
        layer: photoLayer,
      );
    }
    final layer = widget.viewModel.selectedLayer;
    if (layer != null) {
      return _TextLayerTabs(
        key: ValueKey(layer.id),
        layer: layer,
        onUpdate: widget.viewModel.updateTextLayer,
        onDelete: () => widget.viewModel.deleteTextLayer(layer.id),
        onBringToFront: () => widget.viewModel.bringToFront(layer.id, isPhoto: false),
        onSendToBack: () => widget.viewModel.sendToBack(layer.id, isPhoto: false),
      );
    }
    final slide = widget.viewModel.selectedSlide;
    if (slide == null) return const SizedBox.shrink();
    return _SlideTabs(slide: slide, viewModel: widget.viewModel);
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  Widget _buildTimeline({double height = 100}) {
    final slides = widget.viewModel.project.slides;
    return Container(
      height: height,
      color: AppTheme.bg,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Row(
        children: [
          _MusicTimelineButton(
            musicName: widget.viewModel.project.musicName,
            onTap: _onMusicTimelineButtonTap,
          ),
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              itemCount: slides.length,
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) {
                widget.viewModel.reorderSlides(oldIndex, newIndex);
              },
              proxyDecorator: (child, index, animation) => child,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return ReorderableDragStartListener(
                  key: ValueKey(slide.id),
                  index: index,
                  child: _SlideThumbnail(
                    slide: slide,
                    index: index,
                    isSelected: index == widget.viewModel.selectedSlideIndex,
                    onTap: () => widget.viewModel.selectSlide(index),
                  ),
                );
              },
              footer: _AddSlideButton(onTap: _showTemplatePickerForNewSlide),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPortraitLayout(BoxConstraints constraints, Slide slide) {
    _isPortraitLayout = true;
    return Column(
      children: [
        // Canvas — always fully visible, never dimmed
        ColoredBox(
          color: const Color(0xFF1C1C1C),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _SlideCanvas(viewModel: widget.viewModel),
          ),
        ),
        // Section selector — switches edit context without any overlay/dim
        _buildSectionTabBar(slide),
        // Edit panel — always inline, always visible alongside canvas
        Expanded(child: _buildSectionContent(slide)),
        // Timeline strip
        _buildTimeline(height: 108),
      ],
    );
  }

  Widget _buildSectionTabBar(Slide slide) {
    final hasPhoto = slide.photoLayers.isNotEmpty;
    final hasText = slide.textLayers.isNotEmpty;
    final hasMusic = widget.viewModel.project.musicName != null;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.line),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _SectionPill(
            icon: Icons.layers_outlined,
            label: 'Slide',
            active: _section == _EditSection.slide,
            onTap: () => _switchSection(_EditSection.slide),
          ),
          _SectionPill(
            icon: Icons.photo_outlined,
            label: 'Photo',
            active: _section == _EditSection.photo,
            dotted: hasPhoto,
            onTap: () => _switchSection(_EditSection.photo),
          ),
          _SectionPill(
            icon: Icons.title_rounded,
            label: 'Text',
            active: _section == _EditSection.text,
            dotted: hasText,
            onTap: () => _switchSection(_EditSection.text),
          ),
          _SectionPill(
            icon: Icons.music_note_outlined,
            label: 'Music',
            active: _section == _EditSection.music,
            dotted: hasMusic,
            onTap: () => _switchSection(_EditSection.music),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(Slide slide) {
    switch (_section) {
      case _EditSection.slide:
        return _SlideTabs(slide: slide, viewModel: widget.viewModel);

      case _EditSection.photo:
        final layer = widget.viewModel.selectedPhotoLayer;
        if (layer == null) {
          return _LayerPlaceholder(
            icon: Icons.photo_outlined,
            headline: 'No photo selected',
            sub: 'Tap a photo in the canvas above',
            actions: [
              _PlaceholderAction(
                label: '+ Add Photo',
                onTap: () => widget.viewModel.addPhotoLayer(),
              ),
            ],
          );
        }
        return _PhotoLayerTabs(
          key: ValueKey(layer.id),
          vm: widget.viewModel,
          layer: layer,
        );

      case _EditSection.text:
        final layer = widget.viewModel.selectedLayer;
        if (layer == null) {
          return _LayerPlaceholder(
            icon: Icons.title_rounded,
            headline: 'No text selected',
            sub: 'Tap a text layer in the canvas above',
            actions: [
              _PlaceholderAction(
                label: '+ Title',
                onTap: () => widget.viewModel.addTextLayer(isSubtitle: false),
              ),
              _PlaceholderAction(
                label: '+ Subtitle',
                onTap: () => widget.viewModel.addTextLayer(isSubtitle: true),
              ),
            ],
          );
        }
        return _TextLayerTabs(
          key: ValueKey(layer.id),
          layer: layer,
          onUpdate: widget.viewModel.updateTextLayer,
          onDelete: () {
            widget.viewModel.deleteTextLayer(layer.id);
            setState(() => _section = _EditSection.slide);
          },
          onBringToFront: () =>
              widget.viewModel.bringToFront(layer.id, isPhoto: false),
          onSendToBack: () =>
              widget.viewModel.sendToBack(layer.id, isPhoto: false),
        );

      case _EditSection.music:
        return _MusicPanel(
          currentMusicName: widget.viewModel.project.musicName,
          onSelect: (name) => widget.viewModel.setMusic('music_path', name),
          onRemove: () => widget.viewModel.setMusic(null, null),
        );
    }
  }

  Widget _buildLandscapeLayout(BoxConstraints constraints, Slide slide) {
    _isPortraitLayout = false;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF1C1C1C),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _SlideCanvas(viewModel: widget.viewModel),
                    ),
                  ),
                ),
              ),
              _buildTimeline(),
            ],
          ),
        ),
        Container(
          width: 272,
          color: AppTheme.surface,
          child: Column(
            children: [
              _buildAddContentBar(slide),
              Expanded(child: _buildEditPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints, Slide slide) {
    _isPortraitLayout = false;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF1C1C1C),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _SlideCanvas(viewModel: widget.viewModel),
                    ),
                  ),
                ),
              ),
              _buildTimeline(),
            ],
          ),
        ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(left: BorderSide(color: AppTheme.line)),
          ),
          child: Column(
            children: [
              _buildAddContentBar(slide),
              Expanded(child: _buildEditPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddContentBar(Slide slide) {
    return _AddContentBar(
      viewModel: widget.viewModel,
      slide: slide,
      onAddPhoto: () => widget.viewModel.addPhotoLayer(),
      onAddTitle: () => widget.viewModel.addTextLayer(isSubtitle: false),
      onAddSubtitle: () => widget.viewModel.addTextLayer(isSubtitle: true),
      onMusic: _onMusicTimelineButtonTap,
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

  // Photo-layer gesture start values
  double _plStartW = 0.0;
  double _plStartH = 0.0;
  double _plStartCropScale = 1.0;

  Widget _buildTextLayerItem(TextLayer layer, double canvasW, double canvasH, String? selectedLayerId) {
    return Positioned.fill(
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
            (layer.x + d.delta.dx / canvasW).clamp(0.05, 0.95),
            (layer.y + d.delta.dy / canvasH).clamp(0.05, 0.95),
          ),
          child: _LayerWidget(
            layer: layer,
            selected: layer.id == selectedLayerId,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoLayerItem(PhotoLayer pl, double canvasW, double canvasH) {
    final isSelectedPL = widget.viewModel.selectedPhotoLayerId == pl.id;
    final isCropMode = isSelectedPL && widget.viewModel.cropMode;
    final left = (pl.x - pl.widthFraction / 2).clamp(0.0, 0.98) * canvasW;
    final top  = (pl.y - pl.heightFraction / 2).clamp(0.0, 0.98) * canvasH;
    final pw   = pl.widthFraction * canvasW;
    final ph   = pl.heightFraction * canvasH;

    return Positioned(
      key: ValueKey('pl_${pl.id}'),
      left: left, top: top, width: pw, height: ph,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.viewModel.selectPhotoLayer(pl.id);
          widget.viewModel.selectLayer(null);
        },
        onScaleStart: (_) {
          _plStartW = pl.widthFraction;
          _plStartH = pl.heightFraction;
          _plStartCropScale = pl.cropScale;
        },
        onScaleUpdate: (d) {
          if (!isSelectedPL) {
            final newX = (pl.x + d.focalPointDelta.dx / canvasW).clamp(0.04, 0.96);
            final newY = (pl.y + d.focalPointDelta.dy / canvasH).clamp(0.04, 0.96);
            widget.viewModel.movePhotoLayer(pl.id, newX, newY);
          } else if (isCropMode) {
            final newOX = (pl.cropOffsetX + d.focalPointDelta.dx / pw).clamp(-0.5, 0.5);
            final newOY = (pl.cropOffsetY + d.focalPointDelta.dy / ph).clamp(-0.5, 0.5);
            final newCS = (_plStartCropScale * d.scale).clamp(1.0, 4.0);
            widget.viewModel.updatePhotoLayer(
              pl.copyWith(cropOffsetX: newOX, cropOffsetY: newOY, cropScale: newCS),
            );
          } else {
            final newX = (pl.x + d.focalPointDelta.dx / canvasW).clamp(0.04, 0.96);
            final newY = (pl.y + d.focalPointDelta.dy / canvasH).clamp(0.04, 0.96);
            final newW = (_plStartW * d.scale).clamp(0.08, 1.0);
            final newH = (_plStartH * d.scale).clamp(0.08, 1.0);
            widget.viewModel.updatePhotoLayer(
              pl.copyWith(x: newX, y: newY, widthFraction: newW, heightFraction: newH),
            );
          }
        },
        child: Transform.rotate(
          angle: pl.rotation * 3.14159265 / 180.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              buildShapedPhoto(
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
              if (isSelectedPL)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCropMode ? Colors.orangeAccent : Colors.blueAccent,
                        width: isCropMode ? 2.5 : 1.5,
                      ),
                    ),
                  ),
                ),
              if (isCropMode)
                Positioned(
                  top: 4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('CROP', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSortedLayers(Slide slide, double canvasW, double canvasH, String? selectedLayerId) {
    final items = <({int z, Widget w})>[];
    for (final layer in slide.textLayers) {
      items.add((z: layer.zOrder, w: _buildTextLayerItem(layer, canvasW, canvasH, selectedLayerId)));
    }
    for (final pl in slide.photoLayers) {
      items.add((z: pl.zOrder, w: _buildPhotoLayerItem(pl, canvasW, canvasH)));
    }
    items.sort((a, b) => a.z.compareTo(b.z));
    return items.map((e) => e.w).toList();
  }

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
    // All layers rendered in a canonical 1280×720 space so that positions,
    // sizes, and font sizes are identical between editor and preview at any
    // screen resolution or orientation. FittedBox scales the whole canvas.
    const canonicalW = 1280.0;
    const canonicalH = 720.0;

    final slide = widget.viewModel.selectedSlide!;
    final selectedLayerId = widget.viewModel.selectedLayerId;

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
              offset: Offset(slide.photoOffsetX * canonicalW, slide.photoOffsetY * canonicalH),
              child: Transform.scale(scale: slide.photoScale, child: photoWidget),
            ),
          ),
        );
      }

      // Photo acts as the interactive background: tap=deselect, drag/pinch=move+zoom.
      // Gesture deltas are in canonical space because GestureDetector is inside FittedBox.
      background = GestureDetector(
        onTap: () {
          widget.viewModel.selectLayer(null);
          widget.viewModel.selectPhotoLayer(null);
        },
        onScaleStart: slide.layout == SlideLayout.single ? _onPhotoScaleStart : null,
        onScaleUpdate: slide.layout == SlideLayout.single
            ? (d) => _onPhotoScaleUpdate(d, canonicalW, canonicalH)
            : null,
        child: SizedBox.expand(child: photoContent),
      );
    } else {
      background = GestureDetector(
        onTap: () {
          widget.viewModel.selectLayer(null);
          widget.viewModel.selectPhotoLayer(null);
        },
        child: ColoredBox(color: Color(slide.backgroundColor)),
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: canonicalW,
        height: canonicalH,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            background,
            _gradientOverlay(),
            buildSlideOverlay(slide.overlay),
            ..._buildSortedLayers(slide, canonicalW, canonicalH, selectedLayerId),
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
                            color: AppTheme.textMid, size: 10),
                        const SizedBox(width: 3),
                        Text('drag · pinch to zoom',
                            style: TextStyle(
                                fontFamily: AppTheme.fontTheme,
                                color: AppTheme.textMid,
                                fontSize: 8)),
                      ],
                    ),
                  ),
                ),
              ),
            if (slide.textLayers.isEmpty)
              IgnorePointer(
                child: Center(
                  child: Text(
                    'Tap "+ Main" or "+ Sub" to add text',
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.textMid.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
    final double fontSize = layer.fontSize;
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

    return Transform.rotate(
      angle: layer.rotation * 3.14159265 / 180.0,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: selected
            ? BoxDecoration(
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.gold.withValues(alpha: 0.08),
              )
            : null,
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddContentBar — row of big action buttons (Photo · Title · Sub · Music)
// ─────────────────────────────────────────────────────────────────────────────

class _AddContentBar extends StatelessWidget {
  const _AddContentBar({
    required this.viewModel,
    required this.slide,
    required this.onAddPhoto,
    required this.onAddTitle,
    required this.onAddSubtitle,
    required this.onMusic,
  });

  final EditorViewModel viewModel;
  final Slide slide;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddTitle;
  final VoidCallback onAddSubtitle;
  final VoidCallback onMusic;

  @override
  Widget build(BuildContext context) {
    final hasMusic = viewModel.project.musicName != null;
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Row(
        children: [
          _BigActionBtn(
            icon: Icons.add_photo_alternate_rounded,
            label: 'Photo',
            onTap: onAddPhoto,
          ),
          _BigActionBtn(
            icon: Icons.title_rounded,
            label: 'Title',
            onTap: onAddTitle,
          ),
          _BigActionBtn(
            icon: Icons.short_text_rounded,
            label: 'Sub',
            onTap: onAddSubtitle,
          ),
          _BigActionBtn(
            icon: Icons.music_note_rounded,
            label: 'Music',
            onTap: onMusic,
            active: hasMusic,
          ),
        ],
      ),
    );
  }
}

class _BigActionBtn extends StatelessWidget {
  const _BigActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: active ? AppTheme.primary : AppTheme.surface2,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: active ? Colors.white : AppTheme.textMid,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: active ? AppTheme.primary : AppTheme.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionHeader — gold all-caps label with divider
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            color: AppTheme.primary,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 1,
          width: 32,
          color: AppTheme.primary.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TextLayerTabs — tab-based editor for text layers (replaces _LayerEditPanel)
// ─────────────────────────────────────────────────────────────────────────────

class _TextLayerTabs extends StatefulWidget {
  const _TextLayerTabs({
    super.key,
    required this.layer,
    required this.onUpdate,
    required this.onDelete,
    required this.onBringToFront,
    required this.onSendToBack,
  });

  final TextLayer layer;
  final void Function(TextLayer) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;

  @override
  State<_TextLayerTabs> createState() => _TextLayerTabsState();
}

class _TextLayerTabsState extends State<_TextLayerTabs> {
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

  void _applyStyle(TextLayer Function(TextLayer) fn) {
    widget.onUpdate(fn(widget.layer.copyWith(text: _ctrl.text)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: AppTheme.surface,
        child: Column(
          children: [
            TabBar(
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontTheme,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: AppTheme.fontTheme,
                fontSize: 11,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.abc, size: 18), text: 'Text', iconMargin: EdgeInsets.only(bottom: 2)),
                Tab(icon: Icon(Icons.palette_outlined, size: 18), text: 'Style', iconMargin: EdgeInsets.only(bottom: 2)),
                Tab(icon: Icon(Icons.auto_awesome_outlined, size: 18), text: 'Motion', iconMargin: EdgeInsets.only(bottom: 2)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTextTab(),
                  _buildStyleTab(),
                  _buildMotionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    final layer = widget.layer;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Z-order buttons row
          Row(
            children: [
              _SectionHeader(layer.isSubtitle ? 'Subtitle Layer' : 'Main Layer'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.flip_to_front, size: 16),
                tooltip: 'Bring to front',
                color: AppTheme.textMid,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onBringToFront,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.flip_to_back, size: 16),
                tooltip: 'Send to back',
                color: AppTheme.textMid,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onSendToBack,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text input
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _ctrl,
              style: slideLayerTextStyle(layer.fontStyle,
                  fontSize: 16,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.normal),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter text…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
              onChanged: (v) => widget.onUpdate(widget.layer.copyWith(text: v)),
            ),
          ),
          const SizedBox(height: 12),
          // Type toggle
          const _SectionHeader('Type'),
          const SizedBox(height: 8),
          Row(
            children: [
              _TypeButton(
                label: 'Main',
                icon: Icons.title,
                selected: !layer.isSubtitle,
                onTap: () => _applyStyle((l) => l.copyWith(isSubtitle: false)),
              ),
              const SizedBox(width: 8),
              _TypeButton(
                label: 'Subtitle',
                icon: Icons.short_text,
                selected: layer.isSubtitle,
                onTap: () => _applyStyle((l) => l.copyWith(isSubtitle: true)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Delete button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF6B6B)),
              label: const Text('Delete Layer', style: TextStyle(color: Color(0xFFFF6B6B))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: widget.onDelete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTab() {
    final layer = widget.layer;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font picker
          const _SectionHeader('Font'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SlideFontStyle.values.map((f) {
                final sel = layer.fontStyle == f;
                return GestureDetector(
                  onTap: () => _applyStyle((l) => l.copyWith(fontStyle: f)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 44,
                    margin: const EdgeInsets.only(right: 7),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.line, width: sel ? 1.5 : 1),
                    ),
                    child: Text(
                      f.label,
                      style: slideLayerTextStyle(f,
                          fontSize: 13,
                          color: sel ? AppTheme.primary : AppTheme.textMid,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Size slider
          const _SectionHeader('Size'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: layer.fontSize.clamp(12.0, 300.0),
                  min: 12, max: 300, divisions: 72,
                  label: '${layer.fontSize.round()}px',
                  onChanged: (v) => _applyStyle((l) => l.copyWith(fontSize: v)),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text('${layer.fontSize.round()}',
                    style: const TextStyle(color: AppTheme.textMid, fontSize: 12),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text color
          const _SectionHeader('Text Color'),
          const SizedBox(height: 8),
          _ColorDots(
            current: layer.color,
            onSelect: (c) => _applyStyle((l) => l.copyWith(color: c)),
          ),
          // Bar color (subtitle only)
          if (layer.isSubtitle) ...[
            const SizedBox(height: 12),
            const _SectionHeader('Bar Color'),
            const SizedBox(height: 8),
            _ColorDots(
              current: layer.barColor,
              onSelect: (c) => _applyStyle((l) => l.copyWith(barColor: c)),
            ),
          ],
          const SizedBox(height: 12),
          // Text background
          const _SectionHeader('Text Bg'),
          const SizedBox(height: 8),
          Row(
            children: SlideTextBg.values.map((bg) {
              final sel = layer.textBg == bg;
              return GestureDetector(
                onTap: () => _applyStyle((l) => l.copyWith(textBg: bg)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.line, width: sel ? 1.5 : 1),
                  ),
                  child: Center(
                    child: Text(bg.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.primary : AppTheme.textMid,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Outline / stroke
          const _SectionHeader('Outline'),
          const SizedBox(height: 8),
          Row(
            children: [0.0, 1.0, 2.0, 3.0].map((w) {
              final sel = layer.strokeWidth == w;
              final lbl = w == 0 ? 'Off' : w == 1 ? 'Thin' : w == 2 ? 'Med' : 'Bold';
              return GestureDetector(
                onTap: () => _applyStyle((l) => l.copyWith(strokeWidth: w)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.line, width: sel ? 1.5 : 1),
                  ),
                  child: Center(
                    child: Text(lbl,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.primary : AppTheme.textMid,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Letter spacing
          const _SectionHeader('Spacing'),
          const SizedBox(height: 8),
          Row(
            children: [
              (0.0, 'Normal'),
              (1.0, 'Wide'),
              (3.0, 'Wider'),
              (6.0, 'Max'),
            ].map(((double, String) entry) {
              final (sp, lbl) = entry;
              final sel = layer.letterSpacing == sp;
              return GestureDetector(
                onTap: () => _applyStyle((l) => l.copyWith(letterSpacing: sp)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.line, width: sel ? 1.5 : 1),
                  ),
                  child: Center(
                    child: Text(lbl,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: sel ? AppTheme.primary : AppTheme.textMid,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Rotation
          const _SectionHeader('Rotation'),
          const SizedBox(height: 4),
          Slider(
            value: layer.rotation.clamp(-180.0, 180.0),
            min: -180, max: 180, divisions: 72,
            label: '${layer.rotation.round()}°',
            onChanged: (v) => _applyStyle((l) => l.copyWith(rotation: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildMotionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('Animation'),
          const SizedBox(height: 8),
          _AnimationPickerRow(
            current: widget.layer.contentAnimation,
            onSelect: (anim) => widget.onUpdate(widget.layer.copyWith(contentAnimation: anim)),
            allowed: SlideContentAnimationX.textAnimations,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhotoLayerTabs — tab-based editor for photo layers
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoLayerTabs extends StatelessWidget {
  const _PhotoLayerTabs({super.key, required this.vm, required this.layer});
  final EditorViewModel vm;
  final PhotoLayer layer;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: AppTheme.surface,
        child: Column(
          children: [
            TabBar(
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontTheme,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: AppTheme.fontTheme,
                fontSize: 11,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.tune, size: 18), text: 'Adjust', iconMargin: EdgeInsets.only(bottom: 2)),
                Tab(icon: Icon(Icons.style_outlined, size: 18), text: 'Style', iconMargin: EdgeInsets.only(bottom: 2)),
                Tab(icon: Icon(Icons.auto_awesome_outlined, size: 18), text: 'Motion', iconMargin: EdgeInsets.only(bottom: 2)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAdjustTab(context),
                  _buildStyleTab(),
                  _buildMotionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustTab(BuildContext context) {
    final isCrop = vm.cropMode;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Z-order & Crop row
          Row(
            children: [
              const _SectionHeader('Photo Layer'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.flip_to_front, size: 16),
                tooltip: 'Bring to front',
                color: AppTheme.textMid,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => vm.bringToFront(layer.id, isPhoto: true),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.flip_to_back, size: 16),
                tooltip: 'Send to back',
                color: AppTheme.textMid,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => vm.sendToBack(layer.id, isPhoto: true),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: isCrop ? Colors.orangeAccent : AppTheme.textMid,
                  backgroundColor: isCrop ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => vm.toggleCropMode(),
                icon: const Icon(Icons.crop, size: 16),
                label: Text(isCrop ? 'Done' : 'Crop', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isCrop) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 13, color: Colors.orangeAccent),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Drag on photo to pan · Pinch to zoom',
                          style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Zoom', style: TextStyle(fontSize: 11, color: AppTheme.textMid, letterSpacing: 1)),
                  Slider(
                    value: layer.cropScale.clamp(1.0, 4.0),
                    min: 1.0, max: 4.0, divisions: 30,
                    label: '${layer.cropScale.toStringAsFixed(1)}×',
                    activeColor: Colors.orangeAccent,
                    onChanged: (v) => vm.updatePhotoLayer(layer.copyWith(cropScale: v)),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textMid,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => vm.updatePhotoLayer(
                        layer.copyWith(cropScale: 1.0, cropOffsetX: 0.0, cropOffsetY: 0.0),
                      ),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const _SectionHeader('Width'),
            const SizedBox(height: 4),
            Slider(
              value: layer.widthFraction.clamp(0.1, 1.0),
              min: 0.1, max: 1.0, divisions: 18,
              label: '${(layer.widthFraction * 100).round()}%',
              onChanged: (v) => vm.updatePhotoLayer(layer.copyWith(widthFraction: v)),
            ),
            const _SectionHeader('Height'),
            const SizedBox(height: 4),
            Slider(
              value: layer.heightFraction.clamp(0.1, 1.0),
              min: 0.1, max: 1.0, divisions: 18,
              label: '${(layer.heightFraction * 100).round()}%',
              onChanged: (v) => vm.updatePhotoLayer(layer.copyWith(heightFraction: v)),
            ),
            const _SectionHeader('Rotation'),
            const SizedBox(height: 4),
            Slider(
              value: layer.rotation.clamp(-180.0, 180.0),
              min: -180, max: 180, divisions: 72,
              label: '${layer.rotation.round()}°',
              onChanged: (v) => vm.updatePhotoLayer(layer.copyWith(rotation: v)),
            ),
            const SizedBox(height: 8),
            // Change photo button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Change Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMid,
                  side: const BorderSide(color: AppTheme.line),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => vm.pickImageForPhotoLayer(layer.id),
              ),
            ),
            const SizedBox(height: 8),
            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF6B6B)),
                label: const Text('Delete Layer', style: TextStyle(color: Color(0xFFFF6B6B))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => vm.deletePhotoLayer(layer.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shape
          const _SectionHeader('Shape'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PhotoShape.values.map((sh) => ChoiceChip(
              label: Text(sh.label),
              selected: layer.shape == sh,
              onSelected: (_) => vm.updatePhotoLayer(layer.copyWith(shape: sh)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          // Frame
          const _SectionHeader('Frame'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PhotoFrame.values.map((fr) => ChoiceChip(
              label: Text(fr.label),
              selected: layer.frame == fr,
              onSelected: (_) => vm.updatePhotoLayer(layer.copyWith(frame: fr)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          // Filter
          const _SectionHeader('Filter'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PhotoFilter.values.map((f) => ChoiceChip(
              label: Text(f.label),
              selected: layer.filter == f,
              onSelected: (_) => vm.updatePhotoLayer(layer.copyWith(filter: f)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMotionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('Animation'),
          const SizedBox(height: 8),
          _AnimationPickerRow(
            current: layer.contentAnimation,
            onSelect: (anim) => vm.updatePhotoLayer(layer.copyWith(contentAnimation: anim)),
            allowed: SlideContentAnimationX.photoAnimations,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SlideTabs — tab-based editor for slide-level settings
// ─────────────────────────────────────────────────────────────────────────────

class _SlideTabs extends StatelessWidget {
  const _SlideTabs({required this.slide, required this.viewModel});
  final Slide slide;
  final EditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: AppTheme.surface,
        child: Column(
          children: [
            TabBar(
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontTheme,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: AppTheme.fontTheme,
                fontSize: 11,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.image_outlined, size: 18), text: 'Canvas', iconMargin: EdgeInsets.only(bottom: 2)),
                Tab(icon: Icon(Icons.filter_outlined, size: 18), text: 'Style', iconMargin: EdgeInsets.only(bottom: 2)),
                Tab(icon: Icon(Icons.timer_outlined, size: 18), text: 'Timing', iconMargin: EdgeInsets.only(bottom: 2)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCanvasTab(),
                  _buildStyleTab(),
                  _buildTimingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('Background'),
          const SizedBox(height: 8),
          _BackgroundColorPicker(
            current: slide.backgroundColor,
            onSelect: (c) => viewModel.updateSelectedSlide(slide.copyWith(backgroundColor: c)),
          ),
          if (slide.imagePath != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const _SectionHeader('Photo Zoom'),
                const Spacer(),
                Text(
                  '${slide.photoScale.toStringAsFixed(1)}×',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => viewModel.updatePhotoTransform(scale: 1.0, offsetX: 0.0, offsetY: 0.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Text('Reset',
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: AppTheme.textMid,
                          fontSize: 11,
                        )),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.zoom_out, color: AppTheme.textMid, size: 16),
                Expanded(
                  child: Slider(
                    value: slide.photoScale.clamp(0.1, 4.0),
                    min: 0.1, max: 4.0,
                    onChanged: (v) => viewModel.updatePhotoTransform(
                      scale: v, offsetX: slide.photoOffsetX, offsetY: slide.photoOffsetY,
                    ),
                  ),
                ),
                const Icon(Icons.zoom_in, color: AppTheme.textMid, size: 16),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter
          const _SectionHeader('Filter'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PhotoFilter.values.map((filter) {
                final sel = slide.photoFilter == filter;
                return GestureDetector(
                  onTap: () => viewModel.updateSelectedSlide(slide.copyWith(photoFilter: filter)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: sel ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface2,
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.line, width: sel ? 1.5 : 1),
                    ),
                    child: Center(
                      child: Text(filter.label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontTheme,
                            color: sel ? AppTheme.primary : AppTheme.textMid,
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Overlay
          const _SectionHeader('Overlay'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SlideOverlay.values.map((ov) {
                final sel = slide.overlay == ov;
                return GestureDetector(
                  onTap: () => viewModel.updateSelectedSlide(slide.copyWith(overlay: ov)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: sel ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface2,
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.line, width: sel ? 1.5 : 1),
                    ),
                    child: Center(
                      child: Text(ov.label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontTheme,
                            color: sel ? AppTheme.primary : AppTheme.textMid,
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Photo shape
          const _SectionHeader('Photo Shape'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PhotoShape.values.map((sh) => ChoiceChip(
              label: Text(sh.label),
              selected: slide.photoShape == sh,
              onSelected: (_) => viewModel.updateSelectedSlide(slide.copyWith(photoShape: sh)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          // Photo frame
          const _SectionHeader('Photo Frame'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PhotoFrame.values.map((fr) => ChoiceChip(
              label: Text(fr.label),
              selected: slide.photoFrame == fr,
              onSelected: (_) => viewModel.updateSelectedSlide(slide.copyWith(photoFrame: fr)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transition
          const _SectionHeader('Transition'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TransitionEffect.values.map((effect) {
                final sel = slide.transition == effect;
                return GestureDetector(
                  onTap: () => viewModel.updateSelectedSlide(slide.copyWith(transition: effect)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: sel ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface2,
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.line, width: sel ? 1.5 : 1),
                    ),
                    child: Center(
                      child: Text(effect.label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontTheme,
                            color: sel ? AppTheme.primary : AppTheme.textMid,
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Duration slider
          Row(
            children: [
              const _SectionHeader('Duration'),
              const Spacer(),
              Text('${slide.durationSeconds}s',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: slide.durationSeconds.toDouble(),
            min: 2, max: 10, divisions: 8,
            onChanged: (v) => viewModel.updateSelectedSlide(slide.copyWith(durationSeconds: v.round())),
          ),
        ],
      ),
    );
  }
}

// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

// Compact animation picker row — shown in all three edit panels so the user
// can always access the slide-level entrance animation regardless of selection.
class _AnimationPickerRow extends StatelessWidget {
  const _AnimationPickerRow({
    required this.current,
    required this.onSelect,
    this.allowed,
  });
  final SlideContentAnimation current;
  final void Function(SlideContentAnimation) onSelect;
  final List<SlideContentAnimation>? allowed;

  @override
  Widget build(BuildContext context) {
    final animations = allowed ?? SlideContentAnimation.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 11, color: AppTheme.primary),
            const SizedBox(width: 4),
            const Text(
              'ANIMATION',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                color: AppTheme.textMid,
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: animations.map((anim) {
              final sel = current == anim;
              return GestureDetector(
                onTap: () => onSelect(anim),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: sel
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.surface2,
                    border: Border.all(
                      color: sel ? AppTheme.primary : AppTheme.line,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '${anim.emoji} ${anim.label}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: sel ? AppTheme.primary : AppTheme.textMid,
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.current, required this.onSelect});
  final SlideTextColor current;
  final void Function(SlideTextColor) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SlideTextColor.values.map((c) {
        final sel = c == current;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.color,
              border: Border.all(
                  color: sel ? AppTheme.primary : AppTheme.line,
                  width: sel ? 2.5 : 1),
              boxShadow: sel
                  ? [
                      BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 6)
                    ]
                  : null,
            ),
            child: sel
                ? Icon(Icons.check,
                    size: 16,
                    color:
                        c == SlideTextColor.white || c == SlideTextColor.cream ||
                        c == SlideTextColor.champagne || c == SlideTextColor.silver
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
    // Darks
    0xFF000000, 0xFF0D0D0D, 0xFF1A1A1A, 0xFF2C2C2C,
    0xFF1C1C2E, 0xFF1A1A2E, 0xFF2D1B1B, 0xFF1B2D1B,
    // Lights & warm neutrals
    0xFFFFFFFF, 0xFFF5F5F5, 0xFFFFF8F2, 0xFFF5F0E8,
    0xFFEDE0D4, 0xFFD4C5B0, 0xFFC9B9A0, 0xFFBDAD96,
    // Pastels & colors
    0xFFE8B4B8, 0xFFD4A5A5, 0xFFB5C4B1, 0xFFB8CCE0,
    0xFFC9B8D4, 0xFFF2D4A0, 0xFFC07842, 0xFF4A3728,
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

  static bool _isLight(int c) {
    final r = (c >> 16) & 0xFF;
    final g = (c >> 8) & 0xFF;
    final b = c & 0xFF;
    return (r * 299 + g * 587 + b * 114) / 1000 > 160;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((c) {
            final sel = c == widget.current;
            return GestureDetector(
              onTap: () {
                widget.onSelect(c);
                _hex.text = _toHex(c);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(c),
                  border: Border.all(
                    color: sel ? AppTheme.primary : AppTheme.line,
                    width: sel ? 2.5 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.45),
                              blurRadius: 6)
                        ]
                      : null,
                ),
                child: sel
                    ? Icon(Icons.check,
                        size: 14,
                        color: _isLight(c) ? Colors.black : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: _hex,
            style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.textDark,
                fontSize: 12),
            decoration: const InputDecoration(
              hintText: '#000000',
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              prefixIcon: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.palette_outlined,
                    size: 14, color: AppTheme.textMid),
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
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.line,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? AppTheme.primary : AppTheme.textMid),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: selected ? AppTheme.primary : AppTheme.textMid,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

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
    // Best image to show: background photo > first photo layer > nothing (show bg color)
    final thumbPath = slide.imagePath ??
        slide.photoLayers
            .where((pl) => pl.imagePath != null)
            .map((pl) => pl.imagePath!)
            .firstOrNull;

    final hasAnimation = slide.textLayers.any(
          (l) => l.contentAnimation != SlideContentAnimation.none) ||
        slide.photoLayers.any(
          (pl) => pl.contentAnimation != SlideContentAnimation.none);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 88,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.line,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background color always shown
              ColoredBox(color: Color(slide.backgroundColor)),
              // Best photo preview
              if (thumbPath != null)
                Image.file(File(thumbPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              // Subtle dark gradient so the number stays readable
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: isSelected ? AppTheme.primary : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Animation badge
              if (hasAnimation)
                const Positioned(
                  top: 3,
                  right: 3,
                  child: Text('✨', style: TextStyle(fontSize: 10)),
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
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
          color: AppTheme.primary.withValues(alpha: 0.08),
        ),
        child: const Icon(Icons.add, color: AppTheme.primary, size: 22),
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
                ? AppTheme.primary.withValues(alpha: 0.5)
                : AppTheme.line,
          ),
          color: musicName != null
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surface,
        ),
        child: Icon(Icons.music_note_outlined,
            color: musicName != null ? AppTheme.primary : AppTheme.textMid,
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
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Choose a Template',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Start with a pre-designed layout',
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.textMid,
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
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t.label,
                          style: TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(t.description,
                          style: TextStyle(
                              fontFamily: AppTheme.fontTheme,
                              color: AppTheme.textMid,
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

// ─────────────────────────────────────────────────────────────────────────────
// Music panel — inline, no Navigator.pop on close
// ─────────────────────────────────────────────────────────────────────────────

class _MusicPanel extends StatelessWidget {
  const _MusicPanel({
    required this.currentMusicName,
    required this.onSelect,
    required this.onRemove,
    this.closeOnSelect = false,
  });

  final String? currentMusicName;
  final void Function(String name) onSelect;
  final VoidCallback onRemove;
  final bool closeOnSelect;

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
    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          if (currentMusicName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 2),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentMusicName!,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onRemove();
                      if (closeOnSelect) Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: Color(0xFFFF6B6B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: _songs.map((song) {
                final isSel = currentMusicName == song.$1;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppTheme.primary.withValues(alpha: 0.2)
                          : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSel ? Icons.music_note : Icons.music_note_outlined,
                      color: isSel ? AppTheme.primary : AppTheme.textMid,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    song.$1,
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.textDark,
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(
                    song.$2,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.textMid,
                      fontSize: 11,
                    ),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.primary, size: 18)
                      : null,
                  onTap: () {
                    onSelect(song.$1);
                    if (closeOnSelect) Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section tab pill — the four tabs below the canvas
// ─────────────────────────────────────────────────────────────────────────────

class _SectionPill extends StatelessWidget {
  const _SectionPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.dotted = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool dotted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? Colors.white : AppTheme.textMid,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppTheme.textMid,
                ),
              ),
              if (dotted && !active) ...[
                const SizedBox(width: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder shown when a section tab is open but no layer is selected
// ─────────────────────────────────────────────────────────────────────────────

class _LayerPlaceholder extends StatelessWidget {
  const _LayerPlaceholder({
    required this.icon,
    required this.headline,
    required this.sub,
    required this.actions,
  });

  final IconData icon;
  final String headline;
  final String sub;
  final List<_PlaceholderAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppTheme.line),
              const SizedBox(height: 10),
              Text(
                headline,
                style: const TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.textMid,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderAction extends StatelessWidget {
  const _PlaceholderAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

