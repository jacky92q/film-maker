import 'package:film_maker/data/repositories/auth_repository.dart';
import 'package:film_maker/domain/models/user.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _error;
  User? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email: email, password: password);
    } catch (_) {
      _error = 'Invalid credentials. Try any email with 4+ char password.';
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _user;
  }
}
