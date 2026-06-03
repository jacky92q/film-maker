import 'package:film_maker/data/repositories/export_repository.dart';
import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/data/services/mock_export_service.dart';
import 'package:film_maker/domain/models/user.dart';
import 'package:film_maker/ui/core/app_routes.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/editor/view_models/editor_view_model.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:film_maker/ui/features/home/view_models/home_view_model.dart';
import 'package:film_maker/ui/features/projects/view_models/projects_view_model.dart';
import 'package:film_maker/ui/features/projects/views/projects_view.dart';
import 'package:flutter/material.dart';

enum _MenuAction { logout }

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.user,
    required this.projectRepository,
    required this.onLogout,
  });

  final User user;
  final ProjectRepository projectRepository;
  final VoidCallback onLogout;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      user: widget.user,
      projectRepository: widget.projectRepository,
    );
    _viewModel.loadStats();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _goToProjects() {
    Navigator.of(context).push(
      SlideUpPageRoute(
        builder: (_) => ProjectsView(
          viewModel: ProjectsViewModel(
            projectRepository: widget.projectRepository,
          ),
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  Future<void> _showNewFilmDialog() async {
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
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.subtleText,
                  fontSize: 13),
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
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.subtleText)),
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
    if (title == null || title.isEmpty || !mounted) return;

    final vm = ProjectsViewModel(projectRepository: widget.projectRepository);
    final project = await vm.createProject(title);
    if (project == null || !mounted) return;

    await Navigator.of(context).push(
      SlideUpPageRoute(
        builder: (_) => EditorView(
          viewModel: EditorViewModel(
            project: project,
            projectRepository: widget.projectRepository,
          ),
          exportRepository: ExportRepository(exportService: MockExportService()),
        ),
      ),
    );
    _viewModel.loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Create & Explore'),
                  const SizedBox(height: 16),
                  _buildActionCards(),
                  const SizedBox(height: 28),
                  _buildFilmInspiration(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppTheme.darkSurface,
      title: Text(
        'Film Maker',
        style: TextStyle(
          fontFamily: AppTheme.fontTheme,
          color: AppTheme.cream,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              if (action == _MenuAction.logout) widget.onLogout();
            },
            color: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.border),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.logout,
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppTheme.subtleText, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: AppTheme.cream,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.darkSurface2,
              child: Text(
                widget.user.name[0].toUpperCase(),
                style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F4), Color(0xFFFFE0EC), Color(0xFFFCF5F8)],
        ),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child:
                  Icon(Icons.movie_creation, size: 180, color: AppTheme.gold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(width: 28, height: 2, color: AppTheme.gold),
                    const SizedBox(width: 8),
                    Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        color: AppTheme.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.cream,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell your love story through film',
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.subtleText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Row(
          children: [
            _buildStatCard(
              icon: Icons.movie_outlined,
              value: _viewModel.projectCount.toString(),
              label: 'Films',
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.photo_library_outlined,
              value: _viewModel.totalSlides.toString(),
              label: 'Total Slides',
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.favorite_outline,
              value: 'Wedding',
              label: 'Theme',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.gold, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.cream,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.subtleText,
                  fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: AppTheme.gold),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.cream,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F4), Color(0xFFFFDEEB)],
            ),
            icon: Icons.video_library_outlined,
            title: 'My Films',
            subtitle: 'View & edit your projects',
            onTap: _goToProjects,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F4FF), Color(0xFFDEE8FF)],
            ),
            icon: Icons.add_circle_outline,
            title: 'New Film',
            subtitle: 'Start a new story',
            onTap: _showNewFilmDialog,
            iconColor: const Color(0xFF4B7BFF),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required Gradient gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppTheme.gold,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.cream,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.subtleText,
                      fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilmInspiration() {
    final tips = [
      ('🌸', 'Choose photos that tell a story'),
      ('🎵', 'Add a meaningful song for emotion'),
      ('✨', 'Use Ken Burns for cinematic feel'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tips for a perfect wedding film'),
        const SizedBox(height: 14),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(tip.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Text(
                  tip.$2,
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.subtleText,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
