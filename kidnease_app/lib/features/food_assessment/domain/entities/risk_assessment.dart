import 'dietary_assessment.dart';

/// Risk Assessment result containing risk level, explanation, and exceeded nutrients
class RiskAssessment {
  final RiskLevel riskLevel;
  final String explanation;
  final List<String> exceededNutrients;

  const RiskAssessment({
    required this.riskLevel,
    required this.explanation,
    required this.exceededNutrients,
  });

  /// Check if the assessment is high risk
  bool get isHighRisk => riskLevel == RiskLevel.highRisk;

  /// Check if the assessment is safe
  bool get isSafe => riskLevel == RiskLevel.safe;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RiskAssessment &&
        other.riskLevel == riskLevel &&
        other.explanation == explanation &&
        _listEquals(other.exceededNutrients, exceededNutrients);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      riskLevel.hashCode ^ explanation.hashCode ^ exceededNutrients.hashCode;

  @override
  String toString() {
    return 'RiskAssessment(riskLevel: $riskLevel, explanation: $explanation, exceededNutrients: $exceededNutrients)';
  }
}
