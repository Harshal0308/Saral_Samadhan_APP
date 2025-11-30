# SARAL - Samadhan App

SARAL is a comprehensive, locally-functional Flutter application designed for NGOs to manage students, volunteers, and attendance, including AI-powered face recognition for streamlined data collection. The app uses a local `sembast` database for data persistence and a Python-based FastAPI server for face recognition.

## Features

*   **Authentication:** Secure login for users (currently a dummy implementation).
*   **Student Management:** Add, edit, delete, and view student records.
*   **Attendance Tracking:**
    *   Take attendance using a group photo with face recognition.
    *   Manually mark students as present or absent.
    *   View historical attendance records.
*   **Volunteer Reporting:**
    *   Submit daily reports for volunteer activities.
    *   View and edit past volunteer reports.
    *   Bulk delete multiple reports.
*   **Data Export:**
    *   Export attendance reports to Excel, with date range filtering.
    *   Export volunteer reports to PDF.
*   **Event Management:**
    *   Create and view events and activities.
    *   Upload and view photos associated with events in a media gallery.
*   **Class Scheduler:** Schedule classes and view the schedule.
*   **Notifications:** In-app notifications for important events like new schedules, attendance saved, etc.
*   **Offline Sync Simulation:** A simulated offline sync module to track local changes.

## Project Structure

The project follows a standard Flutter structure, with the core application logic located in the `lib` directory.

*   **`lib/`**:
    *   **`main.dart`**: The main entry point of the application, responsible for initializing providers and setting up navigation.
    *   **`pages/`**: Contains all the UI screens of the application.
        *   `login_page.dart`: The login screen.
        *   `main_dashboard_page.dart`: The main dashboard after login.
        *   `student_report_page.dart`, `add_student_page.dart`, `edit_student_page.dart`: For student management.
        *   `take_attendance_page.dart`: For taking attendance.
        *   `volunteer_daily_report_page.dart`, `volunteer_reports_list_page.dart`: For volunteer reporting.
        *   `exported_reports_page.dart`: For generating and viewing exported reports.
        *   `events_activities_page.dart`: For managing events.
        *   `photo_gallery_page.dart`: For viewing event photos.
        *   `class_scheduler_page.dart`: For managing class schedules.
        *   `account_details_page.dart`: For user account management.
        *   `notification_center_page.dart`: For viewing notifications.
        *   `offline_mode_sync_page.dart`: For viewing offline sync status.
    *   **`providers/`**: Contains all the state management logic using the `provider` package.
        *   `auth_provider.dart`: Manages authentication state.
        *   `student_provider.dart`: Manages student data.
        *   `attendance_provider.dart`: Manages attendance data.
        *   `volunteer_provider.dart`: Manages volunteer report data.
        *   `export_provider.dart`: Handles data export to Excel and PDF.
        *   `event_provider.dart`: Manages event and activity data.
        *   `schedule_provider.dart`: Manages class schedule data.
        *   `notification_provider.dart`: Manages in-app notifications.
        *   `offline_sync_provider.dart`: Manages offline sync state.
        *   `user_provider.dart`: Manages user settings.
    *   **`services/`**: Contains services that interact with external systems or databases.
        *   `database_service.dart`: A singleton service to manage the local `sembast` database.
        *   `face_recognition_service.dart`: A service to communicate with the FastAPI server for face recognition.

*   **`Multiface-Recognition-Fastapi/`**: A separate Python project containing the FastAPI server for face recognition.

## Setup and Running the Application

### Prerequisites

*   Flutter SDK installed.
*   Python installed (for the backend server).
*   A code editor like VS Code.

### 1. Backend Setup (FastAPI Server)

The face recognition functionality relies on a Python FastAPI server.

1.  Navigate to the FastAPI project directory:
    ```bash
    cd samadhan_app/Multiface-Recognition-Fastapi
    ```

2.  Install the required Python packages:
    ```bash
    pip install -r requirements.txt
    ```

3.  Run the FastAPI server:
    ```bash
    uvicorn app.main:app --reload
    ```
    The server will be running at `http://127.0.0.1:8000`.

### 2. Frontend Setup (Flutter App)

1.  Navigate to the Flutter project directory:
    ```bash
    cd samadhan_app
    ```

2.  Get the Flutter dependencies:
    ```bash
    flutter pub get
    ```

3.  Run the Flutter application on your desired device (e.g., Windows):
    ```bash
    flutter run -d windows
    ```

## Future Work & Enhancements

This section outlines the planned future work and potential enhancements for the SARAL app.

### High Priority

*   **Testing and Bug Fixing:**
    *   Thoroughly test all existing features to identify and fix bugs.
    *   Test the face recognition with various lighting conditions and group sizes.
*   **Refining UI/UX:**
    *   Improve the layout and design of all pages for a better user experience.
    *   Add loading indicators for all asynchronous operations.

### Medium Priority

*   **Class Scheduler Enhancements:**
    *   Add the ability to edit and delete schedule entries.
    *   Send notifications as reminders for upcoming classes.
*   **Student Module Enhancements:**
    *   Implement bulk deletion for students.
*   **Photo Gallery Enhancements:**
    *   Implement logic to view full-screen photos when tapped.
    *   Add the ability to delete photos.

### Low Priority

*   **Full Offline Mode Implementation:**
    *   Integrate a connectivity checker (e.g., `connectivity_plus` package).
    *   Implement a robust offline queue for all data modifications.
    *   Automatically trigger sync when the device comes online.
*   **User Profile Photo:**
    *   Implement the logic to upload and display a user's profile photo on the `AccountDetailsPage`.
*   **Real Authentication:**
    *   Replace the dummy authentication with a real authentication system (e.g., Firebase Auth, OAuth).
*   **Multi-language Support:**
    *   Implement the UI changes to support the selected language.

This `README.md` file should provide a good overview of the project and its current state.