# Firebase Setup Instructions

## Prerequisites
- Firebase account (https://console.firebase.google.com)
- Flutter SDK installed
- Android Studio or VS Code

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Enter project name: "Kidnease"
4. Follow the setup wizard

## Step 2: Add Android App

1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.kidnease.app`
3. Download `google-services.json`
4. Place it in `android/app/` directory

## Step 3: Enable Firebase Services

### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password" provider

### Cloud Firestore
1. Go to Firestore Database
2. Click "Create database"
3. Start in **production mode**
4. Choose a location close to your users

### Cloud Storage
1. Go to Storage
2. Click "Get started"
3. Start in **production mode**

### Crashlytics (Optional)
1. Go to Crashlytics
2. Follow setup instructions

## Step 4: Configure Security Rules

### Firestore Security Rules
Go to Firestore → Rules and paste:

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

### Cloud Storage Security Rules
Go to Storage → Rules and paste:

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

## Step 5: Create Firestore Indexes

Go to Firestore → Indexes and create:

1. **Collection**: `dietaryAssessments`
   - Fields: `userId` (Ascending), `timestamp` (Descending)
   
2. **Collection**: `dietaryAssessments`
   - Fields: `userId` (Ascending), `riskLevel` (Ascending), `timestamp` (Descending)

## Step 6: Configure Cloud Storage Lifecycle

Using Firebase Console or gsutil CLI:

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

## Step 7: Get API Keys

### Gemini API
1. Go to https://makersuite.google.com/app/apikey
2. Create API key
3. Copy to `.env` file as `GEMINI_API_KEY`

### FatSecret API
1. Go to https://platform.fatsecret.com/api/
2. Register for API access
3. Get Consumer Key and Consumer Secret
4. Copy to `.env` file as `FATSECRET_KEY` and `FATSECRET_SECRET`

## Step 8: Update .env File

Edit `.env` file in project root:

```
GEMINI_API_KEY=your_actual_gemini_api_key
FATSECRET_KEY=your_actual_fatsecret_consumer_key
FATSECRET_SECRET=your_actual_fatsecret_consumer_secret
```

## Step 9: Run the App

```bash
flutter pub get
flutter run
```

## Troubleshooting

### "google-services.json not found"
- Ensure the file is in `android/app/` directory
- Rebuild the project

### "Firebase not initialized"
- Check that `Firebase.initializeApp()` is called in `main.dart`
- Verify `google-services.json` is correctly placed

### "Permission denied" errors
- Verify security rules are correctly configured
- Check that user is authenticated before accessing Firestore/Storage

## Cost Estimation

For 1000 active users with 5 assessments/day:
- **Firestore**: ~$5/month (150k reads, 150k writes)
- **Cloud Storage**: ~$0/month (ephemeral storage)
- **Gemini API**: ~$37.50/month (150k image analyses)
- **FatSecret API**: $0/month (within free tier)
- **Total**: ~$42.50/month

## Production Checklist

- [ ] Enable Firebase App Check for security
- [ ] Set up Firebase Performance Monitoring
- [ ] Configure Firebase Crashlytics
- [ ] Review and test security rules
- [ ] Set up billing alerts
- [ ] Enable backup for Firestore
- [ ] Configure proper CORS for Cloud Storage
- [ ] Test with production API keys
