# Fix Gemini API 404 Error - Get New API Key

## Problem Identified

Your current API key `AIzaSyAoQbuWmbaTm9Cw0mDpP5f_nFwTqi_z7ag` is returning:
- **403 Forbidden** when trying to list models
- **404 Not Found** for all model endpoints

This means the API key needs to be regenerated or the Gemini API needs to be enabled.

---

## Solution: Get a NEW Gemini API Key

### Step 1: Go to Google AI Studio

Open this link: **https://aistudio.google.com/app/apikey**

(Or go to https://makersuite.google.com/app/apikey - same thing)

### Step 2: Sign in with your Google Account

Use the same account you used before (branber23@gmail.com or your personal account)

### Step 3: Create API Key

1. Click **"Create API Key"** button
2. Select **"Create API key in new project"** (or use existing project)
3. **COPY** the new API key (it will look like: `AIzaSy...`)

### Step 4: Enable Gemini API (if needed)

If you see a message about enabling the API:
1. Click **"Enable Gemini API"**
2. Wait for it to be enabled (takes 1-2 minutes)
3. Then create the API key

### Step 5: Update Your .env File

1. Open: `kidnease_app\.env`
2. Replace the old API key with the NEW one:

```
GEMINI_API_KEY=YOUR_NEW_API_KEY_HERE
```

3. **Save the file**

### Step 6: Test the New API Key

Run this command to test:

```powershell
cd C:\Users\USER\OneDrive\Desktop\kidnease
.\test_new_gemini_key.ps1
```

(I'll create this test script for you)

### Step 7: Rebuild and Run the App

```cmd
cd kidnease_app
flutter clean
flutter run --release
```

---

## Alternative: Use Gemini 2.0 Flash (Newest Model)

If the old API structure doesn't work, try the newest model:

The endpoint should be:
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent
```

---

## Why This Happened

Possible reasons:
1. ✗ API key was created before Gemini 1.5 was available
2. ✗ API key restrictions blocking the requests  
3. ✗ Gemini API not enabled in your Google Cloud project
4. ✗ API key quota or billing issue

**Getting a fresh API key will fix all of these!**

---

## Quick Test (After Getting New Key)

Open PowerShell and run:

```powershell
$apiKey = "YOUR_NEW_API_KEY_HERE"
$url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey"

$body = @{
    contents = @(
        @{
            parts = @(
                @{ text = "Say hello if you work" }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
```

If this works, you'll see a response with "hello"!

---

## Need Help?

1. Go to: https://aistudio.google.com/app/apikey
2. Create new API key
3. Update `.env` file
4. Rebuild app

That's it! Let me know once you have the new key and I'll help you test it.
