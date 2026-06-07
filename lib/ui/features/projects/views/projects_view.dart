import 'dart:io';

import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/l10n/app_strings.dart';
import 'package:film_maker/l10n/locale_controller.dart';
import 'package:film_maker/ui/core/app_routes.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/editor/view_models/editor_view_model.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:film_maker/ui/features/projects/view_models/projects_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({
    super.key,
    required this.viewModel,
    required this.projectRepository,
  });

  final ProjectsViewModel viewModel;
  final ProjectRepository projectRepository;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadProjects();
  }

  Future<void> _showNewProjectDialog() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.s.newWeddingFilm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.s.filmTitlePrompt),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                hintText: L10n.s.filmTitleHint,
                prefixIcon: const Icon(Icons.movie_creation_outlined),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(L10n.s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: Text(L10n.s.create),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty && mounted) {
      final project = await widget.viewModel.createProject(title);
      if (project != null && mounted) _openEditor(project);
    }
  }

  void _openEditor(Project project) async {
    final updated = await Navigator.of(context).push<Project>(
      SlideUpPageRoute(
        builder: (_) => EditorView(
          viewModel: EditorViewModel(
            project: project,
            projectRepository: widget.projectRepository,
          ),
        ),
      ),
    );
    if (updated != null) widget.viewModel.upsertProjectInList(updated);
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.s.deleteFilmTitle),
        content: Text(L10n.s.deleteFilmConfirm(project.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L10n.s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE85D4A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L10n.s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.viewModel.deleteProject(project.id);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(L10n.s.myWeddingFilms),
        backgroundColor: AppTheme.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.viewModel.error != null) return _buildError();
          if (widget.viewModel.projects.isEmpty) return _buildEmptyState();
          return _buildProjectGrid();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewProjectDialog,
        icon: const Icon(Icons.add),
        label: Text(L10n.s.newFilm,
            style: const TextStyle(fontFamily: AppTheme.fontTheme, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildProjectGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: widget.viewModel.projects.length,
      itemBuilder: (context, index) {
        final project = widget.viewModel.projects[index];
        return _ProjectCard(
          project: project,
          onTap: () => _openEditor(project),
          onDelete: () => _confirmDelete(project),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.movie_creation_outlined, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              L10n.s.noFilmsYet,
              style: const TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.s.noFilmsSub,
              style: const TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textMid, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE85D4A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Color(0xFFE85D4A), size: 32),
          ),
          const SizedBox(height: 16),
          Text(widget.viewModel.error!,
              style: const TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textMid)),
          const SizedBox(height: 16),
          FilledButton(onPressed: widget.viewModel.loadProjects, child: Text(L10n.s.tryAgain)),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap, required this.onDelete});

  final Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return L10n.s.today;
    if (diff.inDays == 1) return L10n.s.yesterday;
    if (diff.inDays < 7) return L10n.s.daysAgo(diff.inDays);
    return '${dt.year}.${dt.month}.${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.photo_library_outlined, color: AppTheme.textMid, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        L10n.s.slidesCount(project.slideCount),
                        style: const TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textMid, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(project.updatedAt),
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.textMid.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // Resolve the best photo path from the first slide.
    String? photoPath;
    if (project.slides.isNotEmpty) {
      final first = project.slides.first;
      photoPath = first.imagePath;
      if ((photoPath == null || photoPath.isEmpty) &&
          first.photoLayers.isNotEmpty) {
        photoPath = first.photoLayers.first.imagePath;
      }
    }

    // Palette used as fallback when no photo is available.
    final palettes = [
      [const Color(0xFF3B1F0A), const Color(0xFFC07842)],
      [const Color(0xFF0A2A1F), const Color(0xFF1AA38C)],
      [const Color(0xFF1A0A2A), const Color(0xFF6B5CE7)],
      [const Color(0xFF2A1A0A), const Color(0xFFE8963C)],
    ];
    final palette = palettes[project.id.hashCode % palettes.length];

    final hasPhoto = photoPath != null && photoPath.isNotEmpty;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: real photo or gradient fallback.
          if (hasPhoto)
            Image.file(
              File(photoPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _gradientBox(palette),
            )
          else
            _gradientBox(palette),

          // Faint movie icon on gradient-only cards.
          if (!hasPhoto)
            const Center(
              child: Opacity(
                opacity: 0.15,
                child: Icon(Icons.movie_creation, size: 52, color: Colors.white),
              ),
            ),

          // Subtle scrim so the music badge is readable over photos.
          if (project.musicName != null)
            const Positioned(
              bottom: 0, left: 0, right: 0,
              child: SizedBox(
                height: 32,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ),
            ),

          // Music badge.
          if (project.musicName != null)
            Positioned(
              bottom: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_note, color: Colors.white70, size: 10),
                    const SizedBox(width: 3),
                    Text(L10n.s.musicBadge,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontFamily: AppTheme.fontTheme)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gradientBox(List<Color> palette) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
      );
}
