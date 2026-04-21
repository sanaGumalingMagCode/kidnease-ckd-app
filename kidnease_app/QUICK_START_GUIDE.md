# Kidnease Quick Start Guide

## What's Been Built

You have a **solid foundation** with:
- ✅ Complete project structure
- ✅ All domain entities with business logic
- ✅ Error handling framework
- ✅ Authentication system (Firebase)
- ✅ Dietary profile management with KDIGO validation
- ✅ **Risk Assessment Engine** (core business logic)

## What You Need to Complete

### 1. Get API Keys (5 minutes)

#### Gemini API Key
1. Go to https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key

#### FatSecret API (Optional for MVP)
1. Go to https://platform.fatsecret.com/api/
2. Register for API access
3. Get Consumer Key and Secret

#### Update .env file
```bash
cd kidnease_app
# Edit .env file with your actual keys
GEMINI_API_KEY=AIza...your_key_here
FATSECRET_KEY=your_key_here
FATSECRET_SECRET=your_secret_here
```

### 2. Set Up Firebase (10 minutes)

Follow the detailed guide in `FIREBASE_SETUP.md`, or quick steps:

```bash
# 1. Create Firebase project at console.firebase.google.com
# 2. Add Android app with package: com.kidnease.app
# 3. Download google-services.json
# 4. Place it in android/app/

# 5. Enable services in Firebase Console:
#    - Authentication (Email/Password)
#    - Firestore Database
#    - Cloud Storage

# 6. Deploy security rules
firebase deploy --only firestore:rules
firebase deploy --only storage:rules

# 7. Create indexes
firebase deploy --only firestore:indexes
```

### 3. Complete Critical Components

#### A. Gemini API Client (HIGHEST PRIORITY)

Create `lib/features/food_assessment/data/datasources/gemini_api_client.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiClient {
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  
  Future<Map<String, dynamic>> analyzeFood({
    required String imageUrl,
    required Map<String, double> userLimits,
  }) async {
    final prompt = '''
You are a renal nutrition assistant analyzing food for CKD patients.

User's Daily Limits:
- Sodium: ${userLimits['sodium']} mg
- Potassium: ${userLimits['potassium']} mg
- Phosphorus: ${userLimits['phosphorus']} mg
- Protein: ${userLimits['protein']} g

Analyze this food image and return JSON:
{
  "detectedFoodName": "string",
  "sodium": number,
  "potassium": number,
  "phosphorus": number,
  "protein": number,
  "riskLevel": "High Risk" or "Safe",
  "explanationText": "cause-and-effect explanation",
  "filipinoAlternatives": ["alternative1", "alternative2"]
}
''';

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-3.0-pro:generateContent?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [
            {'text': prompt},
            {'inline_data': {'mime_type': 'image/jpeg', 'data': imageUrl}}
          ]
        }]
      }),
    );

    return jsonDecode(response.body);
  }
}
```

#### B. State Management Setup

Create `lib/shared/providers/providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase instances
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Repositories
final authRepositoryProvider = Provider((ref) {
  return AuthRepositoryImpl(
    datasource: FirebaseAuthDatasource(
      firebaseAuth: ref.watch(firebaseAuthProvider),
      firestore: ref.watch(firestoreProvider),
    ),
  );
});

// Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
```

#### C. Simple Main App

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: KidneaseApp(),
    ),
  );
}

class KidneaseApp extends StatelessWidget {
  const KidneaseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kidnease',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Kidnease - CKD Tracking App'),
        ),
      ),
    );
  }
}
```

### 4. Run the App

```bash
cd kidnease_app
flutter pub get
flutter run
```

## Development Workflow

### Daily Development
```bash
# 1. Start with tests
flutter test

# 2. Run analyzer
flutter analyze

# 3. Format code
flutter format lib/

# 4. Run app
flutter run
```

### Before Committing
```bash
flutter analyze
flutter test
flutter format lib/
```

## Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution**: Download from Firebase Console and place in `android/app/`

### Issue: "Firebase not initialized"
**Solution**: Ensure `Firebase.initializeApp()` is called in `main()`

### Issue: "API key not found"
**Solution**: Check `.env` file exists and has correct keys

### Issue: "Camera permission denied"
**Solution**: Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## Next Features to Build (In Order)

1. **Login Screen** (Task 17)
   - Simple email/password form
   - Use `authRepositoryProvider`

2. **Camera Screen** (Task 19)
   - Use `image_picker` package
   - Capture and compress image

3. **Risk Notification** (Task 20)
   - Show risk level with color coding
   - Display explanation

4. **Dietary Profile Screen** (Task 18)
   - Input fields for 4 nutrients
   - KDIGO validation

5. **Dashboard** (Task 21)
   - List of assessments
   - Basic charts (optional)

## Testing Your Implementation

### Test Risk Assessment Engine
```dart
// test/features/food_assessment/domain/risk_assessment_engine_test.dart
void main() {
  test('High risk when sodium exceeds limit', () {
    final engine = RiskAssessmentEngineImpl();
    final profile = DietaryProfile(
      profileId: 'test',
      userId: 'test',
      dailySodiumLimit: 2000,
      dailyPotassiumLimit: 2000,
      dailyPhosphorusLimit: 1000,
      dailyProteinLimit: 50,
      ckdStage: 3,
      lastUpdated: DateTime.now(),
    );
    
    final nutrients = ExtractedNutrients(
      nutrientRecordId: 'test',
      assessmentId: 'test',
      sodiumValue: 2500, // Exceeds limit
      potassiumValue: 1000,
      phosphorusValue: 500,
      proteinValue: 30,
      source: NutrientSource.gemini,
    );
    
    final result = engine.evaluateRisk(
      nutrients: nutrients,
      profile: profile,
    );
    
    expect(result.riskLevel, RiskLevel.highRisk);
    expect(result.exceededNutrients, contains('sodium'));
  });
}
```

### Run Tests
```bash
flutter test test/features/food_assessment/domain/risk_assessment_engine_test.dart
```

## Architecture Overview

```
User Action → Presentation Layer (UI)
    ↓
State Management (Riverpod)
    ↓
Domain Layer (Business Logic)
    ↓
Data Layer (Repositories)
    ↓
External Services (Firebase, APIs)
```

## Key Files Reference

| Component | File Path |
|-----------|-----------|
| Risk Assessment Engine | `lib/features/food_assessment/domain/usecases/risk_assessment_engine.dart` |
| Auth Repository | `lib/features/authentication/data/repositories/auth_repository_impl.dart` |
| Dietary Profile Repo | `lib/features/dietary_profile/data/repositories/dietary_profile_repository_impl.dart` |
| KDIGO Constants | `lib/core/constants/kdigo_limits.dart` |
| Error Handling | `lib/core/errors/exceptions.dart` |
| Logger | `lib/core/utils/logger.dart` |
| Validators | `lib/core/utils/validators.dart` |

## Resources

- **Implementation Status**: See `IMPLEMENTATION_STATUS.md`
- **Firebase Setup**: See `FIREBASE_SETUP.md`
- **Task List**: See `.kiro/specs/kidnease-ckd-tracking-app/tasks.md`
- **Requirements**: See `.kiro/specs/kidnease-ckd-tracking-app/requirements.md`
- **Design**: See `.kiro/specs/kidnease-ckd-tracking-app/design.md`

## Getting Help

1. Check `IMPLEMENTATION_STATUS.md` for what's complete
2. Review `FIREBASE_SETUP.md` for Firebase issues
3. Check Flutter documentation: https://docs.flutter.dev/
4. Review Riverpod docs: https://riverpod.dev/

## Success Criteria

Your MVP is ready when you can:
1. ✅ Register and login
2. ✅ Set dietary profile with KDIGO validation
3. ✅ Capture food image
4. ✅ Get risk assessment from Gemini
5. ✅ See risk notification with explanation
6. ✅ View assessment history

Good luck! 🚀
