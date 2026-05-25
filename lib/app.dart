import 'package:film_maker/data/repositories/auth_repository.dart';
import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/data/services/mock_auth_service.dart';
import 'package:film_maker/data/services/mock_project_service.dart';
import 'package:film_maker/domain/models/user.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/auth/view_models/auth_view_model.dart';
import 'package:film_maker/ui/features/auth/views/login_view.dart';
import 'package:film_maker/ui/features/home/views/home_view.dart';
import 'package:flutter/material.dart';

class FilmMakerApp extends StatelessWidget {
  const FilmMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository(authService: MockAuthService());
    final projectRepository =
        ProjectRepository(projectService: MockProjectService());

    return MaterialApp(
      title: 'Film Maker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _RootView(
        authRepository: authRepository,
        projectRepository: projectRepository,
      ),
    );
  }
}

class _RootView extends StatelessWidget {
  const _RootView({
    required this.authRepository,
    required this.projectRepository,
  });

  final AuthRepository authRepository;
  final ProjectRepository projectRepository;

  void _onLoggedIn(BuildContext context, User user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeView(
          user: user,
          projectRepository: projectRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginView(
      viewModel: AuthViewModel(authRepository: authRepository),
      onLoggedIn: (user) => _onLoggedIn(context, user),
    );
  }
}
