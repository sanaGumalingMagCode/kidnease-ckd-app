/// Dietary Assessment entity representing a complete food risk assessment
class DietaryAssessment {
  final String assessmentId;
  final String userId;
  final DateTime timestamp;
  final String imageUrl; // Will become invalid after image deletion
  final String detectedFoodName;
  final RiskLevel riskLevel;
  final String explanationText;
  final List<String> filipinoAlternatives;

  const DietaryAssessment({
    required this.assessmentId,
    required this.userId,
    required this.timestamp,
    required this.imageUrl,
    required this.detectedFoodName,
    required this.riskLevel,
    required this.explanationText,
    this.filipinoAlternatives = const [],
  });

  DietaryAssessment copyWith({
    String? assessmentId,
    String? userId,
    DateTime? timestamp,
    String? imageUrl,
    String? detectedFoodName,
    RiskLevel? riskLevel,
    String? explanationText,
    List<String>? filipinoAlternatives,
  }) {
    return DietaryAssessment(
      assessmentId: assessmentId ?? this.assessmentId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      detectedFoodName: detectedFoodName ?? this.detectedFoodName,
      riskLevel: riskLevel ?? this.riskLevel,
      explanationText: explanationText ?? this.explanationText,
      filipinoAlternatives: filipinoAlternatives ?? this.filipinoAlternatives,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DietaryAssessment &&
        other.assessmentId == assessmentId &&
        other.userId == userId &&
        other.timestamp == timestamp &&
        other.imageUrl == imageUrl &&
        other.detectedFoodName == detectedFoodName &&
        other.riskLevel == riskLevel &&
        other.explanationText == explanationText &&
        _listEquals(other.filipinoAlternatives, filipinoAlternatives);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return assessmentId.hashCode ^
        userId.hashCode ^
        timestamp.hashCode ^
        imageUrl.hashCode ^
        detectedFoodName.hashCode ^
        riskLevel.hashCode ^
        explanationText.hashCode ^
        filipinoAlternatives.hashCode;
  }

  @override
  String toString() {
    return 'DietaryAssessment(assessmentId: $assessmentId, userId: $userId, timestamp: $timestamp, imageUrl: $imageUrl, detectedFoodName: $detectedFoodName, riskLevel: $riskLevel, explanationText: $explanationText, filipinoAlternatives: $filipinoAlternatives)';
  }
}

/// Risk level classification for dietary assessments
enum RiskLevel {
  safe,
  highRisk;

  String toJson() {
    switch (this) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.highRisk:
        return 'High Risk';
    }
  }

  static RiskLevel fromJson(String json) {
    switch (json) {
      case 'Safe':
        return RiskLevel.safe;
      case 'High Risk':
        return RiskLevel.highRisk;
      default:
        return RiskLevel.safe;
    }
  }

  /// Get display text for UI
  String get displayText {
    switch (this) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.highRisk:
        return 'High Risk';
    }
  }
}
