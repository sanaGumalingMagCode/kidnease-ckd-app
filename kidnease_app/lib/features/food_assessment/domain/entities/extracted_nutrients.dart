/// Extracted Nutrients entity representing nutritional values extracted from food images
class ExtractedNutrients {
  final String nutrientRecordId;
  final String assessmentId;
  final double sodiumValue; // mg
  final double potassiumValue; // mg
  final double phosphorusValue; // mg
  final double proteinValue; // g
  final NutrientSource source;

  const ExtractedNutrients({
    required this.nutrientRecordId,
    required this.assessmentId,
    required this.sodiumValue,
    required this.potassiumValue,
    required this.phosphorusValue,
    required this.proteinValue,
    required this.source,
  });

  ExtractedNutrients copyWith({
    String? nutrientRecordId,
    String? assessmentId,
    double? sodiumValue,
    double? potassiumValue,
    double? phosphorusValue,
    double? proteinValue,
    NutrientSource? source,
  }) {
    return ExtractedNutrients(
      nutrientRecordId: nutrientRecordId ?? this.nutrientRecordId,
      assessmentId: assessmentId ?? this.assessmentId,
      sodiumValue: sodiumValue ?? this.sodiumValue,
      potassiumValue: potassiumValue ?? this.potassiumValue,
      phosphorusValue: phosphorusValue ?? this.phosphorusValue,
      proteinValue: proteinValue ?? this.proteinValue,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExtractedNutrients &&
        other.nutrientRecordId == nutrientRecordId &&
        other.assessmentId == assessmentId &&
        other.sodiumValue == sodiumValue &&
        other.potassiumValue == potassiumValue &&
        other.phosphorusValue == phosphorusValue &&
        other.proteinValue == proteinValue &&
        other.source == source;
  }

  @override
  int get hashCode {
    return nutrientRecordId.hashCode ^
        assessmentId.hashCode ^
        sodiumValue.hashCode ^
        potassiumValue.hashCode ^
        phosphorusValue.hashCode ^
        proteinValue.hashCode ^
        source.hashCode;
  }

  @override
  String toString() {
    return 'ExtractedNutrients(nutrientRecordId: $nutrientRecordId, assessmentId: $assessmentId, sodiumValue: $sodiumValue, potassiumValue: $potassiumValue, phosphorusValue: $phosphorusValue, proteinValue: $proteinValue, source: $source)';
  }
}

/// Source of nutritional data
enum NutrientSource {
  gemini, // From Gemini AI vision
  fatsecret, // From FatSecret API
  hybrid; // Combined from both sources

  String toJson() => name;

  static NutrientSource fromJson(String json) {
    return NutrientSource.values.firstWhere(
      (source) => source.name == json,
      orElse: () => NutrientSource.gemini,
    );
  }
}
