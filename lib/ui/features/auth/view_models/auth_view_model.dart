import 'package:film_maker/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository}) : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.login(email: email, password: password);
      return true;
    } catch (_) {
      _error = 'Login failed. Check email/password.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
