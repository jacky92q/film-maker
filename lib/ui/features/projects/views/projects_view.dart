import 'package:film_maker/data/repositories/export_repository.dart';
import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/data/services/mock_export_service.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/ui/core/app_routes.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/editor/view_models/editor_view_model.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:film_maker/ui/features/projects/view_models/projects_view_model.dart';
import 'package:flutter/material.dart';


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
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'New Wedding Film',
          style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.cream),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Give your film a title to remember',
              style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.subtleText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.cream),
              decoration: const InputDecoration(
                hintText: 'e.g. Our Love Story',
                prefixIcon: Icon(Icons.movie_creation_outlined,
                    color: AppTheme.subtleText),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.subtleText)),
          ),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty && mounted) {
      final project = await widget.viewModel.createProject(title);
      if (project != null && mounted) {
        _openEditor(project);
      }
    }
  }

  void _openEditor(Project project) async {
    final exportRepo =
        ExportRepository(exportService: MockExportService());
    final updated = await Navigator.of(context).push<Project>(
      SlideUpPageRoute(
        builder: (_) => EditorView(
          viewModel: EditorViewModel(
            project: project,
            projectRepository: widget.projectRepository,
          ),
          exportRepository: exportRepo,
        ),
      ),
    );
    if (updated != null) {
      widget.viewModel.updateProjectInList(updated);
    }
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Film?',
            style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.cream)),
        content: Text(
          '"${project.title}" will be permanently deleted.',
          style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.subtleText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.subtleText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.viewModel.deleteProject(project.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Wedding Films',
          style: TextStyle(fontFamily: AppTheme.fontTheme, 
              color: AppTheme.cream, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.error != null) {
            return _buildError();
          }

          if (widget.viewModel.projects.isEmpty) {
            return _buildEmptyState();
          }

          return _buildProjectGrid();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewProjectDialog,
        icon: const Icon(Icons.add),
        label: Text('New Film', style: TextStyle(fontFamily: AppTheme.fontTheme, fontWeight: FontWeight.w700)),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_creation_outlined,
              color: AppTheme.gold.withValues(alpha: 0.5), size: 72),
          const SizedBox(height: 16),
          Text(
            'No films yet',
            style: TextStyle(fontFamily: AppTheme.fontTheme, 
                color: AppTheme.cream, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create\nyour first wedding film',
            style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.subtleText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.gold, size: 48),
          const SizedBox(height: 12),
          Text(
            widget.viewModel.error!,
            style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.subtleText),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: widget.viewModel.loadProjects,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  final Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
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
                    style: TextStyle(fontFamily: AppTheme.fontTheme, 
                      color: AppTheme.cream,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: AppTheme.subtleText, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${project.slideCount} slides',
                        style: TextStyle(fontFamily: AppTheme.fontTheme, 
                            color: AppTheme.subtleText, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(project.updatedAt),
                    style: TextStyle(fontFamily: AppTheme.fontTheme, 
                        color: AppTheme.subtleText, fontSize: 10),
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
    final colors = [
      [const Color(0xFFFFE4EE), const Color(0xFFFFCFE3)],
      [const Color(0xFFE4EEFF), const Color(0xFFCFDFFF)],
      [const Color(0xFFE8F5E9), const Color(0xFFD0EDD1)],
      [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
    ];
    final palette = colors[project.id.hashCode % colors.length];

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.08,
              child: Icon(Icons.movie_creation,
                  size: 60, color: AppTheme.gold),
            ),
            if (project.musicName != null)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note,
                          color: AppTheme.gold, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        'Music',
                        style: TextStyle(fontFamily: AppTheme.fontTheme,
                            color: AppTheme.gold, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
