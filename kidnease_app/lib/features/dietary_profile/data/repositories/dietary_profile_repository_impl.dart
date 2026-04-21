import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/kdigo_limits.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/dietary_profile.dart';
import '../../domain/repositories/dietary_profile_repository.dart';
import '../models/dietary_profile_model.dart';

/// Implementation of DietaryProfileRepository using Firestore
class DietaryProfileRepositoryImpl implements DietaryProfileRepository {
  final FirebaseFirestore _firestore;

  DietaryProfileRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DietaryProfile?> getDietaryProfile(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('dietaryProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return DietaryProfileModel.fromFirestore(querySnapshot.docs.first)
          .toDomain();
    } catch (e, stackTrace) {
      logger.error('Error fetching dietary profile',
          error: e, stackTrace: stackTrace, context: {'userId': userId});
      throw ValidationException('Failed to fetch dietary profile: ${e.toString()}');
    }
  }

  @override
  Future<void> saveDietaryProfile(DietaryProfile profile) async {
    try {
      // Validate profile
      _validateProfile(profile);

      final profileModel = DietaryProfileModel.fromDomain(profile);
      await _firestore
          .collection('dietaryProfiles')
          .doc(profile.profileId)
          .set(profileModel.toFirestore());

      logger.info('Dietary profile saved', context: {
        'profileId': profile.profileId,
        'userId': profile.userId,
      });
    } catch (e, stackTrace) {
      logger.error('Error saving dietary profile',
          error: e, stackTrace: stackTrace, context: {'profileId': profile.profileId});
      rethrow;
    }
  }

  @override
  Future<void> updateDietaryProfile(DietaryProfile profile) async {
    try {
      // Validate profile
      _validateProfile(profile);

      final profileModel = DietaryProfileModel.fromDomain(profile);
      await _firestore
          .collection('dietaryProfiles')
          .doc(profile.profileId)
          .update(profileModel.toFirestore());

      logger.info('Dietary profile updated', context: {
        'profileId': profile.profileId,
        'userId': profile.userId,
      });
    } catch (e, stackTrace) {
      logger.error('Error updating dietary profile',
          error: e, stackTrace: stackTrace, context: {'profileId': profile.profileId});
      throw ValidationException('Failed to update dietary profile: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteDietaryProfile(String profileId) async {
    try {
      await _firestore.collection('dietaryProfiles').doc(profileId).delete();

      logger.info('Dietary profile deleted', context: {
        'profileId': profileId,
      });
    } catch (e, stackTrace) {
      logger.error('Error deleting dietary profile',
          error: e, stackTrace: stackTrace, context: {'profileId': profileId});
      throw ValidationException('Failed to delete dietary profile: ${e.toString()}');
    }
  }

  /// Validate dietary profile limits
  void _validateProfile(DietaryProfile profile) {
    // Validate positive non-zero values
    if (profile.dailySodiumLimit <= 0) {
      throw ValidationException.invalidValue(
          'dailySodiumLimit', 'must be greater than zero');
    }
    if (profile.dailyPotassiumLimit <= 0) {
      throw ValidationException.invalidValue(
          'dailyPotassiumLimit', 'must be greater than zero');
    }
    if (profile.dailyPhosphorusLimit <= 0) {
      throw ValidationException.invalidValue(
          'dailyPhosphorusLimit', 'must be greater than zero');
    }
    if (profile.dailyProteinLimit <= 0) {
      throw ValidationException.invalidValue(
          'dailyProteinLimit', 'must be greater than zero');
    }

    // Validate CKD stage
    if (profile.ckdStage < 1 || profile.ckdStage > 5) {
      throw ValidationException.invalidValue(
          'ckdStage', 'must be between 1 and 5');
    }

    // Validate KDIGO range
    final reference = kdogoLimitsByCkdStage[profile.ckdStage];
    if (reference == null) {
      throw ValidationException.invalidValue(
          'ckdStage', 'invalid CKD stage');
    }

    _validateKdigoRange(
        profile.dailySodiumLimit, reference.sodium, 'Sodium');
    _validateKdigoRange(
        profile.dailyPotassiumLimit, reference.potassium, 'Potassium');
    _validateKdigoRange(
        profile.dailyPhosphorusLimit, reference.phosphorus, 'Phosphorus');
    _validateKdigoRange(
        profile.dailyProteinLimit, reference.protein, 'Protein');
  }

  /// Validate that a limit is within KDIGO acceptable range
  void _validateKdigoRange(double value, double reference, String nutrientName) {
    final min = reference * kdogoMinMultiplier;
    final max = reference * kdogoMaxMultiplier;

    if (value < min || value > max) {
      throw ValidationException.outOfRange(nutrientName, min, max);
    }
  }
}
