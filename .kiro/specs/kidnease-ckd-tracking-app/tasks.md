# Implementation Plan: Kidnease CKD Tracking Application

## Overview

This implementation plan breaks down the Kidnease CKD tracking application into discrete, sequential coding tasks. The application follows Clean Architecture with three layers (Presentation, Domain, Data) and uses Flutter/Dart with Firebase backend services. The implementation prioritizes core functionality first, then builds out the complete feature set with testing integrated throughout.

## Tasks

- [x] 1. Project setup and core infrastructure
  - Initialize Flutter project with package name `com.kidnease.app`
  - Configure `pubspec.yaml` with required dependencies: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `riverpod`, `flutter_riverpod`, `image_picker`, `flutter_image_compress`, `hive`, `hive_flutter`, `fl_chart`, `http`, `flutter_dotenv`
  - Set up folder structure following Clean Architecture pattern (features/, core/, shared/)
  - Create `.env` file template for API keys (GEMINI_API_KEY, FATSECRET_KEY, FATSECRET_SECRET)
  - Download and configure `google-services.json` for Firebase Android integration
  - Create core constants file with KDIGO reference limits for CKD stages 1-5
  - _Requirements: 14.1, 15.1_

- [x] 2. Firebase configuration and security rules
  - Initialize Firebase project and enable Authentication (Email/Password provider)
  - Create Firestore database with collections: users, dietaryProfiles, dietaryAssessments, extractedNutrients, riskNotifications
  - Create Cloud Storage bucket for temporary image storage
  - Implement Firestore security rules restricting users to their own data (userId-based access control)
  - Implement Cloud Storage security rules with 2MB upload limit and user-folder isolation
  - Configure Cloud Storage lifecycle policy to auto-delete images older than 24 hours
  - Create Firestore composite indexes: (userId, timestamp DESC), (userId, riskLevel, timestamp DESC)
  - _Requirements: 1.1, 1.2, 9.4, 10.3, 14.2_

- [ ] 3. Core domain entities and error handling
  - [x] 3.1 Create domain entity models
    - Implement `User` entity with userId, email, name, role, createdAt, onboardingCompleted fields
    - Implement `DietaryProfile` entity with profileId, userId, daily limits (sodium, potassium, phosphorus, protein), ckdStage, lastUpdated
    - Implement `DietaryAssessment` entity with assessmentId, userId, timestamp, imageUrl, detectedFoodName, riskLevel, explanationText, filipinoAlternatives
    - Implement `ExtractedNutrients` entity with nutrientRecordId, assessmentId, nutrient values (sodium, potassium, phosphorus, protein), source
    - Implement `RiskNotification` entity with notificationId, userId, assessmentId, severityLevel, displayMessage, timestamp, dismissed
    - Add business logic methods to `DietaryProfile`: `isWithinKdogoRange()`, `getCompliancePercentage()`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 6.1, 6.2, 6.3, 6.4, 9.1, 9.2_

  - [x] 3.2 Create error handling framework
    - Implement custom exception classes: `AuthenticationException`, `NetworkException`, `ApiException`, `ValidationException`, `StorageException`
    - Implement failure types for error propagation across layers
    - Create logger utility with log levels (INFO, WARNING, ERROR) and Firebase Crashlytics integration
    - Implement global error boundary using Flutter's `ErrorWidget.builder`
    - _Requirements: 18.1, 18.2, 18.4, 18.5_

- [ ] 4. Authentication service and repository
  - [x] 4.1 Implement authentication data layer
    - Create `AuthRepository` abstract interface with methods: `registerWithEmail()`, `signInWithEmail()`, `signOut()`, `authStateChanges`, `currentUser`
    - Implement `FirebaseAuthRepositoryImpl` using Firebase Authentication SDK
    - Handle Firebase auth error codes: weak-password, email-already-in-use, user-not-found, wrong-password, network-request-failed
    - Create `UserModel` DTO for Firestore serialization/deserialization
    - Implement user profile CRUD operations in Firestore (create, read)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [ ]* 4.2 Write unit tests for authentication repository
    - Test successful registration and login flows
    - Test error handling for invalid credentials
    - Test Firestore user profile creation
    - Mock Firebase Authentication for isolated testing
    - _Requirements: 1.1, 1.2, 1.3_

- [ ] 5. Dietary profile management
  - [x] 5.1 Implement dietary profile data layer
    - Create `DietaryProfileRepository` abstract interface with methods: `getDietaryProfile()`, `saveDietaryProfile()`, `updateDietaryProfile()`
    - Implement `DietaryProfileRepositoryImpl` with Firestore integration
    - Create `DietaryProfileModel` DTO for Firestore serialization
    - Implement KDIGO validation logic: accept limits within [0.5 × reference, 2.0 × reference]
    - Add input validation for positive non-zero values
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.7, 15.3_

  - [ ]* 5.2 Write unit tests for dietary profile validation
    - Test KDIGO range validation for all CKD stages
    - Test rejection of out-of-range values
    - Test positive number validation
    - _Requirements: 2.7, 15.3_

- [ ] 6. Risk Assessment Engine (core business logic)
  - [x] 6.1 Implement Risk Assessment Engine
    - Create `RiskAssessmentEngine` abstract interface with method: `evaluateRisk(nutrients, profile)`
    - Implement `RiskAssessmentEngineImpl` with nutrient comparison logic
    - Implement risk classification: "High Risk" if any nutrient exceeds limit, "Safe" if all within limits
    - Implement explanation generation: list exceeded nutrients with values and limits
    - Create `RiskAssessment` result class with riskLevel, explanation, exceededNutrients fields
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [ ]* 6.2 Write property test for nutrient comparison correctness
    - **Property 1: Nutrient Comparison Correctness**
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4**
    - Generate random nutrient values and limits, verify correct comparison (value > limit)
    - Run 100 iterations with randomized inputs
    - Tag with: `@Tags(['pbt', 'feature:kidnease-ckd-tracking-app'])`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 6.3 Write property test for high risk classification
    - **Property 2: High Risk Classification**
    - **Validates: Requirements 6.5**
    - Generate random nutrients where at least one exceeds limit, verify "High Risk" classification
    - Run 100 iterations with randomized inputs
    - Tag with: `@Tags(['pbt', 'feature:kidnease-ckd-tracking-app'])`
    - _Requirements: 6.5_

  - [ ]* 6.4 Write property test for safe classification
    - **Property 3: Safe Classification**
    - **Validates: Requirements 6.6**
    - Generate random nutrients where all are within limits, verify "Safe" classification
    - Run 100 iterations with randomized inputs
    - Tag with: `@Tags(['pbt', 'feature:kidnease-ckd-tracking-app'])`
    - _Requirements: 6.6_

  - [ ]* 6.5 Write property test for explanation content
    - **Property 4: Explanation Contains Exceeded Nutrients**
    - **Validates: Requirements 6.7**
    - Generate high-risk scenarios, verify explanation contains all exceeded nutrient names
    - Run 100 iterations with randomized inputs
    - Tag with: `@Tags(['pbt', 'feature:kidnease-ckd-tracking-app'])`
    - _Requirements: 6.7_

  - [ ]* 6.6 Write property test for KDIGO range validation
    - **Property 5: KDIGO Range Validation**
    - **Validates: Requirements 15.3**
    - Generate random limit values, verify acceptance within [0.5×ref, 2.0×ref] and rejection outside
    - Run 100 iterations with randomized inputs
    - Tag with: `@Tags(['pbt', 'feature:kidnease-ckd-tracking-app'])`
    - _Requirements: 15.3_

  - [ ]* 6.7 Write unit tests for Risk Assessment Engine edge cases
    - Test exact limit matches (value == limit should be "Safe")
    - Test zero nutrient values
    - Test explanation formatting for multiple exceeded nutrients
    - _Requirements: 6.5, 6.6, 6.7_

- [ ] 7. Checkpoint - Core domain logic complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Image capture and compression service
  - [x] 8.1 Implement image capture module
    - Create `ImageCaptureService` abstract interface with methods: `captureImage()`, `compressImage()`, `validateImageQuality()`
    - Implement `CameraImageCaptureService` using `image_picker` package
    - Implement image compression using `flutter_image_compress` with max 2MB size, 85% quality, JPEG format
    - Implement quality validation: minimum resolution 800x600 for OCR readability
    - Handle camera permission errors with descriptive messages
    - _Requirements: 3.1, 3.2, 3.6, 14.1_

  - [ ]* 8.2 Write unit tests for image compression
    - Test file size reduction to under 2MB
    - Test format conversion (PNG → JPEG)
    - Test quality preservation for OCR
    - _Requirements: 3.2, 14.1_

- [ ] 9. Cloud Storage repository
  - [x] 9.1 Implement Cloud Storage repository
    - Create `CloudStorageRepository` abstract interface with methods: `uploadImage()`, `deleteImage()`, `setLifecyclePolicy()`
    - Implement `FirebaseCloudStorageRepository` using Firebase Storage SDK
    - Upload images to path: `users/{userId}/food_images/{timestamp}.jpg`
    - Generate signed URLs with 1-hour expiration
    - Implement automatic deletion after assessment completion
    - Handle storage quota exceeded errors
    - Implement upload timeout (30 seconds) with retry logic (exponential backoff, max 3 attempts)
    - _Requirements: 3.3, 3.4, 3.5, 10.1, 10.2, 10.3, 10.5_

  - [ ]* 9.2 Write integration tests for Cloud Storage lifecycle
    - Test upload → generate URL → delete flow
    - Test permission validation
    - Test timeout and retry logic
    - Use Firebase Emulator for testing
    - _Requirements: 3.3, 3.4, 10.1, 10.2_

- [ ] 10. FatSecret API client
  - [x] 10.1 Implement FatSecret API client
    - Create `FatSecretApiClient` abstract interface with method: `searchProduct(productName)`
    - Implement `FatSecretApiClientImpl` with OAuth 1.0 authentication
    - Configure endpoint: `https://platform.fatsecret.com/rest/server.api`, method: `foods.search`
    - Parse response to extract sodium, potassium, phosphorus, protein values
    - Return null if no match found (graceful degradation, not an error)
    - Handle rate limiting (HTTP 429) with exponential backoff
    - Implement 5-second timeout
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]* 10.2 Write unit tests for FatSecret API client
    - Test successful product search and parsing
    - Test null return for no match
    - Test rate limit handling
    - Mock HTTP responses for isolated testing
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 11. Gemini API client
  - [x] 11.1 Implement Gemini API client
    - Create `GeminiApiClient` abstract interface with method: `analyzeFood(imageUrl, userProfile, fatSecretData?)`
    - Implement `GeminiApiClientImpl` with endpoint: `https://generativelanguage.googleapis.com/v1/models/gemini-3.0-pro:generateContent`
    - Construct multimodal prompt with image URL, user dietary limits, FatSecret data (if available), Filipino cultural context
    - Request JSON response with fields: detectedFoodName, sodium, potassium, phosphorus, protein, riskLevel, explanationText, filipinoAlternatives
    - Implement 10-second timeout with retry logic (2 retries, exponential backoff)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 7.2, 16.1, 16.2, 16.3, 16.4, 16.5, 16.6_

  - [x] 11.2 Implement Gemini response parser and validator
    - Validate JSON structure and required fields presence
    - Validate riskLevel enum values ("High Risk" or "Safe")
    - Validate nutritional values are non-negative numbers
    - Default missing nutritional values to 0.0 with warning log
    - Sanitize explanationText (remove HTML, limit to 500 chars)
    - Handle rate limiting (HTTP 429) with exponential backoff
    - _Requirements: 5.6, 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

  - [ ]* 11.3 Write unit tests for Gemini response parser
    - Test valid JSON parsing
    - Test missing field handling with defaults
    - Test invalid enum value handling
    - Test explanation text sanitization
    - Mock API responses for isolated testing
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

- [ ] 12. Firestore repository for assessments
  - [x] 12.1 Implement Firestore repository
    - Create `FirestoreRepository` abstract interface with methods for all collections (users, dietaryProfiles, assessments, nutrients, notifications)
    - Implement `FirestoreRepositoryImpl` using Firestore SDK
    - Implement `createAssessment()` to save DietaryAssessment document
    - Implement `saveExtractedNutrients()` to save ExtractedNutrients document
    - Implement `createNotification()` to save RiskNotification document
    - Implement `getAssessmentHistory()` as Stream for real-time updates, ordered by timestamp DESC
    - Implement `searchAssessments()` with filters: date range, risk level, food name
    - Use transactions for multi-document writes (assessment + nutrients)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 19.1, 19.2, 19.3, 19.4_

  - [ ]* 12.2 Write integration tests for Firestore operations
    - Test create assessment with nutrients (transaction)
    - Test query assessment history with ordering
    - Test filter and search operations
    - Test offline persistence
    - Use Firebase Emulator for testing
    - _Requirements: 9.1, 9.2, 9.5, 19.4_

- [ ] 13. Local cache repository with Hive
  - [x] 13.1 Implement local cache repository
    - Create `LocalCacheRepository` abstract interface with methods: `cacheAssessments()`, `getCachedAssessments()`, `cacheDietaryProfile()`, `getCachedDietaryProfile()`, `clearCache()`
    - Implement `HiveLocalCacheRepository` using Hive package
    - Initialize Hive with encryption for sensitive data
    - Store most recent 100 assessments with LRU eviction policy
    - Cache dietary profile for offline access
    - _Requirements: 13.3, 13.5, 14.5_

  - [ ]* 13.2 Write unit tests for local cache
    - Test caching and retrieval of assessments
    - Test LRU eviction when exceeding 100 items
    - Test dietary profile caching
    - _Requirements: 13.5, 14.5_

- [ ] 14. Checkpoint - Data layer complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 15. Assessment orchestration use case
  - [x] 15.1 Implement complete assessment flow use case
    - Create `CaptureAndAssessFoodUseCase` that orchestrates: image capture → compression → upload → FatSecret query → Gemini analysis → risk assessment → save to Firestore → delete image
    - Implement error handling for each step with descriptive user messages
    - Implement graceful degradation: if FatSecret fails, proceed with Gemini-only analysis
    - Ensure image deletion happens in finally block (always executes)
    - Return assessment result with risk level, explanation, alternatives
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 5.1, 6.5, 6.6, 9.1, 10.1_

  - [ ]* 15.2 Write integration tests for complete assessment flow
    - Test end-to-end flow with mocked external services
    - Test error handling at each step
    - Test graceful degradation when FatSecret unavailable
    - Verify image deletion occurs even on errors
    - _Requirements: 3.5, 10.1, 10.2_

- [x] 16. Riverpod state management setup
  - Create global providers file with dependency injection setup
  - Implement providers for Firebase instances (Auth, Firestore, Storage)
  - Implement providers for repositories (Auth, Assessment, DietaryProfile, CloudStorage, LocalCache)
  - Implement providers for API clients (Gemini, FatSecret)
  - Implement `authStateProvider` as StreamProvider for reactive auth state
  - Implement `assessmentStateProvider` as StateNotifierProvider for assessment flow state
  - Load API keys from environment variables using `flutter_dotenv`
  - _Requirements: 17.3, 17.5_

- [x] 17. Authentication UI screens
  - [x] 17.1 Implement login and registration screens
    - Create `LoginScreen` with email/password form
    - Create `RegisterScreen` with email/password/name form
    - Implement form validation (email format, password length >= 6)
    - Display error messages for authentication failures
    - Show loading indicators during async operations
    - Navigate to dashboard on successful authentication
    - _Requirements: 1.1, 1.2, 1.3, 17.1, 17.4_

  - [ ]* 17.2 Write widget tests for authentication screens
    - Test form validation
    - Test error message display
    - Test navigation after successful login
    - Mock authentication service for testing
    - _Requirements: 1.3, 17.1_

- [x] 18. Dietary profile configuration UI
  - [x] 18.1 Implement dietary profile screen
    - Create `DietaryProfileScreen` with input fields for sodium, potassium, phosphorus, protein limits
    - Display KDIGO-recommended ranges based on CKD stage selection
    - Implement validation: positive numbers, within KDIGO range [0.5×ref, 2.0×ref]
    - Display warning message for out-of-range values
    - Show disclaimer about consulting healthcare providers
    - Save profile to Firestore on submit
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.7, 15.2, 15.4, 15.6_

  - [ ]* 18.2 Write widget tests for dietary profile screen
    - Test input validation
    - Test KDIGO range warning display
    - Test save functionality
    - _Requirements: 2.7, 15.4_

- [x] 19. Camera and image capture UI
  - [x] 19.1 Implement camera screen
    - Create `CameraScreen` with camera preview using `image_picker`
    - Implement capture button with loading state during processing
    - Display error messages for camera permission denied
    - Show upload progress indicator
    - Handle image capture errors gracefully
    - Navigate to notification display after assessment completes
    - _Requirements: 3.1, 3.5, 17.1, 17.2_

  - [ ]* 19.2 Write widget tests for camera screen
    - Test capture button interaction
    - Test loading state display
    - Test error handling UI
    - Mock image capture service for testing
    - _Requirements: 3.5, 17.1_

- [x] 20. Risk notification display UI
  - [x] 20.1 Implement notification widget
    - Create `RiskNotificationWidget` with color-coded display (red for High Risk, green for Safe)
    - Display risk level, explanation text, and Filipino alternatives
    - Implement dismiss functionality
    - Auto-dismiss after 10 seconds
    - Use custom overlay widget for rich in-app notifications
    - Optionally integrate `flutter_local_notifications` for system-level notifications
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 20.2 Write widget tests for notification display
    - Test color coding for risk levels
    - Test alternative suggestions display
    - Test dismiss interaction
    - _Requirements: 8.2, 8.3, 8.5_

- [x] 21. Dashboard UI with analytics
  - [x] 21.1 Implement dashboard screen
    - Create `DashboardScreen` with tab navigation (Charts, History)
    - Implement `NutrientChartWidget` using `fl_chart` package for line charts
    - Display 4 charts: sodium, potassium, phosphorus, protein (daily consumption vs limits over 30 days)
    - Implement `ProgressRingWidget` for current day's consumption percentage
    - Implement data aggregation logic: group assessments by date, sum nutrients, calculate percentage
    - Display limit threshold lines on charts
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.7_

  - [x] 21.2 Implement assessment history list
    - Create `AssessmentListWidget` with scrollable list of historical assessments
    - Display: timestamp, food name, risk level badge, tap to view details
    - Implement date selection on chart to filter list
    - Load assessments from Firestore Stream for real-time updates
    - _Requirements: 9.6, 11.6, 11.8_

  - [x] 21.3 Implement search and filter functionality
    - Create `FilterBarWidget` with search input for food name
    - Add date range picker for filtering by time period
    - Add toggle for "High Risk only" filter
    - Display count of filtered results
    - Query Firestore with filter conditions
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6_

  - [ ]* 21.4 Write widget tests for dashboard
    - Test chart rendering with mock data
    - Test date selection interaction
    - Test filter application
    - Mock Firestore stream for testing
    - _Requirements: 11.6, 19.4_

- [ ] 22. Offline mode and network error handling
  - [ ] 22.1 Implement offline mode support
    - Display network unavailable banner when device is offline
    - Disable image capture module when offline
    - Load cached assessments from Hive for dashboard viewing
    - Display retry option for failed API requests
    - Implement sync logic when connectivity is restored
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.6_

  - [ ]* 22.2 Write integration tests for offline mode
    - Test cached data display when offline
    - Test sync when connectivity restored
    - Test error messages for offline operations
    - _Requirements: 13.3, 13.6_

- [ ] 23. Onboarding flow
  - [ ] 23.1 Implement onboarding screens
    - Create multi-step onboarding tutorial with page indicators
    - Guide users through dietary profile configuration
    - Demonstrate image capture workflow with visual examples
    - Explain risk level classifications and notification colors
    - Implement skip functionality with access from settings
    - Mark onboarding as completed in user profile
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6_

  - [ ]* 23.2 Write widget tests for onboarding
    - Test page navigation
    - Test skip functionality
    - Test completion marking
    - _Requirements: 20.5, 20.6_

- [ ] 24. Checkpoint - UI layer complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 25. Integration and wiring
  - [x] 25.1 Wire all components together in main.dart
    - Initialize Firebase in main() function
    - Load environment variables from .env file
    - Set up ProviderScope for Riverpod
    - Configure app theme with color scheme
    - Set up navigation routes (login, register, dashboard, camera, profile, onboarding)
    - Implement auth state routing: redirect to login if not authenticated
    - Configure global error boundary
    - _Requirements: 1.6, 17.4, 17.5_

  - [x] 25.2 Implement app-wide error handling
    - Configure Firebase Crashlytics for error logging
    - Implement error logging with context (userId, timestamp)
    - Set up global error boundary with restart functionality
    - Ensure no sensitive data (emails, health info) logged in plain text
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5, 18.6_

  - [ ]* 25.3 Write end-to-end tests for critical flows
    - Test complete assessment flow: login → capture → view notification → check dashboard → logout
    - Test profile configuration flow: login → update profile → capture → verify new limits applied
    - Test offline mode flow: login → disable network → view cached dashboard → enable network → verify sync
    - Use Firebase Emulator Suite for testing
    - _Requirements: 1.6, 13.6, 17.4_

- [ ] 26. Performance optimization
  - Implement query pagination for assessment history (20 items per page)
  - Limit dashboard queries to 90 days by default
  - Implement local caching for dietary profile to reduce Firestore reads
  - Verify image compression achieves <2MB file size
  - Test app startup time (target: <3 seconds cold start)
  - Test dashboard load time (target: <2 seconds for 30 days data)
  - _Requirements: 14.1, 14.4, 14.5_

- [ ] 27. Final testing and validation
  - Run complete test suite: unit tests, widget tests, integration tests, property-based tests
  - Verify all property-based tests pass with 100 iterations
  - Test on physical Android device with various network conditions
  - Verify Firebase security rules prevent unauthorized access
  - Test error scenarios: network failures, API timeouts, invalid responses
  - Verify image deletion lifecycle (immediate + 24-hour fallback)
  - Validate KDIGO compliance for all CKD stages
  - _Requirements: All_

- [ ] 28. Build configuration and deployment preparation
  - Configure build variants (debug, release) with different API keys
  - Set up ProGuard rules for release builds
  - Configure app signing for release
  - Generate release APK with production API keys
  - Test release build on physical device
  - Prepare Firebase project for production (security rules, quotas)
  - Document deployment process and API key management
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

- [ ] 29. Final checkpoint - Implementation complete
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Property-based tests (tasks 6.2-6.6) validate universal correctness properties for the Risk Assessment Engine
- Checkpoints ensure incremental validation at major milestones
- Firebase Emulator Suite should be used for local testing to avoid production costs
- All API keys must be loaded from environment variables, never hardcoded
- Image privacy is critical: ensure deletion happens in finally blocks
- The implementation follows Clean Architecture: complete data layer before presentation layer
- Use Riverpod for dependency injection and state management throughout
- Offline support is essential: implement local caching early in the data layer
