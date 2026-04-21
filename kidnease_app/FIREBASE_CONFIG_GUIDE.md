# 🔥 Firebase Configuration Guide

## Quick Fix for "FirebaseOptions cannot be null" Error

The app needs Firebase configuration to run. Follow these steps:

## Option 1: Use FlutterFire CLI (Easiest)

### Step 1: Run the configuration command

```bash
cd kidnease_app
flutterfire configure
```

### Step 2: Select or create a Firebase project
- Choose an existing project from the list, OR
- Select `<create a new project>` to create a new one

### Step 3: Select platforms
- Select **Android** (press Space to select, Enter to confirm)
- You can also select iOS if needed

### Step 4: Done!
The CLI will automatically:
- Create `lib/firebase_options.dart` with your project's configuration
- Update your Android configuration files

## Option 2: Manual Configuration (If CLI doesn't work)

### Step 1: Get Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click the gear icon ⚙️ → Project settings
4. Scroll down to "Your apps"
5. Click on your Android app (or add one if it doesn't exist)

### Step 2: Get the Configuration Values

You'll need these values from Firebase Console:

- **API Key**: Found in Project Settings → General → Web API Key
- **App ID**: Found in your Android app settings (format: `1:123456789:android:abc123...`)
- **Messaging Sender ID**: Found in Project Settings → Cloud Messaging
- **Project ID**: Your Firebase project ID (e.g., `kidnease-app-12345`)
- **Storage Bucket**: Usually `your-project-id.appspot.com`

### Step 3: Update firebase_options.dart

Open `lib/firebase_options.dart` and replace the placeholder values:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',  // Your actual API key
  appId: '1:123456789:android:abc123def456',          // Your actual App ID
  messagingSenderId: '123456789',                      // Your actual Sender ID
  projectId: 'kidnease-app-12345',                     // Your actual Project ID
  storageBucket: 'kidnease-app-12345.appspot.com',    // Your actual Storage Bucket
);
```

### Step 4: Download google-services.json

1. In Firebase Console, go to Project Settings
2. Scroll to "Your apps" → Android app
3. Click "Download google-services.json"
4. Place the file in `kidnease_app/android/app/`

## Option 3: Create a New Firebase Project

If you don't have a Firebase project yet:

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `kidnease-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

### Step 2: Add Android App

1. In your Firebase project, click "Add app" → Android
2. Enter package name: `com.kidnease.app`
3. Enter app nickname: `Kidnease` (optional)
4. Click "Register app"
5. Download `google-services.json`
6. Place it in `kidnease_app/android/app/`

### Step 3: Enable Firebase Services

In Firebase Console, enable these services:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable "Email/Password"

2. **Firestore Database**
   - Go to Firestore Database
   - Click "Create database"
   - Start in production mode
   - Choose a location

3. **Storage**
   - Go to Storage
   - Click "Get started"
   - Start in production mode

### Step 4: Run FlutterFire Configure

```bash
cd kidnease_app
flutterfire configure
```

Select your newly created project and it will auto-configure everything!

## Verify Configuration

After configuration, your project should have:

✅ `lib/firebase_options.dart` - Firebase configuration file
✅ `android/app/google-services.json` - Android Firebase config
✅ Firebase services enabled (Auth, Firestore, Storage)

## Test the App

```bash
flutter run
```

The app should now start without the "FirebaseOptions cannot be null" error!

## Troubleshooting

### Error: "No Firebase project found"
**Solution**: Create a new Firebase project first at https://console.firebase.google.com/

### Error: "google-services.json not found"
**Solution**: Download it from Firebase Console and place in `android/app/`

### Error: "FlutterFire CLI not found"
**Solution**: Install it with `dart pub global activate flutterfire_cli`

### Error: "Invalid API key"
**Solution**: Double-check the values in `firebase_options.dart` match your Firebase Console

## Need Help?

1. Check Firebase Console for correct configuration values
2. Ensure `google-services.json` is in the correct location
3. Run `flutter clean` and `flutter pub get`
4. Restart your IDE/editor

---

**Quick Command Reference:**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```
