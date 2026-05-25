import 'package:film_maker/data/services/mock_auth_service.dart';

class AuthRepository {
  AuthRepository({required MockAuthService authService}) : _authService = authService;

  final MockAuthService _authService;

  Future<bool> login({required String email, required String password}) async {
    await _authService.login(email: email, password: password);
    return true;
  }

}
