# SARAL - Smart Attendance Reporting And Learning

<p align="center">
  <img src="assets/logo.png" alt="SARAL Logo" width="200"/>
</p>

<p align="center">
  <strong>AI-Powered Educational Management System for Volunteer-Driven Learning Centers</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## Overview

SARAL is a comprehensive mobile application designed to address critical challenges in educational management across India. Built for NGOs and volunteer-driven educational programs, it combines **AI-powered facial recognition** for automated attendance, **offline-first architecture** for low-connectivity areas, and **support for 22 Indian languages** to serve diverse linguistic communities.

### Key Highlights

- 🤖 **AI Face Recognition** - Automated attendance with 512-dimensional embeddings
- 📴 **Offline-First** - Full functionality without internet connectivity
- 🌐 **22 Languages** - Support for all scheduled Indian languages
- 📊 **Analytics Dashboard** - Visual insights and comprehensive reporting
- 🔄 **Cloud Sync** - Seamless data synchronization with Supabase
- 💬 **SAATHI Chatbot** - Multilingual AI navigation assistant

---

## Features

### 🎯 Core Modules

| Module | Description |
|--------|-------------|
| **Authentication** | Email/password auth with teacher profiles and role-based access |
| **Student Management** | CRUD operations with face enrollment and progress tracking |
| **Attendance** | Manual and AI-powered face recognition attendance |
| **Volunteer Reporting** | Daily session reports, test administration, activity tracking |
| **Learning Tracking** | Subject-wise topic progress and baseline assessments |
| **Analytics Dashboard** | Interactive charts, attendance trends, performance metrics |
| **Export Module** | PDF/Excel report generation with sharing capabilities |
| **SAATHI Chatbot** | Gemini-powered multilingual navigation assistant |

### 🔐 Face Recognition System

The face recognition pipeline operates in four stages:

1. **Face Detection** - Google ML Kit with 5-point landmark detection
2. **Face Alignment** - Native FFI-based preprocessing for optimal quality
3. **Embedding Generation** - TensorFlow Lite model producing 512-D vectors
4. **Matching** - Cosine similarity with configurable threshold (default: 0.7)

### 🌍 Supported Languages


| Language | Code | Language | Code |
|----------|------|----------|------|
| English | en | Hindi | hi |
| Bengali | bn | Telugu | te |
| Marathi | mr | Tamil | ta |
| Gujarati | gu | Kannada | kn |
| Malayalam | ml | Odia | or |
| Punjabi | pa | Assamese | as |
| Maithili | mai | Sanskrit | sa |
| Santali | sat | Kashmiri | ks |
| Nepali | ne | Sindhi | sd |
| Konkani | kok | Dogri | doi |
| Manipuri | mni | Bodo | brx |

---

## Tech Stack

### Frontend
- **Framework**: Flutter 3.10+ (Dart 3.0+)
- **State Management**: Provider
- **Local Database**: Sembast (NoSQL document store)
- **UI Components**: Material Design 3

### Backend
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **Real-time**: Supabase Realtime

### AI/ML
- **Face Detection**: Google ML Kit
- **Face Embeddings**: TensorFlow Lite (MobileFaceNet)
- **Face Alignment**: Native C++ via FFI
- **Chatbot**: Google Gemini API

### Key Dependencies

```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.2
  sembast: ^3.7.0
  supabase_flutter: ^2.5.0
  tflite_flutter: ^0.12.1
  google_mlkit_face_detection: ^0.13.1
  fl_chart: ^0.68.0
  pdf: ^3.10.8
  excel: ^4.0.2
  image_picker: ^1.0.8
  cached_network_image: ^3.3.0
  flutter_local_notifications: ^18.0.1
```

---

## Admin Portal (Web)

The admin portal provides a web-based interface to view and manage all Supabase data directly.

### Running the Admin Portal

```bash
# Run admin portal on web (Chrome)
flutter run -d chrome -t lib/admin/main_admin.dart

# Build for web deployment
flutter build web -t lib/admin/main_admin.dart --release
```

### Admin Portal Features
- 📊 Dashboard with real-time statistics
- 👨‍🎓 View/Edit/Delete Students
- 👨‍🏫 Manage Teachers
- ✅ View Attendance Records
- 🙋 Manage Volunteers & Reports
- 📅 View Events & Schedules
- 🔍 Search & Filter by Center/Class
- 🔐 Same authentication as mobile app

---

## Installation

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android NDK (for native face alignment)
- Supabase account

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/saral-app.git
   cd saral-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GEMINI_API_KEY=your_gemini_api_key
   ```

4. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## Configuration

### Supabase Setup

1. Create a new Supabase project
2. Run the database migrations (see `supabase/migrations/`)
3. Configure Row Level Security (RLS) policies
4. Set up storage buckets for media

### Required Database Tables

| Table | Purpose |
|-------|---------|
| `teachers` | Teacher profiles and authentication |
| `students` | Student data with face embeddings |
| `attendance_records` | Daily attendance records |
| `volunteer_reports` | Teaching session reports |
| `topic_evaluations` | Learning progress tracking |
| `events` | Center events and activities |
| `media_items` | Photo gallery metadata |

### Android Configuration

The app requires these permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── admin/                    # Admin Portal (Web)
│   ├── main_admin.dart       # Admin entry point
│   ├── pages/                # Admin UI screens
│   ├── providers/            # Admin state management
│   └── widgets/              # Admin components
├── l10n/                     # Localization files (22 languages)
├── models/                   # Data models
│   ├── student.dart
│   ├── teacher.dart
│   ├── attendance_record.dart
│   └── ...
├── pages/                    # UI screens (50+ pages)
│   ├── login_page.dart
│   ├── main_dashboard_page.dart
│   ├── take_attendance_page.dart
│   └── ...
├── providers/                # State management
│   ├── student_provider.dart
│   ├── attendance_provider.dart
│   ├── auth_provider.dart
│   └── ...
├── services/                 # Business logic
│   ├── face_recognition_service.dart
│   ├── auth_service.dart
│   ├── cloud_sync_service_v2.dart
│   └── ...
├── theme/                    # App theming
│   └── saral_theme.dart
├── utils/                    # Utilities
│   └── sorting_utils.dart
└── widgets/                  # Reusable components
    └── loading_button.dart
```

### Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   UI Layer  │ ──▶ │  Providers  │ ──▶ │  Services   │
│   (Pages)   │ ◀── │   (State)   │ ◀── │  (Logic)    │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
             ┌─────────────┐           ┌─────────────┐           ┌─────────────┐
             │   Sembast   │           │  Supabase   │           │  TFLite +   │
             │  (Offline)  │           │   (Cloud)   │           │   ML Kit    │
             └─────────────┘           └─────────────┘           └─────────────┘
```

---

## System Requirements

### Minimum Requirements
- Android 7.0+ (API 24)
- 3GB RAM
- 250MB storage
- Camera (for face recognition)

### Recommended
- Android 9.0+ (API 28)
- 4GB+ RAM
- 500MB storage
- Front-facing camera

---

## Building for Production

### Generate Release APK
```bash
flutter build apk --release
```

### Generate App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### Signing Configuration

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=your_password
   keyPassword=your_password
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

3. Update `android/app/build.gradle.kts` with signing config

---

## Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Face Recognition Testing
- Test with various lighting conditions
- Verify threshold settings (default: 0.7)
- Test with multiple enrolled faces per student

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before committing
- Write meaningful commit messages

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Supabase](https://supabase.com/) - Backend infrastructure
- [Google ML Kit](https://developers.google.com/ml-kit) - Face detection
- [TensorFlow Lite](https://www.tensorflow.org/lite) - On-device ML

---

## Contact

**Team Skydivers**

- Sidharth Maharana - Lead Developer
- Harshal Kale - ML Engineer  
- Shiv Tangloo - UI/UX Designer

---

<p align="center">
  Made with ❤️ for educational empowerment in India
</p>
