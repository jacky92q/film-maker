import 'package:film_maker/data/repositories/auth_repository.dart';
import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/data/services/firebase_auth_service.dart';
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
    final authRepository = AuthRepository(authService: FirebaseAuthService());
    final projectRepository =
        ProjectRepository(projectService: MockProjectService());

    return MaterialApp(
      title: 'Film Maker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _AuthGate(
        authRepository: authRepository,
        projectRepository: projectRepository,
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({
    required this.authRepository,
    required this.projectRepository,
  });

  final AuthRepository authRepository;
  final ProjectRepository projectRepository;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(authRepository: widget.authRepository);
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        final user = snapshot.data;
        if (user != null) {
          return HomeView(
            user: user,
            projectRepository: widget.projectRepository,
            onLogout: () => widget.authRepository.logout(),
          );
        }
        return LoginView(viewModel: _authViewModel);
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 110,
                  height: 110,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Film Maker',
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.gold,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tell your love story through film',
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.subtleText,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
