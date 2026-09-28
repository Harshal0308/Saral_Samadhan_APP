# SARAL - Smart Attendance Reporting And Learning

<p align="center">
  <img src="assets/logo.png" alt="SARAL Logo" width="180"/>
</p>

<p align="center">
  <strong>AI-Powered Educational Management System for Volunteer-Driven Learning Centers</strong>
</p>

<p align="center">
  A Flutter-based platform combining AI-powered attendance, offline-first data management, learning tracking, reporting, and multilingual support.
</p>

---

## Overview

**SARAL (Smart Attendance Reporting And Learning)** is an educational management system designed for volunteer-driven learning centers and NGO-led educational programs.

The platform helps teachers and volunteers manage students, attendance, learning progress, session reports, analytics, and administrative data through a centralized application.

A major component of SARAL is its **AI-powered face-recognition attendance system**, which uses Google ML Kit for face detection and TensorFlow Lite for generating face embeddings and identifying enrolled students.

The application also follows an **offline-first approach**, allowing core operations to continue in low-connectivity environments and synchronize data with Supabase when connectivity is available.

---

## Key Features

* 🤖 **AI-Powered Attendance** — Automated student identification using face embeddings
* 📴 **Offline-First Support** — Local data storage and synchronization for low-connectivity environments
* 📊 **Learning & Attendance Analytics** — Attendance trends, student progress, and performance insights
* 👨‍🎓 **Student Management** — Student profiles, enrollment, attendance, and learning progress
* 📝 **Volunteer Reporting** — Session reports, assessments, and activity tracking
* 📄 **Report Generation** — PDF and Excel export for attendance and educational records
* 🌐 **Multilingual Support** — Localization for multiple Indian languages
* 💬 **SAATHI** — AI-powered navigation assistant
* 🔐 **Role-Based Access** — Authentication and center-based data access through Supabase

---

## My Contribution

SARAL was developed as part of a **3-member team**.

My primary contributions included:

* Contributing to **product ideation, feature planning, and usability decisions**.
* Working on the **face-recognition attendance pipeline**, including face embedding generation and student identification using TensorFlow Lite.

The project involved contributions from multiple team members across application development, UI/UX, and AI/ML components.

---

## Face Recognition Pipeline

The attendance system follows a multi-stage pipeline:

```text
Camera Input
     │
     ▼
Google ML Kit
Face Detection + Landmarks
     │
     ▼
Face Alignment
Native C++ / FFI Processing
     │
     ▼
TensorFlow Lite
512-D Face Embedding
     │
     ▼
Cosine Similarity
     │
     ▼
Student Identification
     │
     ▼
Attendance Record
```

### Implementation

1. **Face Detection**
   Google ML Kit detects faces and provides facial landmarks.

2. **Face Alignment**
   The detected face is aligned and preprocessed using native C++ code through FFI.

3. **Embedding Generation**
   A TensorFlow Lite face-recognition model generates a **512-dimensional embedding vector** for the detected face.

4. **Face Matching**
   The generated embedding is compared with stored student embeddings using **cosine similarity**.

5. **Attendance Recording**
   When the similarity exceeds the configured threshold, the corresponding student can be identified and attendance can be recorded.

> Student face representations are stored as embeddings rather than raw face images for the recognition pipeline.

---

## Offline-First Architecture

SARAL is designed to continue working in environments with unreliable internet connectivity.

```text
              ┌──────────────────┐
              │   Flutter UI     │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │    Providers     │
              │  State Management│
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │     Services     │
              └───────┬───┬──────┘
                      │   │
             ┌────────┘   └─────────┐
             ▼                      ▼
      ┌─────────────┐        ┌─────────────┐
      │   Sembast   │        │  Supabase   │
      │ Local Data  │◄──────►│ PostgreSQL  │
      └─────────────┘        └─────────────┘
```

Local data is maintained using **Sembast**, while Supabase provides cloud storage and synchronization.

---

## Technology Stack

### Frontend

* **Flutter**
* **Dart**
* **Provider**
* **Material Design 3**
* **Sembast**

### Backend & Database

* **Supabase**
* **PostgreSQL**
* **Supabase Auth**
* **Supabase Storage**
* **Supabase Realtime**

### AI / ML

* **Google ML Kit**
* **TensorFlow Lite**
* **MobileFaceNet**
* **Native C++ / FFI**
* **Google Gemini API**

### Reporting & Utilities

* PDF generation
* Excel export
* Localization
* Offline synchronization

---

## Application Modules

| Module              | Purpose                                      |
| ------------------- | -------------------------------------------- |
| Authentication      | User authentication and role-based access    |
| Student Management  | Student profiles, enrollment, and progress   |
| Attendance          | Manual and AI-powered attendance             |
| Volunteer Reporting | Session and activity reports                 |
| Learning Tracking   | Subject and topic progress                   |
| Analytics           | Attendance and performance insights          |
| Reports             | PDF and Excel exports                        |
| Admin Portal        | Web-based administration and data management |
| SAATHI              | AI-powered navigation assistance             |

---

## Admin Portal

SARAL also includes a web-based administration portal for managing application data.

### Features

* Dashboard with statistics
* Student management
* Teacher management
* Attendance records
* Volunteer reports
* Events and schedules
* Search and filtering
* Supabase-backed authentication

### Run Admin Portal

```bash
flutter run -d chrome -t lib/admin/main_admin.dart
```

---

## Project Structure

```text
lib/
├── main.dart
├── admin/
│   ├── main_admin.dart
│   ├── pages/
│   ├── providers/
│   └── widgets/
├── l10n/
├── models/
├── pages/
├── providers/
├── services/
├── theme/
├── utils/
└── widgets/
```

Key services include:

```text
services/
├── face_recognition_service.dart
├── auth_service.dart
├── cloud_sync_service_v2.dart
└── ...
```

---

## Installation

### Prerequisites

* Flutter SDK 3.10+
* Dart SDK 3.0+
* Android Studio or VS Code
* Android NDK for native face-alignment components
* Supabase project

### Setup

**1. Clone the repository**

```bash
git clone https://github.com/Harshal0308/Saral_Samadhan_APP.git
cd Saral_Samadhan_APP
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Configure environment variables**

Create a `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

**4. Generate localization files**

```bash
flutter gen-l10n
```

**5. Run the application**

```bash
flutter run
```

---

## Database

SARAL uses **Supabase PostgreSQL** for cloud data management.

Major data entities include:

* Teachers
* Students
* Attendance records
* Volunteer reports
* Topic evaluations
* Events
* Media items

Row Level Security (RLS) is used to control access to data.

---


## Future Improvements

* Improve face-recognition robustness across different lighting conditions
* Expand offline synchronization and conflict handling
* Improve analytics and learning-progress insights
* Extend AI-assisted features
* Further optimize the application for low-resource devices

---

## Team

**Team Skydivers**

* **Sidharth Maharana** — Lead Developer
* **Harshal Kale** — ML Engineer
* **Shiv Tangloo** — UI/UX Designer

---

## Acknowledgments

* [Flutter](https://flutter.dev/) — UI framework
* [Supabase](https://supabase.com/) — Backend and database infrastructure
* [Google ML Kit](https://developers.google.com/ml-kit) — Face detection
* [TensorFlow Lite](https://www.tensorflow.org/lite) — On-device machine learning

---

<p align="center">
  Built with ❤️ for educational empowerment
</p>
