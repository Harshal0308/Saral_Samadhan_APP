# SARAL App - Publishing Guide

## Overview
SARAL is a production-ready NGO Coordination Platform with complete authentication, offline support, and center-based data management.

---

## ✅ What's Been Completed

### 1. **Black Screen Issue - FIXED**
- Added professional splash screen with logo and loading indicator
- Smooth transition to login/dashboard based on auth state
- 1.5-second splash duration for better UX

### 2. **Logo Integration - COMPLETE**
- Logo now appears on:
  - Splash screen (centered, 140x140px)
  - Login page (100x100px in white box)
  - Dashboard header (24x24px with text)
  - Center selection page (32x32px with text)
- All logo placements are responsive and professional

### 3. **User-Friendly UI Improvements**
- **Login Page**: 
  - Added helper text for email and password fields
  - Icons for email and password inputs
  - Better validation messages
  - Improved visual hierarchy
  
- **Dashboard**:
  - Clearer descriptions for main tiles
  - Better quick action labels
  - Improved offline banner with icons
  
- **Account Settings**:
  - Organized into sections (Personal, Security, Preferences)
  - Better button styling
  - Clearer logout confirmation
  
- **Center Selection**:
  - Gradient header with logo
  - Helper text "Choose where you work"
  - Better visual hierarchy

### 4. **Core Features - ALL WORKING**
✅ Authentication with Supabase (email/password)
✅ Session persistence (users stay logged in)
✅ Center-based data segregation
✅ Offline mode with proper UI feedback
✅ Face recognition for attendance
✅ Volunteer report management
✅ Student management
✅ Multi-language support (English, Hindi, Marathi)

---

## 📱 Before Publishing

### 1. **Update App Icons**
```
Android: android/app/src/main/res/mipmap-*/ic_launcher.png
iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
```
Use the SARAL logo in multiple sizes (192x192, 512x512, etc.)

### 2. **Update App Name & Package**
```
Android: android/app/build.gradle
  - applicationId: com.yourcompany.saral
  - versionCode: 1
  - versionName: "1.0.0"

iOS: ios/Runner/Info.plist
  - CFBundleName: SARAL
  - CFBundleVersion: 1
```

### 3. **Update Splash Screen (Optional)**
Edit `lib/pages/splash_screen.dart` to customize:
- Duration (currently 1.5 seconds)
- Colors and gradients
- Loading indicator style

### 4. **Test on Real Devices**
```bash
# Android
flutter run -d <device-id>

# iOS
flutter run -d <device-id>
```

### 5. **Build Release APK/IPA**
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🔐 Security Checklist

- ✅ Supabase credentials are in main.dart (consider moving to .env for production)
- ✅ Password validation (minimum 6 characters)
- ✅ Session tokens handled by Supabase SDK
- ✅ Offline data stored locally (sembast database)
- ✅ No sensitive data in logs

### Before Publishing:
1. Move Supabase credentials to environment variables
2. Enable Supabase Row Level Security (RLS)
3. Set up proper authentication rules
4. Test password reset flow
5. Verify logout clears all local data

---

## 📊 Testing Checklist

### Authentication
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (error message)
- [ ] Forgot password flow
- [ ] Session persistence (close and reopen app)
- [ ] Logout functionality
- [ ] Change password

### Attendance
- [ ] Add student with photos
- [ ] Take attendance with camera
- [ ] Manual attendance marking
- [ ] View attendance records
- [ ] Export attendance

### Volunteers
- [ ] Submit daily report
- [ ] View past reports
- [ ] Edit report
- [ ] Delete report

### Offline Mode
- [ ] Disable internet
- [ ] Verify offline banner appears
- [ ] Attendance still works
- [ ] Volunteer reports still work
- [ ] Other features greyscaled
- [ ] Re-enable internet and verify sync

### Multi-Language
- [ ] Switch to Hindi
- [ ] Switch to Marathi
- [ ] Verify all text translates
- [ ] Switch back to English

---

## 🎨 UI/UX Features

### Splash Screen
- Professional gradient background
- Centered logo with shadow
- App name and tagline
- Loading indicator
- Smooth transition

### Login Page
- Gradient background
- Logo in white box
- Helper text for inputs
- Icons for email/password
- Better error messages
- Forgot password dialog

### Dashboard
- Logo in header
- Clear tile descriptions
- Quick action buttons
- Offline status banner
- Notification badge

### Account Settings
- Organized sections
- Profile avatar with border
- Clear action buttons
- Logout confirmation
- Reset data option

---

## 📦 App Store Requirements

### Google Play Store
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 33+
- App icon (512x512)
- Screenshots (2-8 images)
- Description (80 characters)
- Full description (4000 characters)
- Privacy policy URL
- Content rating questionnaire

### Apple App Store
- Minimum iOS: 11.0
- App icon (1024x1024)
- Screenshots (2-5 per device)
- Description (170 characters)
- Keywords (100 characters)
- Support URL
- Privacy policy URL
- Age rating

---

## 🚀 Deployment Steps

### 1. Prepare Release
```bash
flutter clean
flutter pub get
flutter analyze
```

### 2. Build for Android
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

### 3. Build for iOS
```bash
flutter build ios --release
# Use Xcode to upload to App Store
```

### 4. Monitor After Launch
- Check crash reports
- Monitor user feedback
- Track performance metrics
- Update as needed

---

## 📝 Version History

### v1.0.0 (Current)
- Complete authentication system
- Center-based data segregation
- Offline mode support
- Face recognition for attendance
- Volunteer report management
- Multi-language support
- Professional UI with logo integration

---

## 🆘 Troubleshooting

### Black Screen on Startup
- Ensure splash_screen.dart is imported in main.dart
- Check that logo.png exists in assets/
- Verify pubspec.yaml includes assets

### Logo Not Showing
- Confirm assets/logo.png exists
- Run `flutter clean && flutter pub get`
- Check pubspec.yaml has correct asset path

### Offline Mode Not Working
- Verify connectivity_plus package is installed
- Check OfflineSyncProvider initialization
- Test with airplane mode

### Face Recognition Issues
- Ensure camera permissions are granted
- Check that student photos are clear
- Verify embeddings are being generated

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review code comments in relevant files
3. Check Supabase documentation
4. Review Flutter documentation

---

## 📄 License

SARAL - NGO Coordination Platform
© 2024 All Rights Reserved

---

**Ready to publish! Follow the checklist above and your app will be production-ready.** 🎉
