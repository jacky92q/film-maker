import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/domain/models/user.dart';
import 'package:film_maker/l10n/app_strings.dart';
import 'package:film_maker/l10n/locale_controller.dart';
import 'package:film_maker/ui/core/app_routes.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/editor/view_models/editor_view_model.dart';
import 'package:film_maker/ui/features/editor/views/editor_view.dart';
import 'package:film_maker/ui/features/home/view_models/home_view_model.dart';
import 'package:film_maker/ui/features/projects/view_models/projects_view_model.dart';
import 'package:film_maker/ui/features/projects/views/projects_view.dart';
import 'package:film_maker/ui/features/settings/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _MenuAction { settings, logout }

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

  void _goToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
  }

  void _goToProjects() {
    Navigator.of(context).push(
      SlideUpPageRoute(
        builder: (_) => ProjectsView(
          viewModel: ProjectsViewModel(projectRepository: widget.projectRepository),
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
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim());
              },
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
        ),
      ),
    );
    _viewModel.loadStats();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 28),
                  _buildSectionTitle(L10n.s.quickActions),
                  const SizedBox(height: 14),
                  _buildActionCards(),
                  const SizedBox(height: 28),
                  _buildSectionTitle(L10n.s.tipsTitle),
                  const SizedBox(height: 14),
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
      backgroundColor: AppTheme.bg,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Film Maker',
            style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              switch (action) {
                case _MenuAction.settings:
                  _goToSettings();
                case _MenuAction.logout:
                  widget.onLogout();
              }
            },
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.line),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.settings,
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, color: AppTheme.textMid, size: 18),
                    const SizedBox(width: 10),
                    Text(L10n.s.settings,
                        style: const TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textDark, fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.logout,
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppTheme.textMid, size: 18),
                    const SizedBox(width: 10),
                    Text(L10n.s.signOut,
                        style: const TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textDark, fontSize: 14)),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: Text(
                widget.user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1F0A), Color(0xFF7B3F18), Color(0xFFC07842)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.movie_creation, size: 180, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        L10n.s.welcomeBack,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  L10n.s.appTagline,
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  child: FilledButton(
                    onPressed: _showNewFilmDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.fontTheme,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 6),
                        Text(L10n.s.newFilm),
                      ],
                    ),
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
            _buildStatCard(icon: Icons.movie_outlined, value: _viewModel.projectCount.toString(), label: L10n.s.statFilms),
            const SizedBox(width: 12),
            _buildStatCard(icon: Icons.photo_library_outlined, value: _viewModel.totalSlides.toString(), label: L10n.s.statSlides),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textMid, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTheme.fontTheme,
        color: AppTheme.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.video_library_outlined,
            title: L10n.s.myFilms,
            subtitle: L10n.s.myFilmsSub,
            cardColor: AppTheme.primary,
            onTap: _goToProjects,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_circle_outline,
            title: L10n.s.newFilm,
            subtitle: L10n.s.newFilmSub,
            cardColor: const Color(0xFF1AA38C),
            onTap: _showNewFilmDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilmInspiration() {
    final tips = [
      (Icons.photo_camera_outlined, AppTheme.primary, L10n.s.tip1),
      (Icons.music_note_outlined, const Color(0xFF1AA38C), L10n.s.tip2),
      (Icons.auto_awesome_outlined, const Color(0xFF6B5CE7), L10n.s.tip3),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: tips.asMap().entries.map((entry) {
          final i = entry.key;
          final tip = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: tip.$2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tip.$1, color: tip.$2, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tip.$3,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontTheme,
                          color: AppTheme.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < tips.length - 1)
                const Divider(height: 1, indent: 66, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}
