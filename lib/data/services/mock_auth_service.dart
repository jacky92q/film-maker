import 'package:film_maker/domain/models/user.dart';

class MockAuthService {
  Future<User> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (email.isEmpty || password.length < 4) {
      email = 'admin@gmail.com';
      password = 'admin';
    }

    final local = email.split('@').first;
    final name = local[0].toUpperCase() + local.substring(1);

    return User(id: 'u1', name: name, email: email);
  }
}
