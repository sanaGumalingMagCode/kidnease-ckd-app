# Register Web App in Firebase Console

To run the app on web (Chrome), you need to register a web app in Firebase Console.

## Steps:

1. **Go to Firebase Console**: https://console.firebase.google.com/project/kidnease-bdbf3/overview

2. **Add Web App**:
   - Click the **Web icon** (`</>`) to add a web app
   - App nickname: `Kidnease Web`
   - **DO NOT** check "Also set up Firebase Hosting"
   - Click **Register app**

3. **Copy the Web App ID**:
   - After registration, you'll see a config object like:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSyC3kvJ1fA6NYm39ujmiI-O12ZAbVeFFwB0",
     authDomain: "kidnease-bdbf3.firebaseapp.com",
     projectId: "kidnease-bdbf3",
     storageBucket: "kidnease-bdbf3.firebasestorage.app",
     messagingSenderId: "25855431000",
     appId: "1:25855431000:web:XXXXXXXXXX"  // <-- Copy this appId
   };
   ```
   - Copy the **appId** value (it will look like `1:25855431000:web:XXXXXXXXXX`)

4. **Update firebase_options.dart**:
   - Open `lib/firebase_options.dart`
   - Find the `web` configuration
   - Replace `'1:25855431000:web:PLACEHOLDER'` with your actual web app ID

5. **Run the app**:
   ```bash
   flutter run -d chrome
   ```

## Alternative: Use FlutterFire CLI (Automatic)

Instead of manual steps above, you can run:

```bash
flutterfire configure
```

This will:
- Automatically register the web app
- Generate the correct firebase_options.dart with all platforms
- Select your project: `kidnease-bdbf3`
- Select platforms: Android, Web (use spacebar to select, enter to confirm)
