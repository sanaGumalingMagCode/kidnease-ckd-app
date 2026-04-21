# Technical Design Document: Kidnease CKD Tracking Application

## Overview

### Purpose

This design document specifies the technical architecture, component interactions, data models, and implementation approach for the Kidnease CKD tracking application. Kidnease is a privacy-first mobile health application that leverages multimodal AI vision to provide real-time dietary risk assessments for Chronic Kidney Disease (CKD) patients and at-risk individuals.

### System Context

Kidnease operates as a Flutter-based Android mobile application with a Firebase backend infrastructure. The system integrates two external AI/data services:

1. **Google Gemini 3.0 Pro API** - Multimodal AI vision for food image analysis, nutritional extraction, and culturally relevant dietary recommendations
2. **FatSecret API** - Commercial nutritional database for packaged food product baseline data

The application follows a "privacy-first, on-the-fly processing" model where food images are temporarily stored, processed through AI services, and immediately deleted. Only text-based assessment results and user-configured dietary limits persist in cloud storage.

### Key Design Principles

1. **Privacy by Design**: Raw food images are ephemeral; only structured assessment data persists
2. **Clean Architecture**: Clear separation between presentation, domain, and data layers
3. **Cost Optimization**: Aggressive image compression, lifecycle policies, and query optimization
4. **Offline Resilience**: Local caching enables dashboard viewing without connectivity
5. **KDIGO Compliance**: Risk assessments align with evidence-based clinical guidelines
6. **Cultural Relevance**: AI prompts optimized for Filipino dietary context and alternatives

## Architecture

### High-Level Architecture

The system follows a **Clean Architecture** pattern with three primary layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Auth Screens │  │ Camera UI    │  │ Dashboard UI │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Profile UI   │  │ Notification │  │ Onboarding   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Risk Assessment Engine (Business Logic)      │   │
│  │  • Nutrient Comparison  • Risk Classification        │   │
│  │  • Explanation Generation                            │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ User Entity  │  │ Assessment   │  │ Dietary      │      │
│  │              │  │ Entity       │  │ Profile      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Firestore    │  │ Cloud Storage│  │ Local Cache  │      │
│  │ Repository   │  │ Repository   │  │ Repository   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Gemini API   │  │ FatSecret API│  │ Firebase Auth│      │
│  │ Client       │  │ Client       │  │ Service      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer**
- Flutter widgets and UI components
- State management using Riverpod providers
- User input handling and validation
- Navigation and routing
- Loading states and error displays

**Domain Layer**
- Business logic and rules
- Entity models (pure Dart classes)
- Use cases and interactors
- Risk assessment algorithms
- KDIGO guideline enforcement

**Data Layer**
- Repository implementations
- API client services
- Data source abstractions
- DTO (Data Transfer Object) models
- Caching strategies

### State Management Strategy

The application uses **Riverpod** for state management with the following provider types:

1. **StateNotifierProvider**: For complex state with business logic (authentication, assessment flow)
2. **FutureProvider**: For asynchronous data fetching (Firestore queries, API calls)
3. **StreamProvider**: For real-time Firestore updates (assessment history)
4. **Provider**: For dependency injection (repositories, API clients)

### Data Flow: Image Capture to Risk Notification

```
User Captures Image
       │
       ▼
Image Compression (max 2MB)
       │
       ▼
Upload to Cloud Storage
       │
       ▼
Generate Secure Image URL
       │
       ├──────────────────────┐
       ▼                      ▼
FatSecret API Query    Gemini API Request
(if commercial food)   (with Image URL + Profile)
       │                      │
       └──────────┬───────────┘
                  ▼
       Risk Assessment Engine
       (Compare vs KDIGO Limits)
                  │
                  ▼
       ┌─────────┴─────────┐
       ▼                   ▼
Save to Firestore    Display Notification
       │                   │
       ▼                   ▼
Delete Image Blob    Show Alternatives
```

## Components and Interfaces

### 1. Authentication Service

**Responsibility**: User registration, login, session management

**Interface**:
```dart
abstract class AuthenticationService {
  Future<User> registerWithEmail(String email, String password);
  Future<User> signInWithEmail(String email, String password);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  User? get currentUser;
}
```

**Implementation**: `FirebaseAuthenticationService`
- Uses Firebase Authentication SDK
- Handles error codes (weak-password, email-already-in-use, user-not-found, wrong-password)
- Maintains auth state stream for reactive UI updates

### 2. Image Capture Module

**Responsibility**: Camera interface, image compression, quality validation

**Interface**:
```dart
abstract class ImageCaptureService {
  Future<File> captureImage();
  Future<File> compressImage(File originalImage, {int maxSizeKB = 2048});
  Future<bool> validateImageQuality(File image);
}
```

**Implementation**: `CameraImageCaptureService`
- Uses `image_picker` package for camera access
- Uses `flutter_image_compress` for compression
- Validates minimum resolution (800x600) for OCR readability
- Outputs JPEG format with 85% quality

### 3. Cloud Storage Repository

**Responsibility**: Image upload, URL generation, deletion lifecycle

**Interface**:
```dart
abstract class CloudStorageRepository {
  Future<String> uploadImage(File imageFile, String userId);
  Future<void> deleteImage(String imageUrl);
  Future<void> setLifecyclePolicy(int maxAgeHours);
}
```

**Implementation**: `FirebaseCloudStorageRepository`
- Uploads to path: `users/{userId}/food_images/{timestamp}.jpg`
- Generates signed URLs with 1-hour expiration
- Implements automatic deletion after assessment completion
- Fallback lifecycle policy: delete blobs older than 24 hours

### 4. Gemini API Client

**Responsibility**: Multimodal AI vision requests, response parsing, prompt engineering

**Interface**:
```dart
abstract class GeminiApiClient {
  Future<GeminiResponse> analyzeFood({
    required String imageUrl,
    required DietaryProfile userProfile,
    NutritionalData? fatSecretData,
  });
}

class GeminiResponse {
  final String detectedFoodName;
  final double sodium;
  final double potassium;
  final double phosphorus;
  final double protein;
  final String riskLevel;
  final String explanationText;
  final List<String> filipinoAlternatives;
}
```

**Implementation**: `GeminiApiClientImpl`
- Endpoint: `https://generativelanguage.googleapis.com/v1/models/gemini-3.0-pro:generateContent`
- Request timeout: 10 seconds
- Retry logic: 2 retries with exponential backoff
- Prompt structure:
  ```
  You are a renal nutrition assistant analyzing food for CKD patients.
  
  User's Daily Limits:
  - Sodium: {dailySodiumLimit} mg
  - Potassium: {dailyPotassiumLimit} mg
  - Phosphorus: {dailyPhosphorusLimit} mg
  - Protein: {dailyProteinLimit} g
  
  [If FatSecret data available]
  Commercial Product Data: {fatSecretData}
  
  Analyze this food image and extract:
  1. Food name
  2. Nutritional content (sodium, potassium, phosphorus, protein)
  3. Risk assessment (compare to user limits)
  4. Simple cause-and-effect explanation of renal impact
  5. Filipino renal-friendly alternatives if high risk
  
  Return JSON format:
  {
    "detectedFoodName": "string",
    "sodium": number,
    "potassium": number,
    "phosphorus": number,
    "protein": number,
    "riskLevel": "High Risk" | "Safe",
    "explanationText": "string",
    "filipinoAlternatives": ["string"]
  }
  ```

**Response Validation**:
- Validates JSON structure
- Checks required fields presence
- Validates riskLevel enum values
- Sanitizes explanationText (removes HTML, limits length to 500 chars)
- Defaults missing nutritional values to 0.0 with warning log

### 5. FatSecret API Client

**Responsibility**: Commercial food product nutritional data retrieval

**Interface**:
```dart
abstract class FatSecretApiClient {
  Future<NutritionalData?> searchProduct(String productName);
}

class NutritionalData {
  final String productName;
  final double sodium;
  final double potassium;
  final double phosphorus;
  final double protein;
  final String servingSize;
}
```

**Implementation**: `FatSecretApiClientImpl`
- Uses OAuth 1.0 authentication
- Endpoint: `https://platform.fatsecret.com/rest/server.api`
- Method: `foods.search`
- Request timeout: 5 seconds
- Handles rate limiting (429 status) with exponential backoff
- Returns null if no match found (non-error case)

### 6. Risk Assessment Engine

**Responsibility**: Core business logic for dietary risk evaluation

**Interface**:
```dart
abstract class RiskAssessmentEngine {
  RiskAssessment evaluateRisk({
    required ExtractedNutrients nutrients,
    required DietaryProfile profile,
  });
}

class RiskAssessment {
  final RiskLevel riskLevel;
  final String explanation;
  final List<String> exceededNutrients;
}

enum RiskLevel { safe, highRisk }
```

**Implementation**: `RiskAssessmentEngineImpl`

**Algorithm**:
```dart
1. Compare each nutrient against daily limit:
   - sodium > dailySodiumLimit → flag sodium
   - potassium > dailyPotassiumLimit → flag potassium
   - phosphorus > dailyPhosphorusLimit → flag phosphorus
   - protein > dailyProteinLimit → flag protein

2. Determine risk level:
   - If any nutrient exceeds limit → RiskLevel.highRisk
   - If all within limits → RiskLevel.safe

3. Generate explanation:
   - For each exceeded nutrient, append:
     "High {nutrient} ({value}mg) exceeds your daily limit ({limit}mg), 
      which may strain kidney filtration."
   - If safe: "All nutrients within your daily limits."
```

### 7. Firestore Repository

**Responsibility**: CRUD operations for all Firestore collections

**Interface**:
```dart
abstract class FirestoreRepository {
  // Users
  Future<UserProfile> getUserProfile(String userId);
  Future<void> createUserProfile(UserProfile profile);
  
  // Dietary Profiles
  Future<DietaryProfile> getDietaryProfile(String userId);
  Future<void> saveDietaryProfile(DietaryProfile profile);
  
  // Assessments
  Future<String> createAssessment(DietaryAssessment assessment);
  Stream<List<DietaryAssessment>> getAssessmentHistory(String userId, {int limit = 100});
  Future<List<DietaryAssessment>> searchAssessments(String userId, AssessmentFilter filter);
  
  // Nutrients
  Future<void> saveExtractedNutrients(ExtractedNutrients nutrients);
  Future<ExtractedNutrients> getNutrientsByAssessmentId(String assessmentId);
  
  // Notifications
  Future<void> createNotification(RiskNotification notification);
}
```

**Implementation**: `FirestoreRepositoryImpl`
- Uses Firebase Firestore SDK
- Implements indexed queries for performance
- Handles offline persistence automatically via Firestore SDK
- Uses transactions for multi-document writes

### 8. Local Cache Repository

**Responsibility**: Offline data persistence for dashboard viewing

**Interface**:
```dart
abstract class LocalCacheRepository {
  Future<void> cacheAssessments(List<DietaryAssessment> assessments);
  Future<List<DietaryAssessment>> getCachedAssessments(String userId);
  Future<void> cacheDietaryProfile(DietaryProfile profile);
  Future<DietaryProfile?> getCachedDietaryProfile(String userId);
  Future<void> clearCache();
}
```

**Implementation**: `HiveLocalCacheRepository`
- Uses Hive package for local NoSQL storage
- Stores most recent 100 assessments
- Implements LRU eviction policy
- Encrypts sensitive data using `hive_flutter` encryption

### 9. Notification Service

**Responsibility**: Real-time UI notification display

**Interface**:
```dart
abstract class NotificationService {
  void showRiskNotification({
    required RiskLevel riskLevel,
    required String explanation,
    List<String> alternatives = const [],
  });
  void dismissNotification();
}
```

**Implementation**: `InAppNotificationService`
- Uses `flutter_local_notifications` for system-level notifications
- Uses custom overlay widget for in-app rich notifications
- Color scheme:
  - High Risk: Red (#D32F2F) with warning icon
  - Safe: Green (#388E3C) with checkmark icon
- Auto-dismiss after 10 seconds (user can dismiss earlier)

### 10. Dashboard Module

**Responsibility**: Longitudinal analytics visualization

**Components**:
- `NutrientChartWidget`: Line chart showing daily consumption vs limits
- `ProgressRingWidget`: Circular progress indicator for current day
- `AssessmentListWidget`: Scrollable list of historical assessments
- `FilterBarWidget`: Search and filter controls

**Chart Library**: `fl_chart` package

**Data Aggregation Logic**:
```dart
1. Query assessments for date range (default: last 30 days)
2. Group assessments by date
3. For each date, sum nutrients from ExtractedNutrients
4. Calculate percentage: (dailyTotal / dailyLimit) * 100
5. Plot data points with limit threshold line
```

## Data Models

### Firestore Collections

#### 1. Users Collection

**Path**: `/users/{userId}`

**Schema**:
```dart
class UserProfile {
  final String userId;
  final String email;
  final String name;
  final UserRole role; // patient, caregiver, healthcareProvider
  final DateTime createdAt;
  final bool onboardingCompleted;
}
```

**Firestore Document**:
```json
{
  "userId": "string",
  "email": "string",
  "name": "string",
  "role": "patient",
  "createdAt": "timestamp",
  "onboardingCompleted": false
}
```

**Indexes**: None (queries by document ID only)

#### 2. DietaryProfiles Collection

**Path**: `/dietaryProfiles/{profileId}`

**Schema**:
```dart
class DietaryProfile {
  final String profileId;
  final String userId;
  final double dailySodiumLimit; // mg
  final double dailyPotassiumLimit; // mg
  final double dailyPhosphorusLimit; // mg
  final double dailyProteinLimit; // g
  final DateTime lastUpdated;
  final int ckdStage; // 1-5
}
```

**Firestore Document**:
```json
{
  "profileId": "string",
  "userId": "string",
  "dailySodiumLimit": 2000.0,
  "dailyPotassiumLimit": 2000.0,
  "dailyPhosphorusLimit": 1000.0,
  "dailyProteinLimit": 50.0,
  "lastUpdated": "timestamp",
  "ckdStage": 3
}
```

**Indexes**: 
- `userId` (ascending) - for user profile lookup

**KDIGO Reference Limits** (embedded in app, not Firestore):
```dart
const Map<int, DietaryLimits> kdogoLimits = {
  1: DietaryLimits(sodium: 2300, potassium: 3500, phosphorus: 1200, protein: 60),
  2: DietaryLimits(sodium: 2300, potassium: 3000, phosphorus: 1200, protein: 60),
  3: DietaryLimits(sodium: 2000, potassium: 2500, phosphorus: 1000, protein: 50),
  4: DietaryLimits(sodium: 2000, potassium: 2000, phosphorus: 900, protein: 40),
  5: DietaryLimits(sodium: 1500, potassium: 2000, phosphorus: 800, protein: 40),
};
```

#### 3. DietaryAssessments Collection

**Path**: `/dietaryAssessments/{assessmentId}`

**Schema**:
```dart
class DietaryAssessment {
  final String assessmentId;
  final String userId;
  final DateTime timestamp;
  final String imageUrl; // Will become invalid after deletion
  final String detectedFoodName;
  final RiskLevel riskLevel;
  final String explanationText;
  final List<String> filipinoAlternatives;
}
```

**Firestore Document**:
```json
{
  "assessmentId": "string",
  "userId": "string",
  "timestamp": "timestamp",
  "imageUrl": "string",
  "detectedFoodName": "string",
  "riskLevel": "High Risk",
  "explanationText": "string",
  "filipinoAlternatives": ["string"]
}
```

**Indexes**:
- `userId` (ascending), `timestamp` (descending) - for history queries
- `userId` (ascending), `riskLevel` (ascending), `timestamp` (descending) - for filtered queries

#### 4. ExtractedNutrients Collection

**Path**: `/extractedNutrients/{nutrientRecordId}`

**Schema**:
```dart
class ExtractedNutrients {
  final String nutrientRecordId;
  final String assessmentId;
  final double sodiumValue; // mg
  final double potassiumValue; // mg
  final double phosphorusValue; // mg
  final double proteinValue; // g
  final String source; // "gemini", "fatsecret", "hybrid"
}
```

**Firestore Document**:
```json
{
  "nutrientRecordId": "string",
  "assessmentId": "string",
  "sodiumValue": 450.0,
  "potassiumValue": 320.0,
  "phosphorusValue": 180.0,
  "proteinValue": 12.0,
  "source": "gemini"
}
```

**Indexes**:
- `assessmentId` (ascending) - for nutrient lookup by assessment

#### 5. RiskNotifications Collection

**Path**: `/riskNotifications/{notificationId}`

**Schema**:
```dart
class RiskNotification {
  final String notificationId;
  final String userId;
  final String assessmentId;
  final String severityLevel; // "high", "safe"
  final String displayMessage;
  final DateTime timestamp;
  final bool dismissed;
}
```

**Firestore Document**:
```json
{
  "notificationId": "string",
  "userId": "string",
  "assessmentId": "string",
  "severityLevel": "high",
  "displayMessage": "string",
  "timestamp": "timestamp",
  "dismissed": false
}
```

**Indexes**:
- `userId` (ascending), `timestamp` (descending) - for notification history

### Domain Entities

Domain entities are pure Dart classes with business logic methods:

```dart
class DietaryProfile {
  // ... fields ...
  
  bool isWithinKdogoRange(int ckdStage) {
    final reference = kdogoLimits[ckdStage]!;
    return dailySodiumLimit >= reference.sodium * 0.5 &&
           dailySodiumLimit <= reference.sodium * 2.0 &&
           // ... similar for other nutrients
  }
  
  double getCompliancePercentage(ExtractedNutrients nutrients) {
    final sodiumCompliance = (nutrients.sodiumValue / dailySodiumLimit).clamp(0, 1);
    // ... calculate for all nutrients
    return (sodiumCompliance + potassiumCompliance + 
            phosphorusCompliance + proteinCompliance) / 4 * 100;
  }
}
```

### DTOs (Data Transfer Objects)

DTOs handle serialization/deserialization between Firestore and domain entities:

```dart
class DietaryProfileDto {
  final Map<String, dynamic> data;
  
  DietaryProfileDto.fromFirestore(DocumentSnapshot doc) 
    : data = doc.data() as Map<String, dynamic>;
  
  DietaryProfile toDomain() {
    return DietaryProfile(
      profileId: data['profileId'],
      userId: data['userId'],
      dailySodiumLimit: (data['dailySodiumLimit'] as num).toDouble(),
      // ... map all fields
    );
  }
  
  static Map<String, dynamic> fromDomain(DietaryProfile profile) {
    return {
      'profileId': profile.profileId,
      'userId': profile.userId,
      'dailySodiumLimit': profile.dailySodiumLimit,
      // ... map all fields
    };
  }
}
```



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

The Kidnease application contains a core component suitable for property-based testing: the **Risk Assessment Engine**. This component implements pure business logic for comparing nutritional values against dietary limits and classifying risk levels. The following properties specify the correctness requirements for this critical component.

### Property 1: Nutrient Comparison Correctness

*For any* nutritional value and corresponding daily limit, the Risk Assessment Engine SHALL correctly identify whether the value exceeds the limit using standard numerical comparison (value > limit).

**Validates: Requirements 6.1, 6.2, 6.3, 6.4**

### Property 2: High Risk Classification

*For any* set of extracted nutrients (sodium, potassium, phosphorus, protein) and dietary profile limits, if at least one nutrient value exceeds its corresponding daily limit, the Risk Assessment Engine SHALL classify the risk level as "High Risk".

**Validates: Requirements 6.5**

### Property 3: Safe Classification

*For any* set of extracted nutrients (sodium, potassium, phosphorus, protein) and dietary profile limits, if all nutrient values are within or equal to their corresponding daily limits, the Risk Assessment Engine SHALL classify the risk level as "Safe".

**Validates: Requirements 6.6**

### Property 4: Explanation Contains Exceeded Nutrients

*For any* risk assessment classified as "High Risk", the generated explanation text SHALL contain the names of all nutrients that exceeded their daily limits.

**Validates: Requirements 6.7**

### Property 5: KDIGO Range Validation

*For any* KDIGO reference limit value, the dietary profile validation logic SHALL accept custom limit values within the range [0.5 × reference, 2.0 × reference] and reject values outside this range.

**Validates: Requirements 15.3**

## Error Handling

### Error Categories

The application handles four primary error categories:

1. **Network Errors**: Connectivity failures, timeouts, DNS resolution
2. **API Errors**: External service failures, rate limiting, invalid responses
3. **Validation Errors**: Invalid user input, malformed data
4. **System Errors**: Storage failures, permission denials, unexpected exceptions

### Error Handling Strategy by Component

#### Authentication Service

**Errors**:
- `weak-password`: Password less than 6 characters
- `email-already-in-use`: Registration with existing email
- `user-not-found`: Login with non-existent email
- `wrong-password`: Incorrect password
- `network-request-failed`: No internet connectivity

**Handling**:
```dart
try {
  await authService.signInWithEmail(email, password);
} on FirebaseAuthException catch (e) {
  switch (e.code) {
    case 'user-not-found':
      showError('No account found with this email');
    case 'wrong-password':
      showError('Incorrect password');
    case 'network-request-failed':
      showError('No internet connection. Please check your network.');
    default:
      showError('Authentication failed: ${e.message}');
  }
}
```

#### Image Capture and Upload

**Errors**:
- Camera permission denied
- Image compression failure
- Upload timeout (30 seconds)
- Storage quota exceeded

**Handling**:
```dart
try {
  final image = await imageCaptureService.captureImage();
  final compressed = await imageCaptureService.compressImage(image);
  final url = await cloudStorageRepo.uploadImage(compressed, userId);
} on CameraException catch (e) {
  if (e.code == 'camera_access_denied') {
    showError('Camera permission required. Please enable in settings.');
  }
} on StorageException catch (e) {
  if (e.code == 'quota-exceeded') {
    showError('Storage limit reached. Please contact support.');
  } else {
    showError('Upload failed. Please try again.');
    // Retry logic: exponential backoff with max 3 attempts
  }
} on TimeoutException {
  showError('Upload timed out. Please check your connection.');
}
```

#### Gemini API Client

**Errors**:
- HTTP 429: Rate limit exceeded
- HTTP 400: Invalid request format
- HTTP 500: Server error
- Timeout (10 seconds)
- Invalid JSON response
- Missing required fields

**Handling**:
```dart
try {
  final response = await geminiClient.analyzeFood(
    imageUrl: url,
    userProfile: profile,
  );
} on GeminiApiException catch (e) {
  if (e.statusCode == 429) {
    // Rate limit: exponential backoff retry
    await Future.delayed(Duration(seconds: 2 ^ retryCount));
    return retry();
  } else if (e.statusCode >= 500) {
    showError('AI service temporarily unavailable. Please try again.');
  } else {
    showError('Analysis failed: ${e.message}');
  }
} on JsonParseException {
  logError('Invalid Gemini response format', response);
  showError('Unable to process AI response. Please try again.');
} on ValidationException catch (e) {
  logError('Missing required fields in Gemini response', e.missingFields);
  showError('Incomplete analysis results. Please try again.');
}
```

#### FatSecret API Client

**Errors**:
- HTTP 429: Rate limit exceeded
- HTTP 401: Invalid OAuth credentials
- No matching product found (not an error)

**Handling**:
```dart
try {
  final nutritionData = await fatSecretClient.searchProduct(productName);
  if (nutritionData == null) {
    // Not an error - proceed with Gemini-only analysis
    return null;
  }
  return nutritionData;
} on FatSecretApiException catch (e) {
  if (e.statusCode == 429) {
    logWarning('FatSecret rate limit reached');
    return null; // Graceful degradation to Gemini-only
  } else if (e.statusCode == 401) {
    logError('FatSecret authentication failed');
    return null; // Graceful degradation
  }
}
```

#### Firestore Operations

**Errors**:
- Permission denied
- Network unavailable
- Document not found
- Write conflict

**Handling**:
```dart
try {
  await firestoreRepo.createAssessment(assessment);
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    logError('Firestore permission denied for user', userId);
    showError('Unable to save data. Please sign in again.');
  } else if (e.code == 'unavailable') {
    // Offline: queue for sync when online
    await localCache.queueForSync(assessment);
    showInfo('Saved locally. Will sync when online.');
  }
}
```

### Global Error Boundary

The application implements a global error boundary using Flutter's `ErrorWidget.builder`:

```dart
ErrorWidget.builder = (FlutterErrorDetails details) {
  logError('Uncaught error', details.exception, details.stack);
  return ErrorDisplayWidget(
    message: 'Something went wrong. Please restart the app.',
    onRetry: () => RestartWidget.restartApp(context),
  );
};
```

### Error Logging

All errors are logged to Firebase Crashlytics with context:

```dart
void logError(String message, dynamic error, [StackTrace? stack]) {
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: message,
    information: [
      'userId: ${authService.currentUser?.uid ?? "anonymous"}',
      'timestamp: ${DateTime.now().toIso8601String()}',
    ],
  );
}
```

## Testing Strategy

### Testing Approach

The Kidnease application requires a multi-layered testing strategy combining:

1. **Property-Based Tests**: For pure business logic (Risk Assessment Engine)
2. **Unit Tests**: For component-level behavior with specific examples
3. **Integration Tests**: For API clients and Firebase interactions
4. **Widget Tests**: For UI components and user interactions
5. **End-to-End Tests**: For critical user flows

### Property-Based Testing

**Library**: `test` package with custom property test harness (Dart does not have a mature PBT library like QuickCheck or Hypothesis)

**Alternative**: Use `faker` package for randomized input generation within standard unit tests

**Configuration**:
- Minimum 100 iterations per property test
- Each test tagged with: `@Tags(['pbt', 'feature:kidnease-ckd-tracking-app'])`
- Comment format: `// Feature: kidnease-ckd-tracking-app, Property {number}: {property_text}`

**Property Test Implementation Example**:

```dart
// Feature: kidnease-ckd-tracking-app, Property 2: High Risk Classification
@Tags(['pbt', 'risk-assessment'])
void main() {
  group('Risk Assessment Engine - Property Tests', () {
    test('Property 2: High risk when any nutrient exceeds limit', () {
      final engine = RiskAssessmentEngineImpl();
      final random = Random();
      
      for (int i = 0; i < 100; i++) {
        // Generate random limits
        final profile = DietaryProfile(
          dailySodiumLimit: 1000 + random.nextDouble() * 2000,
          dailyPotassiumLimit: 1000 + random.nextDouble() * 2000,
          dailyPhosphorusLimit: 500 + random.nextDouble() * 1000,
          dailyProteinLimit: 30 + random.nextDouble() * 50,
        );
        
        // Generate nutrients where at least one exceeds
        final exceededNutrient = random.nextInt(4);
        final nutrients = ExtractedNutrients(
          sodiumValue: exceededNutrient == 0 
            ? profile.dailySodiumLimit + 1 + random.nextDouble() * 500
            : random.nextDouble() * profile.dailySodiumLimit,
          potassiumValue: exceededNutrient == 1
            ? profile.dailyPotassiumLimit + 1 + random.nextDouble() * 500
            : random.nextDouble() * profile.dailyPotassiumLimit,
          phosphorusValue: exceededNutrient == 2
            ? profile.dailyPhosphorusLimit + 1 + random.nextDouble() * 500
            : random.nextDouble() * profile.dailyPhosphorusLimit,
          proteinValue: exceededNutrient == 3
            ? profile.dailyProteinLimit + 1 + random.nextDouble() * 50
            : random.nextDouble() * profile.dailyProteinLimit,
        );
        
        final result = engine.evaluateRisk(
          nutrients: nutrients,
          profile: profile,
        );
        
        expect(result.riskLevel, RiskLevel.highRisk,
          reason: 'Iteration $i: At least one nutrient exceeded limit');
      }
    });
  });
}
```

### Unit Testing

**Framework**: `test` package

**Coverage Targets**:
- Domain logic: 90%+
- Repositories: 80%+
- API clients: 80%+
- UI components: 70%+

**Key Unit Test Suites**:

1. **Risk Assessment Engine**
   - Specific examples for each nutrient exceeding limit
   - Edge cases: zero values, exact limit matches
   - Explanation text formatting

2. **Dietary Profile Validation**
   - KDIGO range boundary tests
   - Invalid input rejection (negative values, zero)
   - CKD stage mapping

3. **Gemini Response Parser**
   - Valid JSON parsing
   - Missing field handling
   - Invalid enum value handling
   - Sanitization of explanation text

4. **Image Compression**
   - File size reduction verification
   - Quality preservation checks
   - Format conversion (PNG → JPEG)

### Integration Testing

**Framework**: `integration_test` package

**Test Suites**:

1. **Firebase Authentication Flow**
   - Register → Login → Logout
   - Invalid credentials handling
   - Session persistence

2. **Firestore CRUD Operations**
   - Create assessment with nutrients
   - Query assessment history
   - Filter and search operations
   - Offline persistence

3. **Cloud Storage Lifecycle**
   - Upload → Generate URL → Delete
   - Lifecycle policy verification
   - Permission validation

4. **API Client Integration** (with mocked backends)
   - Gemini API request/response cycle
   - FatSecret API search and parse
   - Timeout and retry logic

### Widget Testing

**Framework**: `flutter_test` package

**Test Suites**:

1. **Authentication Screens**
   - Form validation
   - Error message display
   - Navigation after successful login

2. **Camera Interface**
   - Capture button interaction
   - Loading state display
   - Error handling UI

3. **Dashboard Charts**
   - Data visualization rendering
   - Date selection interaction
   - Filter application

4. **Notification Display**
   - Risk level color coding
   - Alternative suggestions display
   - Dismiss interaction

### End-to-End Testing

**Framework**: `integration_test` with Firebase Test Lab

**Critical User Flows**:

1. **Complete Assessment Flow**
   ```
   Launch App → Login → Capture Image → View Risk Notification → 
   Check Dashboard → Logout
   ```

2. **Profile Configuration Flow**
   ```
   Launch App → Login → Navigate to Profile → Update Limits → 
   Verify KDIGO Validation → Save → Capture Image → 
   Verify New Limits Applied
   ```

3. **Offline Mode Flow**
   ```
   Launch App → Login → Disable Network → View Cached Dashboard → 
   Attempt Image Capture (should fail gracefully) → 
   Enable Network → Verify Sync
   ```

### Test Data Management

**Approach**: Use Firebase Emulator Suite for local testing

**Setup**:
```bash
firebase emulators:start --only auth,firestore,storage
```

**Test Data Seeding**:
```dart
Future<void> seedTestData() async {
  final firestore = FirebaseFirestore.instance;
  
  // Create test user
  await firestore.collection('users').doc('test-user-1').set({
    'userId': 'test-user-1',
    'email': 'test@example.com',
    'name': 'Test User',
    'role': 'patient',
    'createdAt': FieldValue.serverTimestamp(),
  });
  
  // Create test dietary profile
  await firestore.collection('dietaryProfiles').doc('profile-1').set({
    'profileId': 'profile-1',
    'userId': 'test-user-1',
    'dailySodiumLimit': 2000.0,
    'dailyPotassiumLimit': 2000.0,
    'dailyPhosphorusLimit': 1000.0,
    'dailyProteinLimit': 50.0,
    'ckdStage': 3,
  });
}
```

### Continuous Integration

**CI Pipeline** (GitHub Actions):

```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter test integration_test/
      - uses: codecov/codecov-action@v3
```

### Performance Testing

**Metrics to Monitor**:
- Image upload time: < 5 seconds (2MB image on 4G)
- Gemini API response time: < 10 seconds
- Dashboard load time: < 2 seconds (30 days of data)
- App startup time: < 3 seconds (cold start)

**Tools**:
- Flutter DevTools for performance profiling
- Firebase Performance Monitoring for production metrics

---

## Implementation Notes

### Flutter Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp configuration
│   ├── router.dart                 # Navigation routes
│   └── theme.dart                  # App theme
├── core/
│   ├── constants/
│   │   ├── kdigo_limits.dart       # KDIGO reference data
│   │   └── api_endpoints.dart      # API URLs
│   ├── errors/
│   │   ├── exceptions.dart         # Custom exception classes
│   │   └── failures.dart           # Failure types
│   └── utils/
│       ├── logger.dart             # Logging utility
│       └── validators.dart         # Input validation
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── firebase_auth_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in.dart
│   │   │       └── sign_up.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       └── widgets/
│   │           └── auth_form.dart
│   ├── dietary_profile/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── food_assessment/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── gemini_api_datasource.dart
│   │   │   │   ├── fatsecret_api_datasource.dart
│   │   │   │   └── cloud_storage_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── assessment_model.dart
│   │   │   │   └── nutrients_model.dart
│   │   │   └── repositories/
│   │   │       └── assessment_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── assessment.dart
│   │   │   │   └── extracted_nutrients.dart
│   │   │   ├── repositories/
│   │   │   │   └── assessment_repository.dart
│   │   │   └── usecases/
│   │   │       ├── capture_and_assess_food.dart
│   │   │       └── evaluate_risk.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── assessment_provider.dart
│   │       ├── screens/
│   │       │   └── camera_screen.dart
│   │       └── widgets/
│   │           ├── camera_view.dart
│   │           └── risk_notification.dart
│   └── dashboard/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── screens/
│           │   └── dashboard_screen.dart
│           └── widgets/
│               ├── nutrient_chart.dart
│               ├── progress_ring.dart
│               └── assessment_list.dart
└── shared/
    ├── providers/
    │   └── providers.dart          # Global providers
    └── widgets/
        ├── loading_indicator.dart
        └── error_display.dart

test/
├── unit/
│   ├── domain/
│   │   └── risk_assessment_engine_test.dart
│   └── data/
│       └── gemini_response_parser_test.dart
├── widget/
│   └── camera_screen_test.dart
└── integration/
    └── assessment_flow_test.dart
```

### Dependency Injection with Riverpod

**Provider Setup**:

```dart
// lib/shared/providers/providers.dart

// Firebase instances
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final cloudStorageProvider = Provider((ref) => FirebaseStorage.instance);

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepositoryImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
    geminiClient: ref.watch(geminiApiClientProvider),
    fatSecretClient: ref.watch(fatSecretApiClientProvider),
    cloudStorage: ref.watch(cloudStorageProvider),
  );
});

// API Clients
final geminiApiClientProvider = Provider<GeminiApiClient>((ref) {
  return GeminiApiClientImpl(apiKey: const String.fromEnvironment('GEMINI_API_KEY'));
});

final fatSecretApiClientProvider = Provider<FatSecretApiClient>((ref) {
  return FatSecretApiClientImpl(
    consumerKey: const String.fromEnvironment('FATSECRET_KEY'),
    consumerSecret: const String.fromEnvironment('FATSECRET_SECRET'),
  );
});

// State Notifiers
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final assessmentStateProvider = StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
  return AssessmentNotifier(
    repository: ref.watch(assessmentRepositoryProvider),
  );
});
```

### Environment Configuration

**API Keys Management**:

Create `.env` file (not committed to git):
```
GEMINI_API_KEY=your_gemini_api_key
FATSECRET_KEY=your_fatsecret_consumer_key
FATSECRET_SECRET=your_fatsecret_consumer_secret
```

Load in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: KidneaseApp()));
}
```

Pass to build:
```bash
flutter build apk --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
                  --dart-define=FATSECRET_KEY=$FATSECRET_KEY \
                  --dart-define=FATSECRET_SECRET=$FATSECRET_SECRET
```

### Firebase Configuration

**Firebase Setup Steps**:

1. Create Firebase project at console.firebase.google.com
2. Add Android app with package name `com.kidnease.app`
3. Download `google-services.json` to `android/app/`
4. Enable Authentication (Email/Password)
5. Create Firestore database (start in production mode)
6. Create Cloud Storage bucket
7. Configure Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only read/write their own dietary profile
    match /dietaryProfiles/{profileId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
    
    // Users can only read/write their own assessments
    match /dietaryAssessments/{assessmentId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
    
    // Users can only read nutrients for their own assessments
    match /extractedNutrients/{nutrientId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Users can only read/write their own notifications
    match /riskNotifications/{notificationId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
  }
}
```

8. Configure Cloud Storage security rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/food_images/{imageId} {
      // Allow upload only for authenticated users to their own folder
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 2 * 1024 * 1024; // 2MB limit
      
      // Allow read only for the owner
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Allow delete for cleanup
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

9. Set up Cloud Storage lifecycle policy (via Firebase Console or gsutil):

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 1,
          "matchesPrefix": ["users/"]
        }
      }
    ]
  }
}
```

### Cost Optimization Strategies

1. **Image Compression**
   - Compress to max 2MB before upload
   - Use JPEG format (smaller than PNG)
   - Quality setting: 85% (balance between size and OCR readability)

2. **Cloud Storage Lifecycle**
   - Delete images immediately after assessment
   - Fallback lifecycle policy: 24-hour auto-deletion
   - Estimated cost: $0.026/GB/month × minimal storage = ~$0

3. **Firestore Query Optimization**
   - Use indexed queries (userId + timestamp)
   - Limit dashboard queries to 90 days by default
   - Implement pagination (20 assessments per page)
   - Cache dietary profile locally (rarely changes)

4. **API Cost Management**
   - Gemini API: ~$0.00025 per image analysis
   - FatSecret API: Free tier (10,000 calls/month)
   - Batch requests where possible
   - Implement request caching for repeated foods

5. **Local Caching**
   - Cache last 100 assessments for offline viewing
   - Cache dietary profile to avoid repeated Firestore reads
   - Use Hive for efficient local storage

**Estimated Monthly Costs** (for 1000 active users, 5 assessments/day):
- Firestore: ~$5 (150k reads, 150k writes)
- Cloud Storage: ~$0 (ephemeral storage)
- Gemini API: ~$37.50 (150k image analyses)
- FatSecret API: $0 (within free tier)
- **Total: ~$42.50/month**

### Privacy and Security Considerations

1. **Image Privacy**
   - Images deleted immediately after processing
   - No long-term visual data storage
   - Secure URLs with 1-hour expiration

2. **Data Encryption**
   - Firestore data encrypted at rest (automatic)
   - Local cache encrypted using Hive encryption
   - HTTPS for all API communications

3. **Authentication Security**
   - Firebase Authentication handles password hashing
   - Session tokens with automatic refresh
   - No passwords stored in app code

4. **API Key Security**
   - API keys loaded from environment variables
   - Not hardcoded in source code
   - Different keys for development/production

5. **HIPAA Considerations**
   - Disclaimer: App is not HIPAA-compliant
   - Users advised to consult healthcare providers
   - No PHI (Protected Health Information) stored beyond dietary data

---

## Document Metadata

- **Specification Type:** Technical Design (Requirements-First Workflow)
- **Feature Name:** kidnease-ckd-tracking-app
- **Target Platform:** Android (Flutter/Dart)
- **Backend Services:** Firebase (Authentication, Cloud Storage, Cloud Firestore)
- **External APIs:** Google Gemini 3.0 Pro API, FatSecret API
- **State Management:** Riverpod
- **Architecture Pattern:** Clean Architecture (Presentation, Domain, Data layers)
- **Testing Approach:** Property-Based Testing (Risk Assessment Engine), Unit Tests, Integration Tests, Widget Tests, E2E Tests
- **Document Version:** 1.0
- **Last Updated:** Initial Creation
