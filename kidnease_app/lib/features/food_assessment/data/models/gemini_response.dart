import '../../domain/entities/dietary_assessment.dart';

/// Response from Gemini API containing food analysis results
class GeminiResponse {
  final String detectedFoodName;
  final double sodium; // mg
  final double potassium; // mg
  final double phosphorus; // mg
  final double protein; // g
  final String riskLevel; // "High Risk" or "Safe"
  final String explanationText;
  final List<String> filipinoAlternatives;

  const GeminiResponse({
    required this.detectedFoodName,
    required this.sodium,
    required this.potassium,
    required this.phosphorus,
    required this.protein,
    required this.riskLevel,
    required this.explanationText,
    this.filipinoAlternatives = const [],
  });

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      detectedFoodName: json['detectedFoodName'] as String? ?? 'Unknown Food',
      sodium: _parseNutrient(json['sodium']),
      potassium: _parseNutrient(json['potassium']),
      phosphorus: _parseNutrient(json['phosphorus']),
      protein: _parseNutrient(json['protein']),
      riskLevel: json['riskLevel'] as String? ?? 'Safe',
      explanationText: json['explanationText'] as String? ?? '',
      filipinoAlternatives: _parseAlternatives(json['filipinoAlternatives']),
    );
  }

  static double _parseNutrient(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<String> _parseAlternatives(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Convert to RiskLevel enum
  RiskLevel get riskLevelEnum => RiskLevel.fromJson(riskLevel);

  Map<String, dynamic> toJson() {
    return {
      'detectedFoodName': detectedFoodName,
      'sodium': sodium,
      'potassium': potassium,
      'phosphorus': phosphorus,
      'protein': protein,
      'riskLevel': riskLevel,
      'explanationText': explanationText,
      'filipinoAlternatives': filipinoAlternatives,
    };
  }

  @override
  String toString() {
    return 'GeminiResponse(detectedFoodName: $detectedFoodName, sodium: $sodium, potassium: $potassium, phosphorus: $phosphorus, protein: $protein, riskLevel: $riskLevel, explanationText: $explanationText, filipinoAlternatives: $filipinoAlternatives)';
  }
}
