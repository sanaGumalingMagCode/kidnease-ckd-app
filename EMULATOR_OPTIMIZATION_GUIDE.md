# Android Emulator Optimization Guide

## Quick Fixes (Do These First!)

### 1. Enable Hardware Acceleration (MOST IMPORTANT)

**Check if Intel HAXM or Hyper-V is enabled:**

```cmd
# Check if Hyper-V is enabled (Windows Pro/Enterprise)
systeminfo | findstr /C:"Hyper-V"

# Check if virtualization is enabled in BIOS
systeminfo | findstr /C:"Virtualization"
```

**If virtualization shows "No":**
- Restart your PC
- Enter BIOS (usually press F2, F10, Del, or F12 during boot)
- Enable "Intel VT-x" or "AMD-V" (virtualization technology)
- Save and restart

**For Windows Home (no Hyper-V):**
- Install Intel HAXM from Android Studio:
  - Tools → SDK Manager → SDK Tools tab
  - Check "Intel x86 Emulator Accelerator (HAXM installer)"
  - Click Apply

**For Windows Pro/Enterprise:**
- Enable Hyper-V:
  ```powershell
  # Run PowerShell as Administrator
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
  ```

### 2. Create a Faster Emulator Configuration

**Open Android Studio → Device Manager**

Create a new device with these settings:
- **Device**: Pixel 5 or Pixel 6 (smaller devices = faster)
- **System Image**: 
  - API Level 30 or 31 (not 34 - older = faster)
  - **x86_64** architecture (NOT ARM)
  - **Without Google Play** if you don't need it
- **Startup Size**: 
  - RAM: 2048 MB (2GB) - NOT more!
  - VM Heap: 512 MB
  - Internal Storage: 2048 MB (2GB)
- **Graphics**: Hardware - GLES 2.0

### 3. Edit Existing Emulator Settings

**In Device Manager:**
1. Click the pencil icon (Edit) on your current emulator
2. Click "Show Advanced Settings" at bottom
3. Optimize these settings:

```
Performance:
  ✓ Boot option: Cold boot (or Quick boot after first time)
  ✓ Graphics: Hardware - GLES 2.0
  ✓ Multi-Core CPU: 4 cores
  
Memory and Storage:
  RAM: 2048 MB (2GB max - more is NOT better!)
  VM Heap: 512 MB
  Internal Storage: 2048 MB (2GB)
  SD Card: None (unless needed)
  
Emulated Performance:
  ✓ Graphics: Hardware - GLES 2.0
```

### 4. Flutter Performance Optimization

**Build in Release Mode for Testing:**
```cmd
# Instead of: flutter run
# Use:
flutter run --release

# Or build APK and install:
flutter build apk --release
flutter install
```

**Disable Hot Reload Auto-Save:**
- In VS Code: Settings → Flutter → Hot Reload On Save → Disable

### 5. Close Background Apps

While running emulator, close:
- Chrome/Edge (heavy browsers)
- Other IDEs
- Video players
- Discord/Slack
- Other emulators

### 6. Windows Power Settings

```powershell
# Set to High Performance mode
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Or use Control Panel:
# Control Panel → Power Options → High performance
```

---

## Advanced Optimizations

### 7. Increase Emulator RAM (If You Have 16GB+ RAM)

Edit emulator config file:
1. Close Android Studio and emulator
2. Open: `C:\Users\USER\.android\avd\YOUR_EMULATOR_NAME.avd\config.ini`
3. Change:
   ```ini
   hw.ramSize=2048
   vm.heapSize=512
   ```

### 8. Use Emulator Command Line for Better Performance

```cmd
# Find your emulator
cd %ANDROID_HOME%\emulator
emulator -list-avds

# Run with optimizations
emulator -avd Pixel_5_API_34 -gpu host -cores 4 -memory 2048 -no-snapshot-load -no-audio -no-boot-anim
```

**Command flags explained:**
- `-gpu host`: Use your GPU (faster graphics)
- `-cores 4`: Use 4 CPU cores
- `-memory 2048`: 2GB RAM
- `-no-snapshot-load`: Fresh start (faster boot after first time)
- `-no-audio`: Disable audio (slight speedup)
- `-no-boot-anim`: Skip boot animation

### 9. Disable Windows Defender Real-Time Scanning (Temporary)

**Only during development:**
1. Windows Security → Virus & threat protection
2. Manage settings
3. Turn off Real-time protection (temporary)
4. Add exclusions for:
   - `C:\Users\USER\.android`
   - `C:\Users\USER\OneDrive\Desktop\kidnease`
   - Android SDK folder

### 10. Clean Emulator Data

```cmd
# Close emulator first, then:
cd %USERPROFILE%\.android\avd\Pixel_5_API_34.avd

# Delete these files:
del *.lock
del snapshots\*

# Or reset emulator completely:
# Device Manager → Wipe Data
```

---

## Quick Comparison: Emulator vs Physical Device

| Method | Speed | Setup | Best For |
|--------|-------|-------|----------|
| Emulator (Optimized) | Medium | Easy | Daily development |
| Physical Phone (USB Debug) | **FASTEST** | Medium | Testing, demo |
| Emulator (Default) | Slow | Easy | Basic testing |

---

## Use a Physical Phone Instead (FASTEST OPTION!)

### Enable USB Debugging on Your Phone:

1. **Enable Developer Options:**
   - Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back → Developer Options

2. **Enable USB Debugging:**
   - Developer Options → USB Debugging → Enable

3. **Connect to PC:**
   ```cmd
   # Check device is connected
   adb devices
   
   # Run app on phone
   flutter run
   ```

**Benefits:**
- ⚡ 5-10x faster than emulator
- Real camera, sensors, GPS
- Better for demo/testing
- No PC performance impact

---

## Troubleshooting

### Emulator Won't Start
```cmd
# Check if HAXM/Hyper-V is working
sc query intelhaxm

# Restart ADB
adb kill-server
adb start-server
```

### Still Slow After All Optimizations?

**Your PC specs matter:**
- Minimum: i5/Ryzen 5, 8GB RAM, SSD
- Recommended: i7/Ryzen 7, 16GB RAM, SSD
- **Use physical phone if PC is low-spec**

### Check Your System:
```cmd
# Check RAM usage
systeminfo | findstr /C:"Available Physical Memory"

# Check CPU
wmic cpu get name

# Check if on SSD
fsutil fsinfo drivetype C:
```

---

## Recommended Setup for Kidnease App

**Best Option (Fastest):**
```
Physical Android phone + USB debugging
```

**Good Option (Balance):**
```
Emulator:
- Pixel 5, API 30, x86_64
- 2GB RAM, Hardware Graphics
- Release mode: flutter run --release
```

**Emergency Option (Slow PC):**
```
Use online emulator: appetize.io
OR
Build APK and test on friend's phone
```

---

## My Recommended Steps for YOU:

1. ✅ Check if virtualization is enabled in BIOS
2. ✅ Create new Pixel 5 API 30 emulator (lighter than API 34)
3. ✅ Set RAM to exactly 2GB (not more!)
4. ✅ Set graphics to "Hardware - GLES 2.0"
5. ✅ Close Chrome and other apps
6. ✅ Run in release mode: `flutter run --release`
7. ✅ Consider using physical phone for testing

**OR use your physical phone - it's 10x faster! 📱⚡**

---

## Quick Commands Reference

```cmd
# List emulators
emulator -list-avds

# Run optimized emulator
emulator -avd Pixel_5_API_30 -gpu host -cores 4 -memory 2048 -no-audio -no-boot-anim

# Check connected devices
adb devices

# Run Flutter app in release mode
flutter run --release

# Build and install APK
flutter build apk --release
flutter install
```

---

## Expected Performance After Optimization

| Action | Before | After |
|--------|--------|-------|
| Emulator Boot | 3-5 min | 30-60 sec |
| App Launch | 30-60 sec | 5-10 sec |
| Hot Reload | 10-20 sec | 2-5 sec |
| Navigation | Laggy | Smooth |

---

Need help with any of these steps? Let me know!
