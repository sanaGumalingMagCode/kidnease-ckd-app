import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/logger.dart';
import '../../../dietary_profile/domain/entities/dietary_profile.dart';
import '../../domain/entities/dietary_assessment.dart';

/// Abstract interface for local cache operations
abstract class LocalCacheRepository {
  /// Initialize the cache
  Future<void> initialize();

  /// Cache assessments
  Future<void> cacheAssessments(List<DietaryAssessment> assessments);

  /// Get cached assessments
  Future<List<DietaryAssessment>> getCachedAssessments(String userId);

  /// Cache dietary profile
  Future<void> cacheDietaryProfile(DietaryProfile profile);

  /// Get cached dietary profile
  Future<DietaryProfile?> getCachedDietaryProfile(String userId);

  /// Clear all cache
  Future<void> clearCache();

  /// Clear user-specific cache
  Future<void> clearUserCache(String userId);
}

/// Implementation of LocalCacheRepository using Hive
class HiveLocalCacheRepository implements LocalCacheRepository {
  static const String _assessmentsBoxName = 'assessments';
  static const String _profilesBoxName = 'dietary_profiles';
  static const int _maxCachedAssessments = 100;

  Box<Map>? _assessmentsBox;
  Box<Map>? _profilesBox;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      logger.info('Initializing Hive local cache');

      // Initialize Hive
      await Hive.initFlutter();

      // Open boxes
      _assessmentsBox = await Hive.openBox<Map>(_assessmentsBoxName);
      _profilesBox = await Hive.openBox<Map>(_profilesBoxName);

      _initialized = true;

      logger.info('Hive local cache initialized', context: {
        'assessmentsCount': _assessmentsBox?.length ?? 0,
        'profilesCount': _profilesBox?.length ?? 0,
      });
    } catch (e, stackTrace) {
      logger.error('Error initializing Hive cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> cacheAssessments(List<DietaryAssessment> assessments) async {
    await _ensureInitialized();

    try {
      if (assessments.isEmpty) return;

      final userId = assessments.first.userId;
      final key = 'assessments_$userId';

      // Get existing cached assessments
      final existingData = _assessmentsBox!.get(key) as Map?;
      final existingList = existingData?['assessments'] as List? ?? [];

      // Convert existing to assessment objects
      final existingAssessments = existingList
          .map((item) => _deserializeAssessment(Map<String, dynamic>.from(item as Map)))
          .toList();

      // Merge with new assessments (avoid duplicates)
      final assessmentMap = <String, DietaryAssessment>{};
      for (final assessment in existingAssessments) {
        assessmentMap[assessment.assessmentId] = assessment;
      }
      for (final assessment in assessments) {
        assessmentMap[assessment.assessmentId] = assessment;
      }

      // Sort by timestamp (most recent first)
      final mergedAssessments = assessmentMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Keep only the most recent N assessments (LRU eviction)
      final cachedAssessments = mergedAssessments.take(_maxCachedAssessments).toList();

      // Serialize and save
      final serializedList = cachedAssessments
          .map((a) => _serializeAssessment(a))
          .toList();

      await _assessmentsBox!.put(key, {
        'userId': userId,
        'assessments': serializedList,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      logger.info('Assessments cached', context: {
        'userId': userId,
        'count': cachedAssessments.length,
        'evicted': mergedAssessments.length - cachedAssessments.length,
      });
    } catch (e, stackTrace) {
      logger.error('Error caching assessments', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<DietaryAssessment>> getCachedAssessments(String userId) async {
    await _ensureInitialized();

    try {
      final key = 'assessments_$userId';
      final data = _assessmentsBox!.get(key) as Map?;

      if (data == null) {
        logger.info('No cached assessments found', context: {'userId': userId});
        return [];
      }

      final assessmentsList = data['assessments'] as List? ?? [];
      final assessments = assessmentsList
          .map((item) => _deserializeAssessment(Map<String, dynamic>.from(item as Map)))
          .toList();

      logger.info('Cached assessments retrieved', context: {
        'userId': userId,
        'count': assessments.length,
      });

      return assessments;
    } catch (e, stackTrace) {
      logger.error('Error getting cached assessments', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<void> cacheDietaryProfile(DietaryProfile profile) async {
    await _ensureInitialized();

    try {
      final key = 'profile_${profile.userId}';
      final serialized = _serializeProfile(profile);

      await _profilesBox!.put(key, serialized);

      logger.info('Dietary profile cached', context: {
        'userId': profile.userId,
        'profileId': profile.profileId,
      });
    } catch (e, stackTrace) {
      logger.error('Error caching dietary profile', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<DietaryProfile?> getCachedDietaryProfile(String userId) async {
    await _ensureInitialized();

    try {
      final key = 'profile_$userId';
      final data = _profilesBox!.get(key) as Map?;

      if (data == null) {
        logger.info('No cached profile found', context: {'userId': userId});
        return null;
      }

      final profile = _deserializeProfile(Map<String, dynamic>.from(data));

      logger.info('Cached profile retrieved', context: {
        'userId': userId,
        'profileId': profile.profileId,
      });

      return profile;
    } catch (e, stackTrace) {
      logger.error('Error getting cached profile', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _ensureInitialized();

    try {
      await _assessmentsBox!.clear();
      await _profilesBox!.clear();

      logger.info('All cache cleared');
    } catch (e, stackTrace) {
      logger.error('Error clearing cache', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> clearUserCache(String userId) async {
    await _ensureInitialized();

    try {
      await _assessmentsBox!.delete('assessments_$userId');
      await _profilesBox!.delete('profile_$userId');

      logger.info('User cache cleared', context: {'userId': userId});
    } catch (e, stackTrace) {
      logger.error('Error clearing user cache', error: e, stackTrace: stackTrace);
    }
  }

  // ==================== Serialization Methods ====================

  Map<String, dynamic> _serializeAssessment(DietaryAssessment assessment) {
    return {
      'assessmentId': assessment.assessmentId,
      'userId': assessment.userId,
      'timestamp': assessment.timestamp.toIso8601String(),
      'imageUrl': assessment.imageUrl,
      'detectedFoodName': assessment.detectedFoodName,
      'riskLevel': assessment.riskLevel.toJson(),
      'explanationText': assessment.explanationText,
      'filipinoAlternatives': assessment.filipinoAlternatives,
    };
  }

  DietaryAssessment _deserializeAssessment(Map<String, dynamic> data) {
    return DietaryAssessment(
      assessmentId: data['assessmentId'] as String,
      userId: data['userId'] as String,
      timestamp: DateTime.parse(data['timestamp'] as String),
      imageUrl: data['imageUrl'] as String,
      detectedFoodName: data['detectedFoodName'] as String,
      riskLevel: RiskLevel.fromJson(data['riskLevel'] as String),
      explanationText: data['explanationText'] as String,
      filipinoAlternatives: (data['filipinoAlternatives'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> _serializeProfile(DietaryProfile profile) {
    return {
      'profileId': profile.profileId,
      'userId': profile.userId,
      'dailySodiumLimit': profile.dailySodiumLimit,
      'dailyPotassiumLimit': profile.dailyPotassiumLimit,
      'dailyPhosphorusLimit': profile.dailyPhosphorusLimit,
      'dailyProteinLimit': profile.dailyProteinLimit,
      'ckdStage': profile.ckdStage,
      'lastUpdated': profile.lastUpdated.toIso8601String(),
    };
  }

  DietaryProfile _deserializeProfile(Map<String, dynamic> data) {
    return DietaryProfile(
      profileId: data['profileId'] as String,
      userId: data['userId'] as String,
      dailySodiumLimit: (data['dailySodiumLimit'] as num).toDouble(),
      dailyPotassiumLimit: (data['dailyPotassiumLimit'] as num).toDouble(),
      dailyPhosphorusLimit: (data['dailyPhosphorusLimit'] as num).toDouble(),
      dailyProteinLimit: (data['dailyProteinLimit'] as num).toDouble(),
      ckdStage: data['ckdStage'] as int,
      lastUpdated: DateTime.parse(data['lastUpdated'] as String),
    );
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
