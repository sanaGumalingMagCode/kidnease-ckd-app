/// KDIGO (Kidney Disease: Improving Global Outcomes) Reference Limits
/// 
/// This file contains the recommended daily nutritional limits for each CKD stage
/// based on KDIGO clinical practice guidelines.

class KdigoLimits {
  final double sodium; // mg
  final double potassium; // mg
  final double phosphorus; // mg
  final double protein; // g

  const KdigoLimits({
    required this.sodium,
    required this.potassium,
    required this.phosphorus,
    required this.protein,
  });
}

/// KDIGO-recommended daily limits by CKD stage
const Map<int, KdigoLimits> kdogoLimitsByCkdStage = {
  1: KdigoLimits(
    sodium: 2300,
    potassium: 3500,
    phosphorus: 1200,
    protein: 60,
  ),
  2: KdigoLimits(
    sodium: 2300,
    potassium: 3000,
    phosphorus: 1200,
    protein: 60,
  ),
  3: KdigoLimits(
    sodium: 2000,
    potassium: 2500,
    phosphorus: 1000,
    protein: 50,
  ),
  4: KdigoLimits(
    sodium: 2000,
    potassium: 2000,
    phosphorus: 900,
    protein: 40,
  ),
  5: KdigoLimits(
    sodium: 1500,
    potassium: 2000,
    phosphorus: 800,
    protein: 40,
  ),
};

/// Validation range multipliers for custom limits
/// Users can set limits within [0.5 × reference, 2.0 × reference]
const double kdogoMinMultiplier = 0.5;
const double kdogoMaxMultiplier = 2.0;
