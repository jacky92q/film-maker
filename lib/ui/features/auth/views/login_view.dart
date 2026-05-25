import 'package:film_maker/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.viewModel, required this.onLoggedIn});

  final AuthViewModel viewModel;
  final VoidCallback onLoggedIn;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();

  }

  @override  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Film Maker Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.viewModel.isLoading
                        ? null
                        : () async {
                            final ok = await widget.viewModel.login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                            if (ok && mounted) widget.onLoggedIn();
                          },
                    child: Text(widget.viewModel.isLoading ? 'Loading...' : 'Login'),
                  ),
                ),
                if (widget.viewModel.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.viewModel.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
