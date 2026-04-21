import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../features/authentication/data/datasources/firebase_auth_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/entities/user.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';

import '../../features/dietary_profile/data/repositories/dietary_profile_repository_impl.dart';
import '../../features/dietary_profile/domain/repositories/dietary_profile_repository.dart';

import '../../features/food_assessment/data/datasources/image_capture_service.dart';
import '../../features/food_assessment/data/datasources/cloud_storage_repository.dart';
import '../../features/food_assessment/data/datasources/gemini_api_client.dart';
import '../../features/food_assessment/data/datasources/fatsecret_api_client.dart';
import '../../features/food_assessment/data/datasources/local_cache_repository.dart';
import '../../features/food_assessment/data/repositories/firestore_repository.dart';
import '../../features/food_assessment/domain/usecases/risk_assessment_engine.dart';
import '../../features/food_assessment/domain/usecases/capture_and_assess_food_usecase.dart';

// ==================== Firebase Instances ====================

final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ==================== Data Sources ====================

final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final imageCaptureServiceProvider = Provider<ImageCaptureService>((ref) {
  return CameraImageCaptureService();
});

final cloudStorageRepositoryProvider = Provider<CloudStorageRepository>((ref) {
  return FirebaseCloudStorageRepository(
    storage: ref.watch(firebaseStorageProvider),
  );
});

final geminiApiClientProvider = Provider<GeminiApiClient>((ref) {
  return GeminiApiClientImpl();
});

final fatSecretApiClientProvider = Provider<FatSecretApiClient>((ref) {
  return FatSecretApiClientImpl();
});

final localCacheRepositoryProvider = Provider<LocalCacheRepository>((ref) {
  return HiveLocalCacheRepository();
});

// ==================== Repositories ====================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    datasource: ref.watch(firebaseAuthDatasourceProvider),
  );
});

final dietaryProfileRepositoryProvider = Provider<DietaryProfileRepository>((ref) {
  return DietaryProfileRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

// ==================== Domain Logic ====================

final riskAssessmentEngineProvider = Provider<RiskAssessmentEngine>((ref) {
  return RiskAssessmentEngineImpl();
});

// ==================== Use Cases ====================

final captureAndAssessFoodUseCaseProvider = Provider<CaptureAndAssessFoodUseCase>((ref) {
  return CaptureAndAssessFoodUseCase(
    imageCaptureService: ref.watch(imageCaptureServiceProvider),
    cloudStorageRepository: ref.watch(cloudStorageRepositoryProvider),
    fatSecretApiClient: ref.watch(fatSecretApiClientProvider),
    geminiApiClient: ref.watch(geminiApiClientProvider),
    riskAssessmentEngine: ref.watch(riskAssessmentEngineProvider),
    firestoreRepository: ref.watch(firestoreRepositoryProvider),
    localCacheRepository: ref.watch(localCacheRepositoryProvider),
  );
});

// ==================== Auth State ====================

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
