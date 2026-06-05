import 'package:film_maker/l10n/app_strings.dart';
import 'package:film_maker/l10n/locale_controller.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/auth/view_models/auth_view_model.dart';
import 'package:film_maker/ui/features/auth/views/register_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.viewModel});
  final AuthViewModel viewModel;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    await widget.viewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _goToRegister() {
    widget.viewModel.clearError();
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => RegisterView(viewModel: widget.viewModel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          _buildHeroSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildForm(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildGoogleButton(),
                  const SizedBox(height: 28),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1F0A), Color(0xFF7B3F18), Color(0xFFC07842)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Decorative film strip pattern
          Positioned(
            right: -30,
            top: -30,
            child: Opacity(
              opacity: 0.07,
              child: Icon(Icons.movie_creation, size: 220, color: Colors.white),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.05,
              child:
                  Icon(Icons.photo_camera_back, size: 160, color: Colors.white),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.movie_creation_outlined,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    L10n.s.loginHeroTitle,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    L10n.s.loginHeroSubtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: L10n.s.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: L10n.s.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: widget.viewModel.isLoading ? null : _handleLogin,
                child: widget.viewModel.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(L10n.s.signIn),
              ),
            ),
            if (widget.viewModel.error != null) ...[
              const SizedBox(height: 14),
              _ErrorBanner(message: widget.viewModel.error!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppTheme.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(L10n.s.orDivider,
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.textMid,
                  fontSize: 13)),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.line)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: widget.viewModel.isLoading
                ? null
                : () => widget.viewModel.loginWithGoogle(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              side: const BorderSide(color: AppTheme.line, width: 1.5),
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleLogo(),
                const SizedBox(width: 12),
                Text(
                  L10n.s.signInWithGoogle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          L10n.s.dontHaveAccount,
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.textMid,
              fontSize: 14),
        ),
        GestureDetector(
          onTap: _goToRegister,
          child: Text(
            L10n.s.register,
            style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/google_logo.svg',
      width: 22,
      height: 22,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE85D4A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFE85D4A).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE85D4A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: Color(0xFFE85D4A),
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
