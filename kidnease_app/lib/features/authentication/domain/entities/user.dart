/// User entity representing a Kidnease application user
class User {
  final String userId;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final bool onboardingCompleted;

  const User({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.onboardingCompleted = false,
  });

  User copyWith({
    String? userId,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    bool? onboardingCompleted,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.userId == userId &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.onboardingCompleted == onboardingCompleted;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        email.hashCode ^
        name.hashCode ^
        role.hashCode ^
        createdAt.hashCode ^
        onboardingCompleted.hashCode;
  }

  @override
  String toString() {
    return 'User(userId: $userId, email: $email, name: $name, role: $role, createdAt: $createdAt, onboardingCompleted: $onboardingCompleted)';
  }
}

/// User roles in the Kidnease application
enum UserRole {
  patient,
  caregiver,
  healthcareProvider;

  String toJson() => name;

  static UserRole fromJson(String json) {
    return UserRole.values.firstWhere(
      (role) => role.name == json,
      orElse: () => UserRole.patient,
    );
  }
}
