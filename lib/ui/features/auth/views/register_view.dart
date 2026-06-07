import 'package:film_maker/l10n/app_strings.dart';
import 'package:film_maker/l10n/locale_controller.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:film_maker/ui/core/responsive.dart';
import 'package:film_maker/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        SnackBar(content: Text(L10n.s.passwordsDoNotMatch)),
      );
      return;
    }
    await widget.viewModel.register(
      email: _emailController.text.trim(),
      password: password,
    );
    if (mounted && widget.viewModel.error == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          _buildHeroSection(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ResponsiveCenter(maxWidth: 440, child: _buildForm()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
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
          Positioned(
            right: -30,
            top: -20,
            child: Opacity(
              opacity: 0.07,
              child: Icon(Icons.movie_creation, size: 180, color: Colors.white),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          L10n.s.createAccountTitle,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontTheme,
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          L10n.s.registerSubtitle,
                          style: TextStyle(
                            fontFamily: AppTheme.fontTheme,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
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
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: L10n.s.password,
                hintText: L10n.s.passwordHintRegister,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: L10n.s.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              onSubmitted: (_) => _handleRegister(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
              ),
              onPressed: widget.viewModel.isLoading ? null : _handleRegister,
              child: widget.viewModel.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(L10n.s.createAccountButton),
            ),
            if (widget.viewModel.error != null) ...[
              const SizedBox(height: 14),
              _ErrorBanner(message: widget.viewModel.error!),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  L10n.s.alreadyHaveAccount,
                  style: TextStyle(fontFamily: AppTheme.fontTheme, color: AppTheme.textMid, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    L10n.s.signIn,
                    style: TextStyle(
                      fontFamily: AppTheme.fontTheme,
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
        color: const Color(0xFFE85D4A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE85D4A).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE85D4A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontFamily: AppTheme.fontTheme, color: Color(0xFFE85D4A), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
