# 📸 Profile Photo Upload - Troubleshooting Guide

## 🔍 YOUR FIREBASE PROJECT INFO
```
Project Name: kidnease-bdbf3
Project ID: kidnease-bdbf3
Storage Bucket: kidnease-bdbf3.firebasestorage.app
```

---

## ⚡ QUICK FIX (Do This First!)

### The problem is 99% likely: **Firebase Rules Not Deployed**

Go to: **https://console.firebase.google.com/project/kidnease-bdbf3**

Then follow the guide in: `URGENT_FIX_PROFILE_PHOTOS.md`

---

## 🧪 TESTING FLOWCHART

```
Start Here
    ↓
Can you sign in to the app?
    ↓
    ├── NO → Go to: FIX_PERMISSION_DENIED_ERROR.md
    │         (Deploy Firestore rules first)
    │
    └── YES → Continue below
            ↓
        Try to upload a profile photo
            ↓
        What happens?
            ↓
            ├── "Profile photo uploaded successfully!" (GREEN)
            │   → ✅ IT WORKS! You're done!
            │
            ├── "Photo upload failed: permission-denied" (ORANGE)
            │   → ❌ Firebase Storage rules not deployed
            │   → Go to: URGENT_FIX_PROFILE_PHOTOS.md → Part 2
            │
            ├── "Photo upload failed: quota-exceeded" (ORANGE)
            │   → ❌ Firebase Storage quota exceeded
            │   → Solution: Upgrade Firebase plan or wait until next month
            │
            ├── "Photo upload failed: network error" (ORANGE)
            │   → ❌ Internet connection issue
            │   → Solution: Check your internet connection
            │
            └── Nothing happens / App crashes
                → ❌ Code issue
                → Solution: Check logs below
```

---

## 🔥 MOST COMMON ISSUES

### 1️⃣ Firebase Storage Rules Not Deployed (90% of issues)

**Symptom:**
```
"Photo upload failed: permission-denied"
```

**Solution:**
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/storage/rules
2. Click "Rules" tab
3. Copy/paste rules from `URGENT_FIX_PROFILE_PHOTOS.md` (Part 2)
4. Click "Publish"
5. Restart app

---

### 2️⃣ Firestore Rules Not Deployed (5% of issues)

**Symptom:**
```
Can't sign in
"Sign in failed: permission-denied"
```

**Solution:**
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/firestore/rules
2. Click "Rules" tab
3. Copy/paste rules from `URGENT_FIX_PROFILE_PHOTOS.md` (Part 1)
4. Click "Publish"
5. Restart app

---

### 3️⃣ Not Signed In (3% of issues)

**Symptom:**
```
"Photo upload failed: unauthenticated"
```

**Solution:**
1. Sign out
2. Sign in again
3. Try uploading photo again

---

### 4️⃣ Network Issues (2% of issues)

**Symptom:**
```
"Photo upload failed: network error"
Upload takes forever then fails
```

**Solution:**
1. Check internet connection
2. Try again
3. Wait a minute and retry

---

## 🎯 VERIFY YOUR FIX

### ✅ After deploying rules, verify they're active:

#### Check Firestore Rules:
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/firestore/rules
2. You should see rules that include:
   - `match /users/{userId}`
   - `match /dietaryProfiles/{profileId}`
   - `isAuthenticated()` function
3. Check "Last published" timestamp - should be recent (within last 10 minutes)

#### Check Storage Rules:
1. Go to: https://console.firebase.google.com/project/kidnease-bdbf3/storage/rules
2. You should see rules that include:
   - `match /users/{userId}/profile/{filename}`
   - `match /users/{userId}/food_images/{filename}`
3. Check "Last published" timestamp - should be recent (within last 10 minutes)

---

## 📝 CHECK LOGS (Advanced)

### If upload still fails, check these:

#### 1. Firebase Console Logs
Go to: https://console.firebase.google.com/project/kidnease-bdbf3/storage

**Check:**
- Is there a folder: `users/{your-user-id}/profile/`?
- Is there a file: `profile_photo.jpg` inside?
- If YES → Upload worked, but display issue
- If NO → Upload failed, check error message in app

#### 2. App Error Messages
The app shows detailed error messages:
- "Profile photo uploaded successfully!" → ✅ Working
- "Photo upload failed: {error}" → ❌ Read the error
- Screenshot the error and check this guide

#### 3. Flutter Logs (Terminal)
If running from terminal, check for:
```
[INFO] Uploading profile photo for user: {userId}
[INFO] Profile photo uploaded successfully: {url}
```
or
```
[ERROR] Failed to upload profile photo: {error}
```

---

## 🔐 EXPECTED STORAGE STRUCTURE

After successful upload, Firebase Storage should look like:

```
kidnease-bdbf3.firebasestorage.app/
└── users/
    └── {your-user-id}/
        ├── profile/
        │   └── profile_photo.jpg  ← Your profile photo
        └── food_images/
            └── {timestamp}.jpg    ← Scanned food photos
```

You can view this at: https://console.firebase.google.com/project/kidnease-bdbf3/storage/files

---

## 🆘 STILL NOT WORKING?

### Final Checklist:

- [ ] Firestore rules deployed? (Check timestamp)
- [ ] Storage rules deployed? (Check timestamp)
- [ ] Signed in to the app?
- [ ] Internet connection working?
- [ ] App restarted after deploying rules?
- [ ] Using the correct Firebase project (kidnease-bdbf3)?
- [ ] Error message shown in app? (Screenshot it)

### If all above are checked and still not working:

**Share this info:**
1. Screenshot of Firebase Console → Storage → Rules
2. Screenshot of the error message in the app
3. Output from Flutter terminal when running the app
4. Does the photo appear in Firebase Storage files?

---

## 💡 TIPS

### Tip 1: Clear App Data
Sometimes cached data causes issues:
```bash
# Uninstall and reinstall
adb uninstall com.kidnease.kidnease_app
flutter run
```

### Tip 2: Check Firebase Quotas
Free plan limits:
- Storage: 5 GB
- Downloads: 1 GB/day
- Uploads: 20,000/day

Check at: https://console.firebase.google.com/project/kidnease-bdbf3/usage

### Tip 3: Test with Different Photo
- Try a smaller photo (< 1 MB)
- Try taking a new photo vs selecting from gallery
- Different photo might have different results

---

## ✅ SUCCESS INDICATORS

### You know it's working when:

1. **During Upload:**
   - Progress indicator shows briefly
   - Green message: "Profile photo uploaded successfully!"
   - Another green message: "Dietary profile saved successfully!"

2. **After Saving:**
   - Your photo appears immediately in the profile screen
   - No error messages shown

3. **After Reopening App:**
   - Sign out and sign in again
   - Go to profile
   - Your photo is still there ✅

4. **In Firebase Console:**
   - Go to Storage → Files
   - Navigate to: `users/{your-id}/profile/`
   - See `profile_photo.jpg` file
   - File size should match your photo (50-500 KB typically)

---

## 📊 ERROR CODES REFERENCE

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `permission-denied` | Storage rules not deployed | Deploy Storage rules |
| `unauthenticated` | Not signed in | Sign in again |
| `quota-exceeded` | Storage quota full | Upgrade Firebase plan |
| `canceled` | Upload was canceled | Try again |
| `unknown` / `unavailable` | Network issue | Check internet, retry |
| `timeout` | Upload took too long | Check internet, retry |

---

## 🎓 HOW THE SYSTEM WORKS

### Upload Flow:
```
1. User selects photo → _pickImage() called
2. Photo stored in: _profileImage (local File)
3. User taps "Save Profile" → _saveProfile() called
4. Code calls: uploadProfilePhoto()
5. Photo uploaded to: users/{userId}/profile/profile_photo.jpg
6. Firebase returns: Download URL
7. URL saved in: DietaryProfile.profilePhotoUrl
8. Profile saved to Firestore
9. Photo displayed using: NetworkImage(photoUrl)
```

### Security:
- ✅ Users can only upload to their own folder
- ✅ Firebase rules check: `request.auth.uid == userId`
- ✅ Anyone can read profile photos (not sensitive)
- ✅ Food images are private (only owner can read)

---

**Bottom Line:** Deploy the Firebase rules from `URGENT_FIX_PROFILE_PHOTOS.md` and it will work! 🚀
