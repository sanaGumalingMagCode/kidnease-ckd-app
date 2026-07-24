# 🔑 API Keys Setup Guide

## Current Status

### ✅ Already Working:
- **FatSecret:** Already configured
- **Open Food Facts:** No key needed (open source)
- **Local Database:** No key needed

### ⚠️ Needs Setup:
- **USDA:** Currently using `DEMO_KEY` (limited)

---

## 🚀 Get USDA API Key (2 Minutes)

### Why You Need This:
- DEMO_KEY has lower rate limits
- Your own key = unlimited searches
- 100% free, no credit card
- Takes 30 seconds to get

### Steps:

#### 1. Visit USDA Signup Page
**URL:** https://fdc.nal.usda.gov/api-key-signup.html

#### 2. Fill the Form
- **Name:** Your name
- **Email:** Your email
- **Organization:** Personal/Student project (or your company)
- **Purpose:** Nutritional tracking for CKD patients
- **Agree to terms**
- Click "Submit"

#### 3. Check Your Email
- You'll receive the API key instantly
- Copy the key (looks like: `XXXXXXXXXX`)

#### 4. Update the Code
Open file:
```
kidnease_app/lib/features/food_search/data/datasources/usda_api_client.dart
```

Find line 10:
```dart
static const String _apiKey = 'DEMO_KEY';
```

Replace with your key:
```dart
static const String _apiKey = 'YOUR_KEY_HERE';
```

#### 5. Restart App
```bash
# Stop the app (Ctrl+C in terminal)
flutter run
```

#### 6. Test
Search for "broccoli" - should see [USDA] badge with blue color ✅

---

## 📊 API Key Summary

| API | Key Needed? | Where to Get | Cost | Time |
|-----|-------------|--------------|------|------|
| **Local Database** | ❌ No | Built-in | Free | - |
| **USDA** | ⚠️ Recommended | [Get Here](https://fdc.nal.usda.gov/api-key-signup.html) | Free | 30 sec |
| **Open Food Facts** | ❌ No | Open source | Free | - |
| **FatSecret** | ✅ Already set | Already configured | Free | - |

---

## 🧪 Testing Without USDA Key

The app works fine with `DEMO_KEY` for testing:
- Limited to ~1000 requests/hour
- Perfect for development
- Fine for personal use

But for production, get your own key!

---

## 🔍 Verify APIs Are Working

### Test Each API:

#### 1. Test Local Database (Green badge):
```
Search: "chickenjoy"
Expected: Jollibee Chickenjoy [Local Database] 🏠
```

#### 2. Test USDA (Blue badge):
```
Search: "broccoli"
Expected: Broccoli [USDA FoodData Central] ✅
```

#### 3. Test Open Food Facts (Orange badge):
```
Search: "lucky me"
Expected: Lucky Me product [Open Food Facts] 🌍
```

#### 4. Test FatSecret (Purple badge):
```
Search: "specific brand not in other DBs"
Expected: Product [FatSecret] ☁️
```

---

## ⚠️ Troubleshooting

### USDA Not Working?
**Symptoms:** No USDA results, only local/FatSecret
**Fix:**
1. Check API key is correct (no spaces)
2. Check internet connection
3. Try after a few minutes (rate limit)
4. Check terminal logs for errors

### Open Food Facts Not Working?
**Symptoms:** No Philippine products found
**Fix:**
1. Check internet connection
2. Try more specific search (e.g., "lucky me pancit canton")
3. Some products may not have complete CKD nutrients

### All APIs Failing?
**Symptoms:** Only local database works
**Fix:**
1. Check internet connection
2. Check if you're behind a firewall/proxy
3. Restart app
4. Check terminal logs

---

## 📝 Quick Reference

### File Locations:
```
USDA API Key:
kidnease_app/lib/features/food_search/data/datasources/usda_api_client.dart
Line 10

FatSecret API Key:
Already configured in your .env file ✅

Open Food Facts:
No key needed ✅
```

### Terminal Logs to Watch:
```
[INFO] Searching Local fallback
[INFO] Searching USDA API
[INFO] Searching Open Food Facts API
[INFO] Searching FatSecret API
[INFO] Found food in [SOURCE]
```

---

## ✅ Checklist

After setup, verify:

- [ ] USDA API key replaced (if needed)
- [ ] App restarted
- [ ] Searched "broccoli" → Shows USDA badge
- [ ] Searched "chickenjoy" → Shows Local badge
- [ ] Searched "lucky me" → Shows Open Food Facts badge
- [ ] All searches return CKD nutrients (Na, K, P)
- [ ] Portion dropdown works
- [ ] No errors in terminal

---

## 💡 Pro Tips

### 1. Keep DEMO_KEY for Development
If just testing, DEMO_KEY works fine!

### 2. Get Key Before Production
Get your own USDA key before releasing to users

### 3. Monitor Terminal
Watch logs to see which API returns data

### 4. Test All Sources
Make sure all 4 APIs work before releasing

---

## 🆘 Need Help?

### Check These:
1. Terminal logs (errors appear here)
2. API key has no spaces
3. Internet connection working
4. App restarted after changing key

### Common Issues:
- **"Rate limit exceeded"** → Get your own USDA key
- **"No results found"** → Try different search term
- **"Network error"** → Check internet connection

---

**Total Setup Time: 2 minutes** ⏱️

**Result: 2.4M+ foods searchable!** 🎉
