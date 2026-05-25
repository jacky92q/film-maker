import 'dart:io';

import 'package:film_maker/data/repositories/export_repository.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/editor/view_models/editor_view_model.dart';
import 'package:film_maker/ui/features/export/view_models/export_view_model.dart';
import 'package:film_maker/ui/features/export/views/export_view.dart';
import 'package:film_maker/ui/features/preview/view_models/preview_view_model.dart';
import 'package:film_maker/ui/features/preview/views/preview_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        content: Text(
          'Save your film before leaving?',
          style: GoogleFonts.lato(color: AppTheme.subtleText),
        ),
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
      MaterialPageRoute(
        builder: (_) => PreviewView(
          viewModel: PreviewViewModel(project: widget.viewModel.project),
        ),
      ),
    );
  }

  void _openExport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportView(
          viewModel: ExportViewModel(
            project: widget.viewModel.project,
            exportRepository: widget.exportRepository,
          ),
        ),
      ),
    );
  }

  void _showSlideEditSheet() {
    final slide = widget.viewModel.selectedSlide;
    if (slide == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SlideEditSheet(
        slide: slide,
        viewModel: widget.viewModel,
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
            return Column(
              children: [
                _buildSlideCanvas(),
                _buildEditControls(),
                _buildTimeline(),
              ],
            );
          },
        ),
      ),
    );
  }

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
              style: GoogleFonts.playfairDisplay(
                  color: AppTheme.cream, fontSize: 18),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
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
                    style: GoogleFonts.playfairDisplay(
                        color: AppTheme.cream, fontSize: 18),
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
          builder: (context, _) {
            return Row(
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
                  child: Text(
                    'Preview',
                    style:
                        GoogleFonts.lato(color: AppTheme.gold, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _openExport,
                  child: Text(
                    'Export',
                    style: GoogleFonts.lato(
                        color: AppTheme.cream, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlideCanvas() {
    final slide = widget.viewModel.selectedSlide;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _showSlideEditSheet,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBg,
            border: Border(
              bottom: BorderSide(
                  color: AppTheme.gold.withValues(alpha: 0.2)),
            ),
          ),
          child: slide == null
              ? const Center(
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.subtleText, size: 48))
              : _SlideCanvas(
                  slide: slide,
                  onTapPhoto: widget.viewModel.pickImageForCurrentSlide,
                ),
        ),
      ),
    );
  }

  Widget _buildEditControls() {
    final slide = widget.viewModel.selectedSlide;
    if (slide == null) return const SizedBox.shrink();

    return Container(
      color: AppTheme.darkSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ControlButton(
                icon: Icons.photo_camera_outlined,
                label: 'Photo',
                onTap: widget.viewModel.pickImageForCurrentSlide,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.text_fields,
                label: 'Text',
                onTap: _showSlideEditSheet,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.music_note_outlined,
                label: widget.viewModel.project.musicName ?? 'Music',
                onTap: () => _showMusicPicker(),
                highlighted: widget.viewModel.project.musicName != null,
              ),
              const Spacer(),
              if (widget.viewModel.project.slides.length > 1)
                IconButton(
                  onPressed: widget.viewModel.deleteSelectedSlide,
                  tooltip: 'Delete slide',
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFFF6B6B), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTransitionChips(slide),
        ],
      ),
    );
  }

  Widget _buildTransitionChips(Slide slide) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TransitionEffect.values.map((effect) {
          final selected = slide.transition == effect;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => widget.viewModel.updateSelectedSlide(
                slide.copyWith(transition: effect),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.gold.withValues(alpha: 0.2)
                      : AppTheme.darkSurface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        selected ? AppTheme.gold : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  effect.label,
                  style: GoogleFonts.lato(
                    color: selected ? AppTheme.gold : AppTheme.subtleText,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
                  return _AddSlideButton(onTap: widget.viewModel.addSlide);
                }
                final slide = widget.viewModel.project.slides[index];
                final isSelected =
                    index == widget.viewModel.selectedSlideIndex;
                return _SlideThumbnail(
                  slide: slide,
                  index: index,
                  isSelected: isSelected,
                  onTap: () => widget.viewModel.selectSlide(index),
                );
              },
            ),
          ),
        ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide canvas widget
// ─────────────────────────────────────────────────────────────────────────────

class _SlideCanvas extends StatelessWidget {
  const _SlideCanvas({required this.slide, required this.onTapPhoto});

  final Slide slide;
  final VoidCallback onTapPhoto;

  Alignment _textAlignment() {
    switch (slide.textPosition) {
      case TextPosition.topCenter:
        return Alignment.topCenter;
      case TextPosition.centerLeft:
        return Alignment.centerLeft;
      case TextPosition.center:
        return Alignment.center;
      case TextPosition.centerRight:
        return Alignment.centerRight;
      case TextPosition.bottomLeft:
        return Alignment.bottomLeft;
      case TextPosition.bottomCenter:
        return Alignment.bottomCenter;
      case TextPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(),
        _buildGradientOverlay(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: _textAlignment(),
            child: _buildTextOverlay(),
          ),
        ),
        if (slide.imagePath == null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onTapPhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    Text(
                      'Add Photo',
                      style: GoogleFonts.lato(
                          color: AppTheme.gold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackground() {
    if (slide.imagePath != null) {
      return Image.file(
        File(slide.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildGradientBg(),
      );
    }
    return _buildGradientBg();
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

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
          ],
          stops: const [0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildTextOverlay() {
    if (slide.title.isEmpty && slide.subtitle.isEmpty) {
      return Text(
        'Tap to add text...',
        style: GoogleFonts.playfairDisplay(
          color: AppTheme.subtleText.withValues(alpha: 0.6),
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (slide.title.isNotEmpty)
          Text(
            slide.title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        if (slide.title.isNotEmpty && slide.subtitle.isNotEmpty)
          const SizedBox(height: 4),
        if (slide.subtitle.isNotEmpty)
          Text(
            slide.subtitle,
            style: GoogleFonts.lato(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 6,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
      ],
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
            colors: [Color(0xFF1A1208), Color(0xFF0D0D0D)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (slide.imagePath != null)
                Image.file(
                  File(slide.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
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
          border: Border.all(
              color: AppTheme.gold.withValues(alpha: 0.5),
              style: BorderStyle.solid),
          color: AppTheme.gold.withValues(alpha: 0.08),
        ),
        child: const Icon(Icons.add, color: AppTheme.gold, size: 22),
      ),
    );
  }
}

class _MusicTimelineButton extends StatelessWidget {
  const _MusicTimelineButton(
      {required this.musicName, required this.onTap});
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
        child: Icon(
          Icons.music_note_outlined,
          color: musicName != null ? AppTheme.gold : AppTheme.subtleText,
          size: 20,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted
              ? AppTheme.gold.withValues(alpha: 0.15)
              : AppTheme.darkSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted ? AppTheme.gold.withValues(alpha: 0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: highlighted ? AppTheme.gold : AppTheme.subtleText,
                size: 15),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                label,
                style: GoogleFonts.lato(
                  color: highlighted ? AppTheme.gold : AppTheme.subtleText,
                  fontSize: 12,
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
// Bottom sheets
// ─────────────────────────────────────────────────────────────────────────────

class _SlideEditSheet extends StatefulWidget {
  const _SlideEditSheet({required this.slide, required this.viewModel});

  final Slide slide;
  final EditorViewModel viewModel;

  @override
  State<_SlideEditSheet> createState() => _SlideEditSheetState();
}

class _SlideEditSheetState extends State<_SlideEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late Slide _slide;

  @override
  void initState() {
    super.initState();
    _slide = widget.slide;
    _titleCtrl = TextEditingController(text: _slide.title);
    _subtitleCtrl = TextEditingController(text: _slide.subtitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.viewModel.updateSelectedSlide(
      _slide.copyWith(
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit Slide',
            style: GoogleFonts.playfairDisplay(
                color: AppTheme.cream, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppTheme.cream),
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. The Day We Met',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitleCtrl,
            style: const TextStyle(color: AppTheme.cream),
            decoration: const InputDecoration(
              labelText: 'Subtitle',
              hintText: 'e.g. Seoul, Spring 2024',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Duration',
            style: GoogleFonts.lato(
                color: AppTheme.subtleText, fontSize: 13),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _slide.durationSeconds.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  onChanged: (v) =>
                      setState(() => _slide = _slide.copyWith(durationSeconds: v.round())),
                ),
              ),
              Text(
                '${_slide.durationSeconds}s',
                style: GoogleFonts.lato(
                    color: AppTheme.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _save, child: const Text('Apply')),
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

  static const _sampleSongs = [
    ('A Thousand Years', 'Christina Perri'),
    ('Perfect', 'Ed Sheeran'),
    ('All of Me', 'John Legend'),
    ('Can\'t Help Falling in Love', 'Elvis Presley'),
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
              Text(
                'Choose a Song',
                style: GoogleFonts.playfairDisplay(
                    color: AppTheme.cream,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (currentMusicName != null)
                TextButton(
                  onPressed: () {
                    onRemove();
                    Navigator.of(context).pop();
                  },
                  child: Text('Remove',
                      style: GoogleFonts.lato(
                          color: const Color(0xFFFF6B6B), fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sample songs for demo — connect real library for production',
            style: GoogleFonts.lato(color: AppTheme.subtleText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ..._sampleSongs.map((song) {
            final isSelected = currentMusicName == song.$1;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.gold.withValues(alpha: 0.2)
                      : AppTheme.darkSurface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected ? Icons.music_note : Icons.music_note_outlined,
                  color: isSelected ? AppTheme.gold : AppTheme.subtleText,
                  size: 18,
                ),
              ),
              title: Text(song.$1,
                  style: GoogleFonts.lato(
                      color: AppTheme.cream,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400)),
              subtitle: Text(song.$2,
                  style: GoogleFonts.lato(
                      color: AppTheme.subtleText, fontSize: 12)),
              trailing: isSelected
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
