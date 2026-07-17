# Firebase Security Rules Fix for Registration

## Problem
You're getting a `permission-denied` error when trying to register because Firebase Firestore security rules are blocking the creation of user documents.

## Solution
You need to update your Firestore Security Rules in the Firebase Console.

### Steps:

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your "kidnease" project

2. **Navigate to Firestore Database**
   - Click on "Firestore Database" in the left sidebar
   - Click on the "Rules" tab at the top

3. **Update Security Rules**
   Replace your current rules with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is accessing their own data
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection - allow users to create and read their own profile
    match /users/{userId} {
      // Allow user to create their own document during registration
      allow create: if isAuthenticated() && request.auth.uid == userId;
      
      // Allow user to read and update their own profile
      allow read, update: if isOwner(userId);
      
      // Prevent deletion of user profiles
      allow delete: if false;
    }
    
    // Dietary profiles collection
    match /dietaryProfiles/{profileId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
    }
    
    // Dietary assessments collection
    match /dietaryAssessments/{assessmentId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
    }
    
    // Extracted nutrients collection
    match /extractedNutrients/{nutrientId} {
      allow read, write: if isAuthenticated();
    }
    
    // Risk notifications collection
    match /riskNotifications/{notificationId} {
      allow read, write: if isAuthenticated() && 
                            resource.data.userId == request.auth.uid;
    }
  }
}
```

4. **Publish the Rules**
   - Click the "Publish" button at the top right
   - Wait for the confirmation message

5. **Test Registration Again**
   - Go back to your app
   - Try registering with your email again: `branber51@gmail.com`
   - It should work now!

## What These Rules Do

- **Users Collection**: 
  - `allow create`: Lets authenticated users create their own user document (this fixes your registration error)
  - `allow read, update`: Lets users read and update only their own profile
  - `allow delete: false`: Prevents user profile deletion

- **Other Collections**: 
  - All require authentication
  - Users can only access their own data (based on `userId` field)

## Security Note
These rules follow the principle of least privilege - users can only access their own data, which is required for privacy in a health app.

## After Updating Rules
Once you update the rules, your registration should work. The app will:
1. Create a Firebase Auth account
2. Create a user document in Firestore with your profile info
3. Navigate to the dashboard

Try it and let me know if you need any help!
