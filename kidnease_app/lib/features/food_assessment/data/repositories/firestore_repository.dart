import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/dietary_assessment.dart';
import '../../domain/entities/extracted_nutrients.dart';
import '../../domain/entities/risk_notification.dart';
import '../models/dietary_assessment_model.dart';
import '../models/extracted_nutrients_model.dart';
import '../models/risk_notification_model.dart';

/// Filter criteria for searching assessments
class AssessmentFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? riskLevel;
  final String? foodName;

  const AssessmentFilter({
    this.startDate,
    this.endDate,
    this.riskLevel,
    this.foodName,
  });
}

/// Repository for Firestore operations
class FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== Assessment Operations ====================

  /// Create a new dietary assessment with nutrients in a transaction
  Future<String> createAssessment({
    required DietaryAssessment assessment,
    required ExtractedNutrients nutrients,
  }) async {
    try {
      logger.info('Creating assessment in Firestore', context: {
        'assessmentId': assessment.assessmentId,
        'userId': assessment.userId,
      });

      // Use transaction to ensure both documents are created together
      await _firestore.runTransaction((transaction) async {
        // Create assessment document
        final assessmentRef = _firestore
            .collection('dietaryAssessments')
            .doc(assessment.assessmentId);
        final assessmentModel = DietaryAssessmentModel.fromDomain(assessment);
        transaction.set(assessmentRef, assessmentModel.toFirestore());

        // Create nutrients document
        final nutrientsRef = _firestore
            .collection('extractedNutrients')
            .doc(nutrients.nutrientRecordId);
        final nutrientsModel = ExtractedNutrientsModel.fromDomain(nutrients);
        transaction.set(nutrientsRef, nutrientsModel.toFirestore());
      });

      logger.info('Assessment created successfully', context: {
        'assessmentId': assessment.assessmentId,
      });

      return assessment.assessmentId;
    } catch (e, stackTrace) {
      logger.error('Error creating assessment', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to create assessment: ${e.toString()}');
    }
  }

  /// Save extracted nutrients
  Future<void> saveExtractedNutrients(ExtractedNutrients nutrients) async {
    try {
      final model = ExtractedNutrientsModel.fromDomain(nutrients);
      await _firestore
          .collection('extractedNutrients')
          .doc(nutrients.nutrientRecordId)
          .set(model.toFirestore());

      logger.info('Nutrients saved', context: {
        'nutrientRecordId': nutrients.nutrientRecordId,
      });
    } catch (e, stackTrace) {
      logger.error('Error saving nutrients', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to save nutrients: ${e.toString()}');
    }
  }

  /// Get assessment history as a stream for real-time updates
  Stream<List<DietaryAssessment>> getAssessmentHistory(
    String userId, {
    int limit = 100,
  }) {
    try {
      return _firestore
          .collection('dietaryAssessments')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DietaryAssessmentModel.fromFirestore(doc).toDomain())
            .toList();
      });
    } catch (e, stackTrace) {
      logger.error('Error getting assessment history stream', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to get assessment history: ${e.toString()}');
    }
  }

  /// Search assessments with filters
  Future<List<DietaryAssessment>> searchAssessments(
    String userId,
    AssessmentFilter filter,
  ) async {
    try {
      Query query = _firestore
          .collection('dietaryAssessments')
          .where('userId', isEqualTo: userId);

      // Apply filters
      if (filter.startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }

      if (filter.endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }

      if (filter.riskLevel != null) {
        query = query.where('riskLevel', isEqualTo: filter.riskLevel);
      }

      // Order by timestamp
      query = query.orderBy('timestamp', descending: true);

      final snapshot = await query.get();
      var assessments = snapshot.docs
          .map((doc) => DietaryAssessmentModel.fromFirestore(doc).toDomain())
          .toList();

      // Filter by food name (client-side since Firestore doesn't support LIKE)
      if (filter.foodName != null && filter.foodName!.isNotEmpty) {
        final searchTerm = filter.foodName!.toLowerCase();
        assessments = assessments
            .where((a) => a.detectedFoodName.toLowerCase().contains(searchTerm))
            .toList();
      }

      logger.info('Assessments searched', context: {
        'userId': userId,
        'count': assessments.length,
      });

      return assessments;
    } catch (e, stackTrace) {
      logger.error('Error searching assessments', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to search assessments: ${e.toString()}');
    }
  }

  /// Get nutrients by assessment ID
  Future<ExtractedNutrients?> getNutrientsByAssessmentId(
      String assessmentId) async {
    try {
      final snapshot = await _firestore
          .collection('extractedNutrients')
          .where('assessmentId', isEqualTo: assessmentId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ExtractedNutrientsModel.fromFirestore(snapshot.docs.first)
          .toDomain();
    } catch (e, stackTrace) {
      logger.error('Error getting nutrients', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to get nutrients: ${e.toString()}');
    }
  }

  /// Get assessments for a specific date range (for dashboard aggregation)
  Future<List<DietaryAssessment>> getAssessmentsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('dietaryAssessments')
          .where('userId', isEqualTo: userId)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DietaryAssessmentModel.fromFirestore(doc).toDomain())
          .toList();
    } catch (e, stackTrace) {
      logger.error('Error getting assessments by date range', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to get assessments: ${e.toString()}');
    }
  }

  // ==================== Notification Operations ====================

  /// Create a risk notification
  Future<void> createNotification(RiskNotification notification) async {
    try {
      final model = RiskNotificationModel.fromDomain(notification);
      await _firestore
          .collection('riskNotifications')
          .doc(notification.notificationId)
          .set(model.toFirestore());

      logger.info('Notification created', context: {
        'notificationId': notification.notificationId,
        'severityLevel': notification.severityLevel,
      });
    } catch (e, stackTrace) {
      logger.error('Error creating notification', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to create notification: ${e.toString()}');
    }
  }

  /// Get notification history
  Stream<List<RiskNotification>> getNotificationHistory(
    String userId, {
    int limit = 50,
  }) {
    try {
      return _firestore
          .collection('riskNotifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => RiskNotificationModel.fromFirestore(doc).toDomain())
            .toList();
      });
    } catch (e, stackTrace) {
      logger.error('Error getting notification history', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to get notifications: ${e.toString()}');
    }
  }

  /// Mark notification as dismissed
  Future<void> dismissNotification(String notificationId) async {
    try {
      await _firestore
          .collection('riskNotifications')
          .doc(notificationId)
          .update({'dismissed': true});

      logger.info('Notification dismissed', context: {
        'notificationId': notificationId,
      });
    } catch (e, stackTrace) {
      logger.error('Error dismissing notification', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to dismiss notification: ${e.toString()}');
    }
  }

  // ==================== Analytics Operations ====================

  /// Get daily nutrient totals for a specific date
  Future<Map<String, double>> getDailyNutrientTotals(
    String userId,
    DateTime date,
  ) async {
    try {
      // Get start and end of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get all assessments for the day
      final assessments = await getAssessmentsByDateRange(
        userId,
        startOfDay,
        endOfDay,
      );

      // Get nutrients for each assessment and sum them
      double totalSodium = 0;
      double totalPotassium = 0;
      double totalPhosphorus = 0;
      double totalProtein = 0;

      for (final assessment in assessments) {
        final nutrients = await getNutrientsByAssessmentId(assessment.assessmentId);
        if (nutrients != null) {
          totalSodium += nutrients.sodiumValue;
          totalPotassium += nutrients.potassiumValue;
          totalPhosphorus += nutrients.phosphorusValue;
          totalProtein += nutrients.proteinValue;
        }
      }

      return {
        'sodium': totalSodium,
        'potassium': totalPotassium,
        'phosphorus': totalPhosphorus,
        'protein': totalProtein,
      };
    } catch (e, stackTrace) {
      logger.error('Error calculating daily totals', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to calculate daily totals: ${e.toString()}');
    }
  }

  /// Get assessment count by risk level
  Future<Map<String, int>> getAssessmentCountByRiskLevel(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('dietaryAssessments')
          .where('userId', isEqualTo: userId)
          .get();

      int highRiskCount = 0;
      int safeCount = 0;

      for (final doc in snapshot.docs) {
        final riskLevel = doc.data()['riskLevel'] as String;
        if (riskLevel == 'High Risk') {
          highRiskCount++;
        } else {
          safeCount++;
        }
      }

      return {
        'highRisk': highRiskCount,
        'safe': safeCount,
      };
    } catch (e, stackTrace) {
      logger.error('Error getting risk level counts', error: e, stackTrace: stackTrace);
      throw ValidationException('Failed to get risk level counts: ${e.toString()}');
    }
  }
}
