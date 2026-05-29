import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/auth/view_models/auth_view_model.dart';
import 'package:film_maker/ui/features/auth/views/register_view.dart';
import 'package:flutter/material.dart';

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
    // Auth state stream in app.dart handles navigation on success
  }

  void _goToRegister() {
    widget.viewModel.clearError();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterView(viewModel: widget.viewModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 72),
                  _buildLogo(),
                  const SizedBox(height: 48),
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

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D0D), Color(0xFF111118), Color(0xFF0D0D0D)],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold, width: 1.5),
            color: AppTheme.darkSurface,
          ),
          child: const Icon(Icons.movie_creation_outlined,
              color: AppTheme.gold, size: 32),
        ),
        const SizedBox(height: 20),
        Text(
          'Film Maker',
          style: TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.cream,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: AppTheme.gold),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Make film with your special memories.',
                style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.subtleText,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(width: 24, height: 1, color: AppTheme.gold),
          ],
        ),
      ],
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
              style: const TextStyle(color: AppTheme.cream),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon:
                    Icon(Icons.email_outlined, color: AppTheme.subtleText),
              ),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppTheme.cream),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon:
                    const Icon(Icons.lock_outline, color: AppTheme.subtleText),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.subtleText,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: widget.viewModel.isLoading ? null : _handleLogin,
                child: widget.viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg),
                      )
                    : const Text('Sign In'),
              ),
            ),
            if (widget.viewModel.error != null) ...[
              const SizedBox(height: 16),
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
        Expanded(child: Container(height: 1, color: AppTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.subtleText,
                fontSize: 13),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.border)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.viewModel.isLoading
                ? null
                : () => widget.viewModel.loginWithGoogle(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3C3C3C)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF1E1E1E),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleLogo(),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontFamily: AppTheme.fontTheme,
                    color: AppTheme.cream,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
          "Don't have an account? ",
          style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.subtleText,
              fontSize: 14),
        ),
        GestureDetector(
          onTap: _goToRegister,
          child: Text(
            'Register',
            style: TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.gold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
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
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: const Color(0xFFFF6B6B),
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
