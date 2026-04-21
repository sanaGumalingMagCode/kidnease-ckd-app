/// Nutritional data from FatSecret API
class NutritionalData {
  final String productName;
  final double sodium; // mg
  final double potassium; // mg
  final double phosphorus; // mg
  final double protein; // g
  final String servingSize;

  const NutritionalData({
    required this.productName,
    required this.sodium,
    required this.potassium,
    required this.phosphorus,
    required this.protein,
    required this.servingSize,
  });

  factory NutritionalData.fromJson(Map<String, dynamic> json) {
    return NutritionalData(
      productName: json['food_name'] as String? ?? '',
      sodium: _parseNutrient(json, 'sodium'),
      potassium: _parseNutrient(json, 'potassium'),
      phosphorus: _parseNutrient(json, 'phosphorus'),
      protein: _parseNutrient(json, 'protein'),
      servingSize: json['serving_description'] as String? ?? 'Unknown',
    );
  }

  static double _parseNutrient(Map<String, dynamic> json, String nutrient) {
    final value = json[nutrient];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'sodium': sodium,
      'potassium': potassium,
      'phosphorus': phosphorus,
      'protein': protein,
      'servingSize': servingSize,
    };
  }

  @override
  String toString() {
    return 'NutritionalData(productName: $productName, sodium: $sodium, potassium: $potassium, phosphorus: $phosphorus, protein: $protein, servingSize: $servingSize)';
  }
}
