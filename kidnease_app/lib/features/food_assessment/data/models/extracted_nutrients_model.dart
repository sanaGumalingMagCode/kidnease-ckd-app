import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/extracted_nutrients.dart';

/// Data Transfer Object for ExtractedNutrients entity
class ExtractedNutrientsModel {
  final String nutrientRecordId;
  final String assessmentId;
  final double sodiumValue;
  final double potassiumValue;
  final double phosphorusValue;
  final double proteinValue;
  final String source;

  const ExtractedNutrientsModel({
    required this.nutrientRecordId,
    required this.assessmentId,
    required this.sodiumValue,
    required this.potassiumValue,
    required this.phosphorusValue,
    required this.proteinValue,
    required this.source,
  });

  factory ExtractedNutrientsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExtractedNutrientsModel(
      nutrientRecordId: data['nutrientRecordId'] as String,
      assessmentId: data['assessmentId'] as String,
      sodiumValue: (data['sodiumValue'] as num).toDouble(),
      potassiumValue: (data['potassiumValue'] as num).toDouble(),
      phosphorusValue: (data['phosphorusValue'] as num).toDouble(),
      proteinValue: (data['proteinValue'] as num).toDouble(),
      source: data['source'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nutrientRecordId': nutrientRecordId,
      'assessmentId': assessmentId,
      'sodiumValue': sodiumValue,
      'potassiumValue': potassiumValue,
      'phosphorusValue': phosphorusValue,
      'proteinValue': proteinValue,
      'source': source,
    };
  }

  ExtractedNutrients toDomain() {
    return ExtractedNutrients(
      nutrientRecordId: nutrientRecordId,
      assessmentId: assessmentId,
      sodiumValue: sodiumValue,
      potassiumValue: potassiumValue,
      phosphorusValue: phosphorusValue,
      proteinValue: proteinValue,
      source: NutrientSource.fromJson(source),
    );
  }

  static ExtractedNutrientsModel fromDomain(ExtractedNutrients nutrients) {
    return ExtractedNutrientsModel(
      nutrientRecordId: nutrients.nutrientRecordId,
      assessmentId: nutrients.assessmentId,
      sodiumValue: nutrients.sodiumValue,
      potassiumValue: nutrients.potassiumValue,
      phosphorusValue: nutrients.phosphorusValue,
      proteinValue: nutrients.proteinValue,
      source: nutrients.source.toJson(),
    );
  }
}
