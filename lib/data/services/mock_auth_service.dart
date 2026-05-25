class MockAuthService {
  Future<Map<String, String>> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (email.isEmpty || password.length < 4) {
      throw Exception('Invalid credentials');
    }

    return {
      'id': 'u1',
      'name': 'Wedding Creator',
      'email': email,
    };
  }
}
