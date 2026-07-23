import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dietary_profile.dart';

/// Data Transfer Object for DietaryProfile entity
class DietaryProfileModel {
  final String profileId;
  final String userId;
  final double dailySodiumLimit;
  final double dailyPotassiumLimit;
  final double dailyPhosphorusLimit;
  final double dailyProteinLimit;
  final int ckdStage;
  final Timestamp lastUpdated;
  final String? profilePhotoUrl;

  const DietaryProfileModel({
    required this.profileId,
    required this.userId,
    required this.dailySodiumLimit,
    required this.dailyPotassiumLimit,
    required this.dailyPhosphorusLimit,
    required this.dailyProteinLimit,
    required this.ckdStage,
    required this.lastUpdated,
    this.profilePhotoUrl,
  });

  /// Convert from Firestore document to DietaryProfileModel
  factory DietaryProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DietaryProfileModel(
      profileId: data['profileId'] as String,
      userId: data['userId'] as String,
      dailySodiumLimit: (data['dailySodiumLimit'] as num).toDouble(),
      dailyPotassiumLimit: (data['dailyPotassiumLimit'] as num).toDouble(),
      dailyPhosphorusLimit: (data['dailyPhosphorusLimit'] as num).toDouble(),
      dailyProteinLimit: (data['dailyProteinLimit'] as num).toDouble(),
      ckdStage: data['ckdStage'] as int,
      lastUpdated: data['lastUpdated'] as Timestamp,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
    );
  }

  /// Convert from DietaryProfileModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'profileId': profileId,
      'userId': userId,
      'dailySodiumLimit': dailySodiumLimit,
      'dailyPotassiumLimit': dailyPotassiumLimit,
      'dailyPhosphorusLimit': dailyPhosphorusLimit,
      'dailyProteinLimit': dailyProteinLimit,
      'ckdStage': ckdStage,
      'lastUpdated': lastUpdated,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
    };
  }

  /// Convert DietaryProfileModel to domain DietaryProfile entity
  DietaryProfile toDomain() {
    return DietaryProfile(
      profileId: profileId,
      userId: userId,
      dailySodiumLimit: dailySodiumLimit,
      dailyPotassiumLimit: dailyPotassiumLimit,
      dailyPhosphorusLimit: dailyPhosphorusLimit,
      dailyProteinLimit: dailyProteinLimit,
      ckdStage: ckdStage,
      lastUpdated: lastUpdated.toDate(),
      profilePhotoUrl: profilePhotoUrl,
    );
  }

  /// Convert domain DietaryProfile entity to DietaryProfileModel
  static DietaryProfileModel fromDomain(DietaryProfile profile) {
    return DietaryProfileModel(
      profileId: profile.profileId,
      userId: profile.userId,
      dailySodiumLimit: profile.dailySodiumLimit,
      dailyPotassiumLimit: profile.dailyPotassiumLimit,
      dailyPhosphorusLimit: profile.dailyPhosphorusLimit,
      dailyProteinLimit: profile.dailyProteinLimit,
      ckdStage: profile.ckdStage,
      lastUpdated: Timestamp.fromDate(profile.lastUpdated),
      profilePhotoUrl: profile.profilePhotoUrl,
    );
  }
}
