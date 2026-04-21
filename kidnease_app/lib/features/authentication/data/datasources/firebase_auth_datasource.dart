import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user.dart' as domain;
import '../models/user_model.dart';

/// Firebase Authentication data source
class FirebaseAuthDatasource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDatasource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Register a new user with email and password
  Future<domain.User> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthenticationException('Failed to create user account');
      }

      // Create user profile in Firestore
      final userModel = UserModel(
        userId: credential.user!.uid,
        email: email,
        name: name,
        role: domain.UserRole.patient.toJson(),
        createdAt: Timestamp.now(),
        onboardingCompleted: false,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      logger.info('User registered successfully', context: {
        'userId': credential.user!.uid,
      });

      return userModel.toDomain();
    } on firebase_auth.FirebaseAuthException catch (e) {
      logger.error('Firebase Auth registration error', error: e, context: {
        'code': e.code,
      });
      throw AuthenticationException.fromFirebaseCode(e.code);
    } catch (e, stackTrace) {
      logger.error('Unexpected registration error', error: e, stackTrace: stackTrace);
      throw AuthenticationException('Registration failed: ${e.toString()}');
    }
  }

  /// Sign in an existing user with email and password
  Future<domain.User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthenticationException('Failed to sign in');
      }

      // Fetch user profile from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw const AuthenticationException('User profile not found');
      }

      logger.info('User signed in successfully', context: {
        'userId': credential.user!.uid,
      });

      return UserModel.fromFirestore(userDoc).toDomain();
    } on firebase_auth.FirebaseAuthException catch (e) {
      logger.error('Firebase Auth sign in error', error: e, context: {
        'code': e.code,
      });
      throw AuthenticationException.fromFirebaseCode(e.code);
    } catch (e, stackTrace) {
      logger.error('Unexpected sign in error', error: e, stackTrace: stackTrace);
      throw AuthenticationException('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      logger.info('User signed out successfully');
    } catch (e, stackTrace) {
      logger.error('Sign out error', error: e, stackTrace: stackTrace);
      throw AuthenticationException('Sign out failed: ${e.toString()}');
    }
  }

  /// Stream of authentication state changes
  Stream<domain.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) {
          return null;
        }

        return UserModel.fromFirestore(userDoc).toDomain();
      } catch (e) {
        logger.error('Error fetching user profile in auth state stream', error: e);
        return null;
      }
    });
  }

  /// Get the current authenticated user
  Future<domain.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromFirestore(userDoc).toDomain();
    } catch (e) {
      logger.error('Error fetching current user', error: e);
      return null;
    }
  }

  /// Get user profile from Firestore
  Future<domain.User> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw const AuthenticationException('User profile not found');
      }

      return UserModel.fromFirestore(userDoc).toDomain();
    } catch (e, stackTrace) {
      logger.error('Error fetching user profile', error: e, stackTrace: stackTrace);
      throw AuthenticationException('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile(domain.User user) async {
    try {
      final userModel = UserModel.fromDomain(user);
      await _firestore
          .collection('users')
          .doc(user.userId)
          .update(userModel.toFirestore());

      logger.info('User profile updated', context: {
        'userId': user.userId,
      });
    } catch (e, stackTrace) {
      logger.error('Error updating user profile', error: e, stackTrace: stackTrace);
      throw AuthenticationException('Failed to update user profile: ${e.toString()}');
    }
  }
}
