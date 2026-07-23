import '../../../../core/constants/kdigo_limits.dart';
import '../../../food_assessment/domain/entities/extracted_nutrients.dart';

/// Dietary Profile entity representing user's personalized KDIGO-compliant daily nutritional limits
class DietaryProfile {
  final String profileId;
  final String userId;
  final double dailySodiumLimit; // mg
  final double dailyPotassiumLimit; // mg
  final double dailyPhosphorusLimit; // mg
  final double dailyProteinLimit; // g
  final int ckdStage; // 0-5 (0 = Prevention/Healthy, 1-5 = CKD Stages)
  final DateTime lastUpdated;
  final String? profilePhotoUrl; // Optional profile photo URL

  const DietaryProfile({
    required this.profileId,
    required this.userId,
    required this.dailySodiumLimit,
    required this.dailyPotassiumLimit,
    required this.dailyPhosphorusLimit,
    required this.dailyProteinLimit,
    required this.ckdStage,
    required this.lastUpdated,
    this.profilePhotoUrl,
  });

  /// Check if the profile limits are within KDIGO-recommended range
  /// Acceptable range: [0.5 × reference, 2.0 × reference]
  bool isWithinKdogoRange() {
    final reference = kdogoLimitsByCkdStage[ckdStage];
    if (reference == null) return false;

    return _isWithinRange(dailySodiumLimit, reference.sodium) &&
        _isWithinRange(dailyPotassiumLimit, reference.potassium) &&
        _isWithinRange(dailyPhosphorusLimit, reference.phosphorus) &&
        _isWithinRange(dailyProteinLimit, reference.protein);
  }

  bool _isWithinRange(double value, double reference) {
    final min = reference * kdogoMinMultiplier;
    final max = reference * kdogoMaxMultiplier;
    return value >= min && value <= max;
  }

  /// Calculate compliance percentage for given nutrients
  /// Returns average compliance across all nutrients (0-100%)
  double getCompliancePercentage(ExtractedNutrients nutrients) {
    final sodiumCompliance =
        (nutrients.sodiumValue / dailySodiumLimit).clamp(0.0, 1.0);
    final potassiumCompliance =
        (nutrients.potassiumValue / dailyPotassiumLimit).clamp(0.0, 1.0);
    final phosphorusCompliance =
        (nutrients.phosphorusValue / dailyPhosphorusLimit).clamp(0.0, 1.0);
    final proteinCompliance =
        (nutrients.proteinValue / dailyProteinLimit).clamp(0.0, 1.0);

    return ((sodiumCompliance +
                potassiumCompliance +
                phosphorusCompliance +
                proteinCompliance) /
            4) *
        100;
  }

  /// Get KDIGO reference limits for the current CKD stage
  KdigoLimits? getKdigoReference() {
    return kdogoLimitsByCkdStage[ckdStage];
  }

  DietaryProfile copyWith({
    String? profileId,
    String? userId,
    double? dailySodiumLimit,
    double? dailyPotassiumLimit,
    double? dailyPhosphorusLimit,
    double? dailyProteinLimit,
    int? ckdStage,
    DateTime? lastUpdated,
    String? profilePhotoUrl,
  }) {
    return DietaryProfile(
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      dailySodiumLimit: dailySodiumLimit ?? this.dailySodiumLimit,
      dailyPotassiumLimit: dailyPotassiumLimit ?? this.dailyPotassiumLimit,
      dailyPhosphorusLimit: dailyPhosphorusLimit ?? this.dailyPhosphorusLimit,
      dailyProteinLimit: dailyProteinLimit ?? this.dailyProteinLimit,
      ckdStage: ckdStage ?? this.ckdStage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DietaryProfile &&
        other.profileId == profileId &&
        other.userId == userId &&
        other.dailySodiumLimit == dailySodiumLimit &&
        other.dailyPotassiumLimit == dailyPotassiumLimit &&
        other.dailyPhosphorusLimit == dailyPhosphorusLimit &&
        other.dailyProteinLimit == dailyProteinLimit &&
        other.ckdStage == ckdStage &&
        other.lastUpdated == lastUpdated &&
        other.profilePhotoUrl == profilePhotoUrl;
  }

  @override
  int get hashCode {
    return profileId.hashCode ^
        userId.hashCode ^
        dailySodiumLimit.hashCode ^
        dailyPotassiumLimit.hashCode ^
        dailyPhosphorusLimit.hashCode ^
        dailyProteinLimit.hashCode ^
        ckdStage.hashCode ^
        lastUpdated.hashCode ^
        profilePhotoUrl.hashCode;
  }

  @override
  String toString() {
    return 'DietaryProfile(profileId: $profileId, userId: $userId, dailySodiumLimit: $dailySodiumLimit, dailyPotassiumLimit: $dailyPotassiumLimit, dailyPhosphorusLimit: $dailyPhosphorusLimit, dailyProteinLimit: $dailyProteinLimit, ckdStage: $ckdStage, lastUpdated: $lastUpdated, profilePhotoUrl: $profilePhotoUrl)';
  }
}
