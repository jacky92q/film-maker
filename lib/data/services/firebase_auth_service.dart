import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:film_maker/domain/models/user.dart';

class FirebaseAuthService {
  final _auth = fb.FirebaseAuth.instance;

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().map(_toAppUser);
  }

  User? get currentUser => _toAppUser(_auth.currentUser);

  Future<User> signIn({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toAppUser(cred.user)!;
  }

  Future<User> register({required String email, required String password}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = cred.user!;
    final displayName = email.split('@').first;
    await fbUser.updateDisplayName(displayName);
    return User(id: fbUser.uid, name: displayName, email: email);
  }

  Future<void> signOut() => _auth.signOut();

  User? _toAppUser(fb.User? fbUser) {
    if (fbUser == null) return null;
    final name = fbUser.displayName?.isNotEmpty == true
        ? fbUser.displayName!
        : (fbUser.email ?? '').split('@').first;
    return User(id: fbUser.uid, name: name, email: fbUser.email ?? '');
  }
}
