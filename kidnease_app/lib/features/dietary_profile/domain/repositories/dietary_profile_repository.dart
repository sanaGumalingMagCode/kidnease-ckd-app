import '../entities/dietary_profile.dart';

/// Abstract repository interface for dietary profile operations
abstract class DietaryProfileRepository {
  /// Get dietary profile for a user
  Future<DietaryProfile?> getDietaryProfile(String userId);

  /// Save a new dietary profile
  Future<void> saveDietaryProfile(DietaryProfile profile);

  /// Update an existing dietary profile
  Future<void> updateDietaryProfile(DietaryProfile profile);

  /// Delete a dietary profile
  Future<void> deleteDietaryProfile(String profileId);
}
