import 'package:film_maker/data/repositories/auth_repository.dart';
import 'package:film_maker/l10n/app_strings.dart';
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
      return L10n.s.errIncorrectCredentials;
    }
    if (message.contains('email-already-in-use')) {
      return L10n.s.errEmailInUse;
    }
    if (message.contains('weak-password')) {
      return L10n.s.errWeakPassword;
    }
    if (message.contains('invalid-email')) {
      return L10n.s.errInvalidEmail;
    }
    if (message.contains('network-request-failed') ||
        message.contains('network_error')) {
      return L10n.s.errNetwork;
    }
    if (message.contains('too-many-requests')) {
      return L10n.s.errTooManyRequests;
    }
    if (message.contains('operation-not-allowed')) {
      return L10n.s.errOperationNotAllowed;
    }
    if (message.contains('sign_in_failed') ||
        message.contains('ApiException') ||
        message.contains('DEVELOPER_ERROR')) {
      return L10n.s.errGoogleSignIn;
    }
    return L10n.s.errGeneric;
  }
}
