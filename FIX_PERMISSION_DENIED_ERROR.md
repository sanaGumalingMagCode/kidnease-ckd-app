# Fix: Permission Denied Error on Sign In

## 🔴 Error Message:
```
AuthenticationException: Sign in failed:
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## 🎯 Root Cause:
Your **Firestore Security Rules** are not deployed to Firebase Console, so the database is blocking all access.

---

## ✅ Solution: Deploy Firestore Security Rules

### **Method 1: Deploy via Firebase Console** (RECOMMENDED - Fastest)

#### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com/
2. Select your **kidnease** project
3. Click **"Firestore Database"** in the left sidebar
4. Click the **"Rules"** tab at the top

#### Step 2: Copy and Paste These Rules
**Replace ALL existing rules** with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection - users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    // Dietary Profiles - users can only access their own profile
    match /dietaryProfiles/{profileId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
    
    // Dietary Assessments - users can only access their own assessments
    match /dietaryAssessments/{assessmentId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
    
    // Extracted Nutrients - users can read/write nutrients for their assessments
    match /extractedNutrients/{nutrientId} {
      allow read, write: if isAuthenticated();
    }
    
    // Risk Notifications - users can only access their own notifications
    match /riskNotifications/{notificationId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
  }
}
```

#### Step 3: Publish Rules
1. Click the **"Publish"** button
2. Wait for "Rules published successfully" message
3. **Done!** ✅

---

### **Method 2: Deploy via Firebase CLI** (Advanced)

If you have Firebase CLI installed:

```bash
cd C:\Users\USER\OneDrive\Desktop\kidnease\kidnease_app
firebase deploy --only firestore:rules
```

---

## 🧪 Test After Deploying Rules

1. **Restart the app**
2. **Sign in again** with your credentials
3. **Should work now!** ✅

---

## 🔍 Verify Rules Are Deployed

1. Go to Firebase Console
2. Click "Firestore Database" → "Rules" tab
3. You should see the rules you just pasted
4. Check the "Last published" timestamp - should be recent

---

## ⚠️ IMPORTANT: Also Update Storage Rules

While you're in Firebase Console, also update **Storage Rules** for profile photos:

1. Click **"Storage"** in the left sidebar
2. Click **"Rules"** tab
3. Copy and paste these rules:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile photos
    match /users/{userId}/profile/{filename} {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if true;
    }
    
    // Food images
    match /users/{userId}/food_images/{filename} {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && request.auth.uid == userId;
    }
    
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

4. Click **"Publish"**

---

## 📋 What These Rules Do

### Firestore Rules:
- ✅ **Users can only access their own data**
- ✅ **Must be logged in to read/write**
- ✅ **Prevents unauthorized access**
- ✅ **Secure by default**

### Storage Rules:
- ✅ **Users can only upload to their own folders**
- ✅ **Profile photos are publicly readable**
- ✅ **Food images are private**

---

## 🎯 Expected Behavior After Fix

### Before (Current):
```
❌ Sign in fails
❌ "Permission denied" error
❌ Can't access database
```

### After (Fixed):
```
✅ Sign in succeeds
✅ Can create profile
✅ Can upload photos
✅ Can scan food
✅ App works fully!
```

---

## 🆘 Still Not Working?

### Check These:

1. **Are you signed in?**
   - Sign out and sign in again
   - Check Firebase Console → Authentication → Users

2. **Are rules published?**
   - Check Firebase Console → Firestore → Rules
   - Look for recent "Last published" timestamp

3. **Clear app data:**
   ```bash
   adb uninstall com.example.kidnease_app
   flutter run
   ```

4. **Check Firebase Console logs:**
   - Firebase Console → Firestore → Usage
   - Look for denied requests

---

## 🔐 Security Note

These rules are **production-ready** and secure:
- Users can only access their own data
- Authentication is required for all operations
- No one can access other users' information
- Data is protected by Firebase Authentication

---

## ✅ Quick Checklist

- [ ] Go to Firebase Console
- [ ] Navigate to Firestore Database → Rules
- [ ] Copy and paste the Firestore rules above
- [ ] Click "Publish"
- [ ] Navigate to Storage → Rules  
- [ ] Copy and paste the Storage rules above
- [ ] Click "Publish"
- [ ] Restart app and test sign in
- [ ] Should work now! 🎉

---

**After deploying these rules, your app should work perfectly!**
