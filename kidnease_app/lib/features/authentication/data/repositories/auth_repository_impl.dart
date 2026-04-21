import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Implementation of AuthRepository using Firebase
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;

  AuthRepositoryImpl({required FirebaseAuthDatasource datasource})
      : _datasource = datasource;

  @override
  Future<User> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _datasource.registerWithEmail(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _datasource.signInWithEmail(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    return await _datasource.signOut();
  }

  @override
  Stream<User?> get authStateChanges => _datasource.authStateChanges;

  @override
  User? get currentUser {
    // Note: This is synchronous, so we can't fetch from Firestore here
    // The actual user data should be managed by a state provider
    // that listens to authStateChanges
    return null;
  }
}
