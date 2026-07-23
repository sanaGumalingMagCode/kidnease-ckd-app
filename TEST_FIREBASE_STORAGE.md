# 🔍 Firebase Storage Diagnostic Test

## Problem: Rules deployed but still getting errors

Let me help you diagnose what's happening.

---

## 🎯 STEP 1: Verify Rules Are Actually Deployed

### Check Storage Rules:
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/storage/rules
2. Look at the **"Last published"** timestamp
3. Should say: "a few minutes ago" or today's date/time

### What You Should See:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/profile/{filename} {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if true;
    }
    // ... rest of rules
  }
}
```

### ❌ If you see something different:
- The rules weren't saved properly
- Try deploying again

---

## 🎯 STEP 2: Verify You're Signed In

The error "StorageException: Upload failed" usually means:
1. You're not signed in (unauthenticated)
2. Or Firebase Auth is not connected properly

### Test:
1. In your app, go to the Settings/Profile section
2. Check if your email is displayed
3. Try signing out and signing in again
4. Then test the photo upload

---

## 🎯 STEP 3: Check Firebase Project Configuration

### Verify in Firebase Console:

#### A. Check Authentication:
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/authentication/users
2. Do you see your user account listed?
3. Copy your **User UID** (you'll need this)

#### B. Check Storage:
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/storage
2. Is there a "Files" section?
3. Click "Files" - do you see any folder structure?

#### C. Check if Storage is Enabled:
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/storage
2. If you see "Get Started" button, **Storage is not initialized!**
3. Click "Get Started" to initialize Storage
4. Choose your location (closest to Philippines: `asia-southeast1`)
5. Accept the default rules for now (we'll change them)

---

## 🎯 STEP 4: Run Diagnostic App

I've updated the app to show better error messages. Let's run it and see the exact error:

### Command:
```bash
cd c:\Users\USER\OneDrive\Desktop\kidnease\kidnease_app
flutter run
```

### What to Look For:

In the terminal, you'll see logs like:
```
[INFO] Firebase initialized successfully
[INFO] Firebase Storage bucket: kidnease-bdbf3.firebasestorage.app
[INFO] User authenticated: your@email.com
[INFO] Uploading profile photo to Firebase Storage
```

### When Upload Fails, Look For:
```
[ERROR] Firebase Storage error uploading profile photo
[ERROR] code: unauthorized (or unauthenticated, or quota-exceeded, etc.)
[ERROR] message: {detailed error message}
```

**Take a screenshot of the error logs and share them with me!**

---

## 🎯 STEP 5: Common Issues and Fixes

### Issue 1: "unauthenticated" or "unauthorized"
**Means:** Firebase can't verify you're signed in

**Fix:**
1. Make sure you're signed in to the app
2. Check Firebase Console → Authentication → Users (your user should be listed)
3. Try signing out and back in
4. Redeploy BOTH Firestore AND Storage rules

---

### Issue 2: "bucket-not-found"
**Means:** Firebase Storage is not initialized

**Fix:**
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/storage
2. Click "Get Started"
3. Initialize Storage
4. Then deploy the Storage rules

---

### Issue 3: "quota-exceeded"
**Means:** You've hit the free tier limits

**Fix:**
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/usage
2. Check Storage usage
3. Either wait until next month or upgrade to paid plan

---

### Issue 4: "unknown" or "unavailable"
**Means:** Network or configuration issue

**Fix:**
1. Check your internet connection
2. Try again in a few minutes
3. Restart the app

---

## 🎯 STEP 6: Verify Both Rules Are Deployed

You need to deploy TWO sets of rules:

### 1. Firestore Rules (for database):
URL: https://console.firebase.google.com/project/kidnease-bdbf3/firestore/rules

Should include:
```javascript
match /dietaryProfiles/{profileId} {
  allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
  allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
  allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
}
```

### 2. Storage Rules (for file uploads):
URL: https://console.firebase.google.com/project/kidnease-bdbf3/storage/rules

Should include:
```javascript
match /users/{userId}/profile/{filename} {
  allow write: if request.auth != null && request.auth.uid == userId;
  allow read: if true;
}
```

**Check BOTH have recent "Last published" timestamps!**

---

## 🎯 STEP 7: Test with This Sequence

1. **Stop the app completely** (close emulator or kill app on phone)
2. **Restart the app:**
   ```bash
   flutter run
   ```
3. **Sign in** with your email and password
4. **Wait 5 seconds** (let Firebase initialize)
5. **Go to profile** → Edit Profile
6. **Try to upload a photo**
7. **Read the error message carefully** - take a screenshot!

---

## 🎯 STEP 8: Check the New Error Messages

I've updated the app to show more detailed errors. You should now see something like:

### Good (Success):
```
✅ Profile photo uploaded successfully!
✅ Dietary profile saved successfully!
```

### Bad (Permission Error):
```
❌ Photo upload failed: Permission denied. Firebase Storage rules may not be deployed correctly. Error: {detailed message}
```

### Bad (Not Signed In):
```
❌ Photo upload failed: Upload failed (unauthenticated): User must be authenticated
```

### Bad (Storage Not Initialized):
```
❌ Photo upload failed: Storage bucket not found. Check Firebase configuration.
```

---

## 🆘 WHAT TO SHARE WITH ME

If it's still not working, share these:

1. **Screenshot of Firebase Storage Rules page** showing:
   - The actual rules text
   - The "Last published" timestamp

2. **Screenshot of Firebase Authentication Users page** showing:
   - Your user account listed

3. **Screenshot of the app error message** showing:
   - The orange error notification at the bottom

4. **Terminal logs** when you run `flutter run`:
   - Copy the lines with [ERROR] or [INFO]
   - Especially the lines about "Firebase Storage error"

5. **Answer these questions:**
   - Did you click "Publish" after pasting the rules?
   - Do you see your user in Authentication → Users?
   - Is Firebase Storage initialized (do you see Files tab)?
   - What's the exact error message shown in the app?

---

## 💡 MOST LIKELY CAUSES

### 1. Storage Not Initialized (60% chance)
- Solution: Click "Get Started" in Storage

### 2. Rules Not Actually Published (20% chance)
- Solution: Paste rules again and click "Publish", wait for success message

### 3. Not Signed In Properly (10% chance)
- Solution: Sign out and sign in again

### 4. Firestore Rules Blocking (5% chance)
- Solution: Deploy Firestore rules too (not just Storage)

### 5. Wrong Firebase Project (5% chance)
- Solution: Check `google-services.json` matches Firebase Console project

---

## ✅ QUICK CHECKLIST

Before contacting me, verify:

- [ ] Firebase Storage is initialized (Files tab exists)
- [ ] Storage rules are deployed (check "Last published")
- [ ] Firestore rules are deployed (check "Last published")
- [ ] You can sign in to the app
- [ ] Your user appears in Authentication → Users
- [ ] App is restarted after deploying rules
- [ ] Error message is shown in app (screenshot it)

---

**Run the diagnostic steps above and share the results!** 🔍
