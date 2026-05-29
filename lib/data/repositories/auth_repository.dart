import 'package:film_maker/data/services/firebase_auth_service.dart';
import 'package:film_maker/domain/models/user.dart';

class AuthRepository {
  AuthRepository({required FirebaseAuthService authService})
      : _authService = authService;

  final FirebaseAuthService _authService;

  Stream<User?> get authStateChanges => _authService.authStateChanges;
  User? get currentUser => _authService.currentUser;

  Future<User> login({required String email, required String password}) {
    return _authService.signIn(email: email, password: password);
  }

  Future<User> register({required String email, required String password}) {
    return _authService.register(email: email, password: password);
  }

  Future<void> logout() => _authService.signOut();
}
