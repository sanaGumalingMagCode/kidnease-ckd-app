import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dietary_assessment.dart';

/// Data Transfer Object for DietaryAssessment entity
class DietaryAssessmentModel {
  final String assessmentId;
  final String userId;
  final Timestamp timestamp;
  final String imageUrl;
  final String detectedFoodName;
  final String riskLevel;
  final String explanationText;
  final List<String> filipinoAlternatives;

  const DietaryAssessmentModel({
    required this.assessmentId,
    required this.userId,
    required this.timestamp,
    required this.imageUrl,
    required this.detectedFoodName,
    required this.riskLevel,
    required this.explanationText,
    this.filipinoAlternatives = const [],
  });

  factory DietaryAssessmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DietaryAssessmentModel(
      assessmentId: data['assessmentId'] as String,
      userId: data['userId'] as String,
      timestamp: data['timestamp'] as Timestamp,
      imageUrl: data['imageUrl'] as String,
      detectedFoodName: data['detectedFoodName'] as String,
      riskLevel: data['riskLevel'] as String,
      explanationText: data['explanationText'] as String,
      filipinoAlternatives: (data['filipinoAlternatives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assessmentId': assessmentId,
      'userId': userId,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'detectedFoodName': detectedFoodName,
      'riskLevel': riskLevel,
      'explanationText': explanationText,
      'filipinoAlternatives': filipinoAlternatives,
    };
  }

  DietaryAssessment toDomain() {
    return DietaryAssessment(
      assessmentId: assessmentId,
      userId: userId,
      timestamp: timestamp.toDate(),
      imageUrl: imageUrl,
      detectedFoodName: detectedFoodName,
      riskLevel: RiskLevel.fromJson(riskLevel),
      explanationText: explanationText,
      filipinoAlternatives: filipinoAlternatives,
    );
  }

  static DietaryAssessmentModel fromDomain(DietaryAssessment assessment) {
    return DietaryAssessmentModel(
      assessmentId: assessment.assessmentId,
      userId: assessment.userId,
      timestamp: Timestamp.fromDate(assessment.timestamp),
      imageUrl: assessment.imageUrl,
      detectedFoodName: assessment.detectedFoodName,
      riskLevel: assessment.riskLevel.toJson(),
      explanationText: assessment.explanationText,
      filipinoAlternatives: assessment.filipinoAlternatives,
    );
  }
}
