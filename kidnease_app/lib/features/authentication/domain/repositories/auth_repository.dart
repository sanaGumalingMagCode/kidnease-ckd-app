import '../entities/user.dart';

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Register a new user with email and password
  Future<User> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Sign in an existing user with email and password
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Get the current authenticated user
  User? get currentUser;
}
