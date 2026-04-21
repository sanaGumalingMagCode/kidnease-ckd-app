import '../../../dietary_profile/domain/entities/dietary_profile.dart';
import '../entities/dietary_assessment.dart';
import '../entities/extracted_nutrients.dart';
import '../entities/risk_assessment.dart';

/// Abstract interface for Risk Assessment Engine
abstract class RiskAssessmentEngine {
  /// Evaluate dietary risk based on extracted nutrients and user's dietary profile
  RiskAssessment evaluateRisk({
    required ExtractedNutrients nutrients,
    required DietaryProfile profile,
  });
}

/// Implementation of Risk Assessment Engine
class RiskAssessmentEngineImpl implements RiskAssessmentEngine {
  @override
  RiskAssessment evaluateRisk({
    required ExtractedNutrients nutrients,
    required DietaryProfile profile,
  }) {
    final exceededNutrients = <String>[];
    final explanationParts = <String>[];

    // Compare sodium
    if (nutrients.sodiumValue > profile.dailySodiumLimit) {
      exceededNutrients.add('sodium');
      explanationParts.add(
        'High sodium (${nutrients.sodiumValue.toStringAsFixed(0)}mg) exceeds your daily limit (${profile.dailySodiumLimit.toStringAsFixed(0)}mg), which may strain kidney filtration and increase blood pressure.',
      );
    }

    // Compare potassium
    if (nutrients.potassiumValue > profile.dailyPotassiumLimit) {
      exceededNutrients.add('potassium');
      explanationParts.add(
        'High potassium (${nutrients.potassiumValue.toStringAsFixed(0)}mg) exceeds your daily limit (${profile.dailyPotassiumLimit.toStringAsFixed(0)}mg), which can lead to dangerous heart rhythm problems when kidneys cannot filter it properly.',
      );
    }

    // Compare phosphorus
    if (nutrients.phosphorusValue > profile.dailyPhosphorusLimit) {
      exceededNutrients.add('phosphorus');
      explanationParts.add(
        'High phosphorus (${nutrients.phosphorusValue.toStringAsFixed(0)}mg) exceeds your daily limit (${profile.dailyPhosphorusLimit.toStringAsFixed(0)}mg), which can weaken bones and damage blood vessels when kidneys cannot remove excess.',
      );
    }

    // Compare protein
    if (nutrients.proteinValue > profile.dailyProteinLimit) {
      exceededNutrients.add('protein');
      explanationParts.add(
        'High protein (${nutrients.proteinValue.toStringAsFixed(1)}g) exceeds your daily limit (${profile.dailyProteinLimit.toStringAsFixed(1)}g), which creates more waste products that damaged kidneys must filter.',
      );
    }

    // Determine risk level
    final riskLevel = exceededNutrients.isEmpty
        ? RiskLevel.safe
        : RiskLevel.highRisk;

    // Generate explanation
    final explanation = exceededNutrients.isEmpty
        ? 'All nutrients are within your daily limits. This food is safe for your kidney health.'
        : explanationParts.join(' ');

    return RiskAssessment(
      riskLevel: riskLevel,
      explanation: explanation,
      exceededNutrients: exceededNutrients,
    );
  }
}
