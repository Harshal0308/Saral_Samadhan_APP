# Reminder & Notification System - Setup Guide

## Quick Start

### 1. Install Dependencies
Run the following command to install the new packages:

```bash
flutter pub get
```

### 2. Platform-Specific Setup

#### Android (Already Configured)
The following Android configurations have been applied:
- ✅ Notification permissions added to AndroidManifest.xml
- ✅ Core library desugaring enabled in build.gradle.kts
- ✅ Boot receiver configured for notification persistence

No additional action needed.

#### iOS Setup (If targeting iOS)
Add the following to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 3. Run the App
```bash
flutter run
```

## Testing the Feature

### Test Schedule Reminders

1. **Open the app** and navigate to the dashboard
2. **Tap "Class Scheduler"** from the menu
3. **Add a new class schedule**:
   - Select a class/batch
   - Choose a date (today or tomorrow)
   - Set a time (e.g., 15 minutes from now)
   - Add a topic
   - Save
4. **You should see**:
   - An immediate notification: "New Class Schedule Added"
   - A scheduled reminder will appear X minutes before the class time

### Test Attendance Reminders

1. **Tap the notification bell** icon in the dashboard
2. **Tap the settings icon** (gear icon) in the notification center
3. **Configure Attendance Reminders**:
   - Enable "Attendance Reminders"
   - Set a time (e.g., 2 minutes from now for testing)
   - Select days (enable today's day)
   - Tap Save
4. **Wait for the scheduled time** - you should receive a notification

### Test Reminder Settings

1. **Access Reminder Settings**:
   - Dashboard → Notification Bell → Settings Icon
2. **Schedule Reminders**:
   - Toggle on/off
   - Change reminder time (5, 10, 15, 30, 60, 120 minutes)
3. **Attendance Reminders**:
   - Toggle on/off
   - Change reminder time
   - Select/deselect days
4. **Save** and verify settings persist

## Verification Checklist

- [ ] App builds without errors
- [ ] Schedule reminders work when adding a class
- [ ] Immediate notification shows when schedule is added
- [ ] Pre-class reminder appears at configured time
- [ ] Attendance reminder shows at configured time
- [ ] Settings page is accessible from notification center
- [ ] Settings persist after app restart
- [ ] Notifications work when app is closed
- [ ] Notifications work offline

## Troubleshooting

### Notifications Not Showing

**Android:**
1. Check app notification permissions in device settings
2. Ensure "Exact Alarm" permission is granted (Android 12+)
3. Check battery optimization settings - disable for the app

**iOS:**
1. Check notification permissions in device settings
2. Ensure app has permission to send notifications

### Reminders Not Scheduling

1. Check reminder settings are enabled
2. Verify the scheduled time is in the future
3. Check device date/time settings
4. Restart the app

### Permission Issues

Run this to check permissions:
```dart
import 'package:permission_handler/permission_handler.dart';

// Check notification permission
var status = await Permission.notification.status;
print('Notification permission: $status');

// Request if denied
if (status.isDenied) {
  await Permission.notification.request();
}
```

## Key Files Modified/Created

### New Files
- `lib/models/reminder_settings.dart` - Settings model
- `lib/services/local_notification_service.dart` - Notification service
- `lib/providers/reminder_provider.dart` - State management
- `lib/pages/reminder_settings_page.dart` - Settings UI

### Modified Files
- `pubspec.yaml` - Added dependencies
- `lib/main.dart` - Initialize reminder service
- `lib/providers/schedule_provider.dart` - Reminder integration
- `lib/pages/notification_center_page.dart` - Settings link
- `android/app/src/main/AndroidManifest.xml` - Permissions

## Usage Examples

### Accessing Reminder Settings
```
Dashboard → Notification Bell (top right) → Settings Icon
```

### Adding a Schedule with Reminder
```
Dashboard → Class Scheduler → Add Schedule → Save
(Reminder automatically scheduled)
```

### Configuring Attendance Reminders
```
Notification Center → Settings → Attendance Reminders → Configure → Save
```

## Next Steps

1. Test all features thoroughly
2. Customize notification sounds (optional)
3. Adjust default reminder times if needed
4. Train users on the new feature
5. Monitor for any issues

## Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Review the REMINDER_NOTIFICATION_FEATURE.md for detailed documentation
3. Check device logs for error messages
4. Verify all dependencies are installed correctly
