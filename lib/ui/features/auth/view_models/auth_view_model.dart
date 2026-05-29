import 'package:film_maker/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepository.login(email: email, password: password);
    } catch (e) {
      _error = _mapError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepository.loginWithGoogle();
      // null means user cancelled — no error needed
    } catch (e) {
      _error = _mapError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepository.register(email: email, password: password);
    } catch (e) {
      _error = _mapError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapError(String message) {
    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('network-request-failed') ||
        message.contains('network_error')) {
      return 'Network error. Check your connection.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (message.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Contact the app admin.';
    }
    if (message.contains('sign_in_failed') ||
        message.contains('ApiException') ||
        message.contains('DEVELOPER_ERROR')) {
      return 'Google Sign-In failed. Android SHA-1 fingerprint may need to be registered in Firebase Console.';
    }
    return 'Something went wrong. Please try again.';
  }
}
