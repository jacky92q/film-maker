import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    await widget.viewModel.register(
      email: _emailController.text.trim(),
      password: password,
    );
    // On success, auth state stream triggers navigation in app.dart
    if (mounted && widget.viewModel.error == null) {
      Navigator.of(context).pop();
    }
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
                  const SizedBox(height: 48),
                  _buildHeader(context),
                  const SizedBox(height: 40),
                  _buildForm(),
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.cream, size: 20),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold, width: 1.5),
            color: AppTheme.darkSurface,
          ),
          child: const Icon(Icons.person_add_outlined,
              color: AppTheme.gold, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.cream,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start telling your story',
          style: TextStyle(
            fontFamily: AppTheme.fontTheme,
            color: AppTheme.subtleText,
            fontSize: 13,
          ),
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppTheme.cream),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 6 characters',
                hintStyle:
                    const TextStyle(color: AppTheme.subtleText, fontSize: 12),
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: AppTheme.cream),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon:
                    const Icon(Icons.lock_outline, color: AppTheme.subtleText),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.subtleText,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              onSubmitted: (_) => _handleRegister(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: widget.viewModel.isLoading ? null : _handleRegister,
                child: widget.viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg),
                      )
                    : const Text('Create Account'),
              ),
            ),
            if (widget.viewModel.error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: widget.viewModel.error!),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.subtleText,
                      fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
