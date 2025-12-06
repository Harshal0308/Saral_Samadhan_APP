# Testing Reminder & Notification System

## Quick Test Scenarios

### Scenario 1: Test Schedule Reminder (5 minutes)

1. **Open the app**
2. **Go to Class Scheduler** (from dashboard menu)
3. **Add a new schedule**:
   - Class/Batch: "Test Class A"
   - Date: Today
   - Time: 10 minutes from now
   - Topic: "Test Topic"
   - Click Save
4. **Expected Results**:
   - ✅ Immediate notification: "New Class Schedule Added"
   - ✅ In notification center: New notification appears
   - ✅ After 5 minutes (default): "Class Reminder" notification

### Scenario 2: Configure Reminder Settings

1. **Tap notification bell** (top right of dashboard)
2. **Tap settings icon** (gear icon)
3. **Modify Schedule Reminders**:
   - Change "Remind me before" to 15 minutes
   - Click Save
4. **Expected Results**:
   - ✅ Success message: "Reminder settings saved successfully"
   - ✅ Settings persist after closing and reopening

### Scenario 3: Test Attendance Reminder

1. **Go to Reminder Settings** (Notification Center → Settings)
2. **Configure Attendance Reminder**:
   - Enable "Attendance Reminders"
   - Set time to 3 minutes from now
   - Select today's day of week
   - Click Save
3. **Wait 3 minutes**
4. **Expected Results**:
   - ✅ Notification appears: "Attendance Reminder"
   - ✅ Message: "Don't forget to mark attendance for today's classes"

### Scenario 4: Test Offline Functionality

1. **Add a schedule** for 10 minutes from now
2. **Turn on Airplane Mode** or disable WiFi/Data
3. **Close the app completely**
4. **Wait for reminder time**
5. **Expected Results**:
   - ✅ Notification still appears even offline
   - ✅ Notification appears even with app closed

### Scenario 5: Test Day Selection

1. **Go to Reminder Settings**
2. **Configure Attendance Reminder**:
   - Enable attendance reminders
   - Set time to 2 minutes from now
   - **Deselect today's day**
   - Select only tomorrow's day
   - Click Save
3. **Wait 2 minutes**
4. **Expected Results**:
   - ✅ No notification today (since today is deselected)
   - ✅ Will receive notification tomorrow at set time

### Scenario 6: Test Multiple Schedules

1. **Add 3 different schedules**:
   - Schedule 1: 5 minutes from now
   - Schedule 2: 10 minutes from now
   - Schedule 3: 15 minutes from now
2. **Expected Results**:
   - ✅ 3 immediate notifications for schedule added
   - ✅ 3 separate reminder notifications at appropriate times

### Scenario 7: Test Schedule Update

1. **Add a schedule** for tomorrow at 10:00 AM
2. **Edit the schedule** and change time to 11:00 AM
3. **Expected Results**:
   - ✅ Old reminder is cancelled
   - ✅ New reminder is scheduled for 11:00 AM

### Scenario 8: Test Schedule Deletion

1. **Add a schedule** for tomorrow
2. **Delete the schedule**
3. **Expected Results**:
   - ✅ Reminder notification is cancelled
   - ✅ No notification will appear at scheduled time

## Verification Commands

### Check Pending Notifications (Developer)
Add this code temporarily to see pending notifications:

```dart
// In any page, add a button with this action:
final reminders = await context.read<ReminderProvider>().getPendingNotifications();
print('Pending notifications: ${reminders.length}');
for (var reminder in reminders) {
  print('ID: ${reminder.id}, Title: ${reminder.title}');
}
```

### Check Permissions (Android)
```
Settings → Apps → SARAL → Permissions → Notifications (should be ON)
Settings → Apps → SARAL → Alarms & reminders (should be ON)
```

### Check Permissions (iOS)
```
Settings → SARAL → Notifications (should be ON)
```

## Common Issues & Solutions

### Issue: No notifications appearing
**Solution:**
1. Check app notification permissions in device settings
2. Ensure battery optimization is disabled for the app
3. Verify the scheduled time is in the future
4. Restart the app

### Issue: Notifications appear but no sound
**Solution:**
1. Check device volume settings
2. Check notification channel settings
3. Verify "Do Not Disturb" is off

### Issue: Reminders not persisting after device restart
**Solution:**
1. Verify RECEIVE_BOOT_COMPLETED permission in manifest
2. Check if device has battery optimization enabled
3. Some devices require manual permission for boot receivers

### Issue: Settings not saving
**Solution:**
1. Check database initialization
2. Verify write permissions
3. Check for any error logs

## Performance Checklist

- [ ] App starts without crashes
- [ ] Notifications appear on time
- [ ] Settings save and load correctly
- [ ] Multiple schedules work simultaneously
- [ ] Offline functionality works
- [ ] App closed functionality works
- [ ] Battery usage is reasonable
- [ ] No memory leaks
- [ ] UI is responsive

## User Acceptance Criteria

✅ Users can enable/disable schedule reminders
✅ Users can choose reminder time before class
✅ Users can enable/disable attendance reminders
✅ Users can set custom attendance reminder time
✅ Users can select specific days for attendance reminders
✅ Notifications work offline
✅ Notifications work when app is closed
✅ Settings persist across app restarts
✅ Immediate notification when schedule is added
✅ Reminders are automatically managed (add/update/delete)

## Test Report Template

```
Date: ___________
Tester: ___________
Device: ___________
OS Version: ___________

Scenario 1: [ ] Pass [ ] Fail
Scenario 2: [ ] Pass [ ] Fail
Scenario 3: [ ] Pass [ ] Fail
Scenario 4: [ ] Pass [ ] Fail
Scenario 5: [ ] Pass [ ] Fail
Scenario 6: [ ] Pass [ ] Fail
Scenario 7: [ ] Pass [ ] Fail
Scenario 8: [ ] Pass [ ] Fail

Issues Found:
1. ___________
2. ___________
3. ___________

Overall Status: [ ] Approved [ ] Needs Work
```
