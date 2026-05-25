import 'package:film_maker/data/repositories/auth_repository.dart';
import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/data/services/mock_auth_service.dart';
import 'package:film_maker/data/services/mock_project_service.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/auth/view_models/auth_view_model.dart';
import 'package:film_maker/ui/features/auth/views/login_view.dart';
import 'package:film_maker/ui/features/projects/view_models/projects_view_model.dart';
import 'package:film_maker/ui/features/projects/views/projects_view.dart';
import 'package:flutter/material.dart';

class FilmMakerApp extends StatelessWidget {
  const FilmMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository(authService: MockAuthService());
    final projectRepository = ProjectRepository(projectService: MockProjectService());

    return MaterialApp(
      title: 'Film Maker',
      theme: AppTheme.light(),
      home: LoginView(
        viewModel: AuthViewModel(authRepository: authRepository),
        onLoggedIn: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ProjectsView(
                viewModel: ProjectsViewModel(projectRepository: projectRepository),
              ),
            ),
          );
        },
      ),
    );
  }
}
