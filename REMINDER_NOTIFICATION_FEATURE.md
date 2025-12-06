# Reminder & Notification System

## Overview
A comprehensive notification and reminder system that works offline and provides timely alerts for class schedules and attendance.

## Features

### 1. Schedule Reminders
- **Automatic Notifications**: When a class is added to the schedule, users receive an immediate notification
- **Pre-Class Reminders**: Configurable reminders before scheduled classes (5, 10, 15, 30, 60, or 120 minutes)
- **Offline Support**: Reminders work even when the app is closed or device is offline
- **Auto-Scheduling**: Reminders are automatically scheduled when adding/updating schedules

### 2. Attendance Reminders
- **Daily Reminders**: Configurable daily reminder to mark attendance
- **Custom Time**: Set your preferred reminder time
- **Day Selection**: Choose which days of the week to receive reminders (Mon-Sun)
- **Persistent**: Works offline and shows even when app is closed

### 3. Settings Management
- **Easy Configuration**: Dedicated settings page accessible from notification center
- **Toggle Controls**: Enable/disable reminders independently
- **Flexible Options**: Customize timing and frequency
- **Instant Save**: Settings are saved immediately and applied

## Technical Implementation

### New Dependencies
```yaml
flutter_local_notifications: ^18.0.1  # Local notification support
timezone: ^0.9.4                       # Timezone handling
permission_handler: ^11.3.1            # Permission management
```

### New Files Created

1. **lib/models/reminder_settings.dart**
   - Data model for reminder preferences
   - Serialization/deserialization support

2. **lib/services/local_notification_service.dart**
   - Core notification service
   - Handles scheduling, canceling, and showing notifications
   - Timezone support for accurate scheduling
   - Permission handling

3. **lib/providers/reminder_provider.dart**
   - State management for reminders
   - Integration with schedule provider
   - Settings persistence using Sembast

4. **lib/pages/reminder_settings_page.dart**
   - User interface for configuring reminders
   - Schedule reminder settings
   - Attendance reminder settings
   - Day selection and time picker

### Modified Files

1. **pubspec.yaml**
   - Added notification dependencies

2. **lib/main.dart**
   - Initialize reminder service on app startup
   - Added ReminderProvider to provider tree
   - Linked ScheduleProvider with ReminderProvider

3. **lib/providers/schedule_provider.dart**
   - Integration with reminder system
   - Auto-schedule notifications on add/update
   - Cancel notifications on delete

4. **lib/pages/notification_center_page.dart**
   - Added settings button to access reminder settings

## Usage

### For Users

1. **Access Settings**:
   - Tap notification bell icon in dashboard
   - Tap settings icon in notification center
   - Configure your preferences

2. **Schedule Reminders**:
   - Enable "Schedule Reminders"
   - Choose how many minutes before class you want to be reminded
   - Reminders are automatically created when you add a class

3. **Attendance Reminders**:
   - Enable "Attendance Reminders"
   - Set your preferred reminder time
   - Select which days you want reminders
   - Receive daily notifications at your chosen time

### For Developers

**Initialize the service**:
```dart
await ReminderProvider().initialize();
```

**Schedule a class reminder**:
```dart
await reminderProvider.scheduleClassReminder(scheduleEntry);
```

**Show immediate notification**:
```dart
await reminderProvider.showScheduleAddedNotification(scheduleEntry);
```

**Update settings**:
```dart
await reminderProvider.updateSettings(newSettings);
```

## Platform-Specific Setup

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Data Storage

All reminder settings are stored locally using Sembast database:
- **Store Key**: `reminder_settings`
- **Offline First**: All data persists locally
- **No Cloud Dependency**: Works completely offline

## Notification IDs

- **Schedule Reminders**: Use schedule entry ID
- **Attendance Reminder**: Fixed ID `999999`
- **Schedule Added**: Random ID based on timestamp

## Benefits

1. **Never Miss a Class**: Timely reminders before scheduled classes
2. **Attendance Tracking**: Daily reminders to mark attendance
3. **Offline Reliability**: Works without internet connection
4. **Flexible Configuration**: Customize to your needs
5. **Battery Efficient**: Uses native notification scheduling
6. **User-Friendly**: Simple, intuitive interface

## Future Enhancements

- Custom notification sounds
- Snooze functionality
- Multiple reminder times per schedule
- Smart reminders based on location
- Notification history
- Reminder statistics and insights
