import 'package:film_maker/data/services/mock_auth_service.dart';
import 'package:film_maker/domain/models/user.dart';

class AuthRepository {
  AuthRepository({required MockAuthService authService})
      : _authService = authService;

  final MockAuthService _authService;

  Future<User> login({required String email, required String password}) {
    return _authService.login(email: email, password: password);
  }
}
