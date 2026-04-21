import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

/// Data Transfer Object for User entity
class UserModel {
  final String userId;
  final String email;
  final String name;
  final String role;
  final Timestamp createdAt;
  final bool onboardingCompleted;

  const UserModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.onboardingCompleted = false,
  });

  /// Convert from Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: data['userId'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      role: data['role'] as String,
      createdAt: data['createdAt'] as Timestamp,
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }

  /// Convert from UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  /// Convert UserModel to domain User entity
  User toDomain() {
    return User(
      userId: userId,
      email: email,
      name: name,
      role: UserRole.fromJson(role),
      createdAt: createdAt.toDate(),
      onboardingCompleted: onboardingCompleted,
    );
  }

  /// Convert domain User entity to UserModel
  static UserModel fromDomain(User user) {
    return UserModel(
      userId: user.userId,
      email: user.email,
      name: user.name,
      role: user.role.toJson(),
      createdAt: Timestamp.fromDate(user.createdAt),
      onboardingCompleted: user.onboardingCompleted,
    );
  }
}
