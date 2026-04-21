import 'package:kidnease_app/core/errors/exceptions.dart';
import 'package:kidnease_app/core/utils/logger.dart';
import 'package:kidnease_app/features/dietary_profile/domain/entities/dietary_profile.dart';
import 'package:kidnease_app/features/food_assessment/data/datasources/cloud_storage_repository.dart';
import 'package:kidnease_app/features/food_assessment/data/datasources/fatsecret_api_client.dart';
import 'package:kidnease_app/features/food_assessment/data/datasources/gemini_api_client.dart';
import 'package:kidnease_app/features/food_assessment/data/datasources/image_capture_service.dart';
import 'package:kidnease_app/features/food_assessment/data/datasources/local_cache_repository.dart';
import 'package:kidnease_app/features/food_assessment/data/repositories/firestore_repository.dart';
import 'package:kidnease_app/features/food_assessment/domain/entities/dietary_assessment.dart';
import 'package:kidnease_app/features/food_assessment/domain/entities/extracted_nutrients.dart';
import 'package:kidnease_app/features/food_assessment/domain/entities/risk_notification.dart';
import 'package:kidnease_app/features/food_assessment/domain/usecases/risk_assessment_engine.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Result of the complete food assessment flow
class AssessmentResult {
  final DietaryAssessment assessment;
  final ExtractedNutrients nutrients;
  final RiskNotification notification;
  final String riskLevel;
  final String explanation;
  final List<String> filipinoAlternatives;

  AssessmentResult({
    required this.assessment,
    required this.nutrients,
    required this.notification,
    required this.riskLevel,
    required this.explanation,
    required this.filipinoAlternatives,
  });
}

/// Orchestrates the complete food assessment flow:
/// 1. Capture image
/// 2. Compress image
/// 3. Upload to Cloud Storage
/// 4. Query FatSecret API (optional)
/// 5. Analyze with Gemini AI
/// 6. Assess risk
/// 7. Save to Firestore
/// 8. Cache locally
/// 9. Delete image from storage
/// 10. Return result
class CaptureAndAssessFoodUseCase {
  final ImageCaptureService imageCaptureService;
  final CloudStorageRepository cloudStorageRepository;
  final FatSecretApiClient fatSecretApiClient;
  final GeminiApiClient geminiApiClient;
  final RiskAssessmentEngine riskAssessmentEngine;
  final FirestoreRepository firestoreRepository;
  final LocalCacheRepository localCacheRepository;

  CaptureAndAssessFoodUseCase({
    required this.imageCaptureService,
    required this.cloudStorageRepository,
    required this.fatSecretApiClient,
    required this.geminiApiClient,
    required this.riskAssessmentEngine,
    required this.firestoreRepository,
    required this.localCacheRepository,
  });

  /// Execute the complete assessment flow
  /// 
  /// [userId] - The ID of the user performing the assessment
  /// [userProfile] - The user's dietary profile with limits
  /// [source] - The source of the image (camera or gallery)
  /// 
  /// Returns [AssessmentResult] with complete assessment data
  /// 
  /// Throws [ValidationException] if image quality is insufficient
  /// Throws [NetworkException] if network operations fail
  /// Throws [ApiException] if API calls fail
  /// Throws [StorageException] if storage operations fail
  Future<AssessmentResult> execute({
    required String userId,
    required DietaryProfile userProfile,
    ImageSource source = ImageSource.camera,
  }) async {
    String? imageUrl;
    
    try {
      // Step 1: Capture image
      logger.info('Starting food assessment for user: $userId');
      final File capturedImage;
      
      if (source == ImageSource.camera) {
        capturedImage = await imageCaptureService.captureImage();
      } else {
        // For gallery, we need to use image picker directly
        final picker = ImagePicker();
        final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
        if (photo == null) {
          throw ValidationException('No image selected');
        }
        capturedImage = File(photo.path);
      }

      // Step 2: Compress image
      logger.info('Compressing image...');
      final compressedImage = await imageCaptureService.compressImage(capturedImage);

      // Step 3: Validate image quality
      logger.info('Validating image quality...');
      final isValid = await imageCaptureService.validateImageQuality(compressedImage);
      if (!isValid) {
        throw ValidationException(
          'Image quality is insufficient. Please ensure the image is clear and well-lit (minimum 800x600 resolution).',
        );
      }

      // Step 4: Upload to Cloud Storage
      logger.info('Uploading image to Cloud Storage...');
      imageUrl = await cloudStorageRepository.uploadImage(compressedImage, userId);
      logger.info('Image uploaded successfully: $imageUrl');

      // Step 5: Query FatSecret API (optional, graceful degradation)
      logger.info('Querying FatSecret API...');
      try {
        // We don't have the product name yet, so we'll skip FatSecret for now
        // In a real implementation, you might want to do OCR first to extract product name
        // For now, we'll rely on Gemini to do everything
        logger.info('Skipping FatSecret API - will rely on Gemini for nutritional analysis');
      } catch (e) {
        // Graceful degradation: if FatSecret fails, continue with Gemini-only analysis
        logger.warning('FatSecret API failed, continuing with Gemini-only analysis: $e');
      }

      // Step 6: Analyze with Gemini AI
      logger.info('Analyzing food with Gemini AI...');
      final geminiResponse = await geminiApiClient.analyzeFood(
        imageUrl: imageUrl,
        userProfile: userProfile,
        fatSecretData: null,
      );
      logger.info('Gemini analysis complete: ${geminiResponse.detectedFoodName}');

      // Step 7: Create ExtractedNutrients entity
      final nutrients = ExtractedNutrients(
        nutrientRecordId: DateTime.now().millisecondsSinceEpoch.toString(),
        assessmentId: '', // Will be set after creating assessment
        sodiumValue: geminiResponse.sodium,
        potassiumValue: geminiResponse.potassium,
        phosphorusValue: geminiResponse.phosphorus,
        proteinValue: geminiResponse.protein,
        source: NutrientSource.gemini,
      );

      // Step 8: Assess risk using Risk Assessment Engine
      logger.info('Assessing dietary risk...');
      final riskAssessment = riskAssessmentEngine.evaluateRisk(
        nutrients: nutrients,
        profile: userProfile,
      );
      logger.info('Risk assessment complete: ${riskAssessment.riskLevel.displayText}');

      // Step 9: Create DietaryAssessment entity
      final assessmentId = DateTime.now().millisecondsSinceEpoch.toString();
      final assessment = DietaryAssessment(
        assessmentId: assessmentId,
        userId: userId,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        detectedFoodName: geminiResponse.detectedFoodName,
        riskLevel: riskAssessment.riskLevel,
        explanationText: riskAssessment.explanation,
        filipinoAlternatives: geminiResponse.filipinoAlternatives,
      );

      // Update nutrients with assessment ID
      final updatedNutrients = ExtractedNutrients(
        nutrientRecordId: nutrients.nutrientRecordId,
        assessmentId: assessmentId,
        sodiumValue: nutrients.sodiumValue,
        potassiumValue: nutrients.potassiumValue,
        phosphorusValue: nutrients.phosphorusValue,
        proteinValue: nutrients.proteinValue,
        source: nutrients.source,
      );

      // Step 10: Create RiskNotification entity
      final notification = RiskNotification(
        notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        assessmentId: assessmentId,
        severityLevel: riskAssessment.riskLevel.displayText,
        displayMessage: _generateDisplayMessage(
          riskLevel: riskAssessment.riskLevel.displayText,
          foodName: geminiResponse.detectedFoodName,
          explanation: riskAssessment.explanation,
        ),
        timestamp: DateTime.now(),
        dismissed: false,
      );

      // Step 11: Save to Firestore (transaction for assessment + nutrients)
      logger.info('Saving assessment to Firestore...');
      await firestoreRepository.createAssessment(
        assessment: assessment,
        nutrients: updatedNutrients,
      );
      logger.info('Assessment saved to Firestore');

      // Step 12: Save notification to Firestore
      logger.info('Saving notification to Firestore...');
      await firestoreRepository.createNotification(notification);
      logger.info('Notification saved to Firestore');

      // Step 13: Cache locally for offline access
      logger.info('Caching assessment locally...');
      try {
        await localCacheRepository.cacheAssessments([assessment]);
        logger.info('Assessment cached locally');
      } catch (e) {
        // Non-critical error, log and continue
        logger.warning('Failed to cache assessment locally: $e');
      }

      // Step 14: Return result
      logger.info('Food assessment completed successfully');
      return AssessmentResult(
        assessment: assessment,
        nutrients: updatedNutrients,
        notification: notification,
        riskLevel: riskAssessment.riskLevel.displayText,
        explanation: riskAssessment.explanation,
        filipinoAlternatives: geminiResponse.filipinoAlternatives,
      );
    } catch (e) {
      // Log error with context
      logger.error('Food assessment failed: $e');
      
      // Re-throw with user-friendly message
      if (e is ValidationException) {
        rethrow;
      } else if (e is NetworkException) {
        throw NetworkException(
          'Network error during assessment. Please check your internet connection and try again.',
        );
      } else if (e is ApiException) {
        throw ApiException(
          'API error during assessment: ${e.message}. Please try again.',
        );
      } else if (e is StorageException) {
        throw StorageException(
          'Storage error during assessment: ${e.message}. Please try again.',
        );
      } else {
        throw Exception('Unexpected error during assessment: $e');
      }
    } finally {
      // Step 15: Delete image from storage (always execute, even on error)
      if (imageUrl != null) {
        try {
          logger.info('Deleting image from Cloud Storage...');
          await cloudStorageRepository.deleteImage(imageUrl);
          logger.info('Image deleted successfully');
        } catch (e) {
          // Non-critical error, log and continue
          // The lifecycle policy will delete it after 24 hours anyway
          logger.warning('Failed to delete image immediately: $e. Lifecycle policy will clean up after 24 hours.');
        }
      }
    }
  }

  /// Generate user-friendly display message for notification
  String _generateDisplayMessage({
    required String riskLevel,
    required String foodName,
    required String explanation,
  }) {
    if (riskLevel == 'High Risk') {
      return '⚠️ High Risk: $foodName\n\n$explanation';
    } else {
      return '✅ Safe: $foodName\n\nThis meal is within your dietary limits. Enjoy!';
    }
  }
}
