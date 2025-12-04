# SARAL App - Multi-Teacher Setup Guide

## 🎯 Overview

Multiple teachers in the same center can now access and share the same student data, attendance records, and volunteer reports.

---

## 🔄 How It Works

### Data Sync Architecture

```
Teacher 1 (Local Device)          Teacher 2 (Local Device)
    ↓                                  ↓
[Local Database]                  [Local Database]
    ↓                                  ↓
    └─────────→ [Supabase Cloud] ←─────┘
                (Shared Data)
```

### Sync Flow

```
1. Teacher adds student
   ↓
2. Data saved locally
   ↓
3. If online → Upload to Supabase
   ↓
4. Other teachers' apps sync automatically
   ↓
5. All teachers see the same student
```

---

## ✅ What Gets Synced

### Students
- ✅ Student name, roll number, class
- ✅ Face embeddings (for recognition)
- ✅ Lessons learned
- ✅ Test results

### Attendance
- ✅ Daily attendance records
- ✅ Present/absent status
- ✅ Date and time

### Volunteer Reports
- ✅ Volunteer name and activity
- ✅ Students involved
- ✅ Test results (if conducted)
- ✅ In/out times

---

## 🚀 How to Use Multi-Teacher Features

### Scenario 1: Adding a Student

```
Teacher 1:
1. Opens app
2. Selects center "Mumbai Central"
3. Adds student "Raj" with photos
4. Student saved locally
5. If online → Uploaded to cloud

Teacher 2:
1. Opens app
2. Selects same center "Mumbai Central"
3. Clicks sync button (cloud icon)
4. App downloads "Raj" from cloud
5. Now sees "Raj" in student list
```

### Scenario 2: Taking Attendance

```
Teacher 1:
1. Takes attendance for class 5
2. Marks 30 students present
3. Attendance saved locally
4. If online → Uploaded to cloud

Teacher 2:
1. Opens app
2. Clicks sync button
3. Downloads attendance from Teacher 1
4. Can view same attendance records
5. Can add more attendance if needed
```

### Scenario 3: Volunteer Reports

```
Teacher 1:
1. Submits volunteer report
2. Report saved locally
3. If online → Uploaded to cloud

Teacher 2:
1. Opens app
2. Clicks sync button
3. Downloads report from Teacher 1
4. Can view and edit report
5. Can add more reports
```

---

## 🔄 Automatic Sync

### When Does Sync Happen?

```
✅ Automatically:
- When dashboard loads
- When adding a student (if online)
- When saving attendance (if online)
- When submitting volunteer report (if online)

✅ Manually:
- Click cloud sync button in dashboard header
```

### Sync Button

```
Location: Dashboard header (top right)
Icon: Cloud with sync arrows
Status:
  - Spinning: Sync in progress
  - Static: Ready to sync
  - Disabled: Already syncing
```

---

## 📱 Offline Mode with Multi-Teacher

### When Offline

```
✅ Works offline:
- Add students (syncs when online)
- Take attendance (syncs when online)
- Submit reports (syncs when online)
- View local data

❌ Cannot:
- See other teachers' new data
- Sync with cloud
```

### When Back Online

```
1. App detects internet connection
2. Automatically syncs data
3. Downloads new data from other teachers
4. Shows notification: "Data synced with other teachers"
```

---

## 🔐 Data Consistency

### Conflict Resolution

If two teachers add the same student:
```
Teacher 1: Adds "Raj" (ID: 101)
Teacher 2: Adds "Raj" (ID: 102)

Result:
- Both records kept (different IDs)
- No conflict
- Both visible in app
```

### Duplicate Prevention

```
System checks:
- Roll number
- Class batch
- Center name

If all three match → Considered same student
If any differs → Considered different student
```

---

## 📊 Sync Status Indicators

### Dashboard Notifications

```
✅ "Data synced with other teachers"
   → Sync successful

⚠️ "Sync failed: [error]"
   → Sync failed, will retry

🔄 Sync button spinning
   → Sync in progress

📡 Offline banner visible
   → No internet, sync disabled
```

---

## 🎯 Best Practices

### For Multiple Teachers

1. **Sync Regularly**
   - Click sync button when opening app
   - Ensures you have latest data

2. **Use Same Center**
   - All teachers must select same center
   - Data only syncs within same center

3. **Check Before Editing**
   - Sync before editing student data
   - Prevents duplicate entries

4. **Communicate**
   - Tell other teachers about new students
   - Coordinate attendance marking

5. **Stay Online**
   - Keep internet on for sync
   - Offline mode works but delays sync

---

## 🔧 Technical Details

### Supabase Tables

```
students
├── id (unique)
├── name
├── rollNo
├── classBatch
├── centerName
├── embeddings
├── lessonsLearned
├── testResults
└── createdAt

attendance_records
├── id (unique)
├── date
├── centerName
├── attendance (map)
└── createdAt

volunteer_reports
├── id (unique)
├── volunteerName
├── selectedStudents
├── classBatch
├── centerName
├── inTime
├── outTime
├── activityTaught
├── testConducted
├── testTopic
├── marksGrade
├── testStudents
├── testMarks
└── createdAt
```

### Sync Service

```
CloudSyncService:
├── uploadStudent()
├── downloadStudentsForCenter()
├── uploadAttendanceRecord()
├── downloadAttendanceForCenter()
├── uploadVolunteerReport()
├── downloadVolunteerReportsForCenter()
└── fullSyncForCenter()
```

---

## 📋 Troubleshooting

### Problem: Data not syncing

**Solution:**
1. Check internet connection
2. Click sync button manually
3. Wait for sync to complete
4. Refresh app

### Problem: Seeing duplicate students

**Solution:**
1. Check roll number and class
2. If different → Different students (OK)
3. If same → Merge manually
4. Contact admin

### Problem: Attendance not showing

**Solution:**
1. Sync with other teachers
2. Check if attendance was marked
3. Verify center selection
4. Check date range

### Problem: Sync button not working

**Solution:**
1. Check internet connection
2. Verify Supabase is running
3. Check app permissions
4. Restart app

---

## 🎓 Example Workflow

### Day 1: Teacher 1 Sets Up

```
1. Opens app
2. Selects center "Mumbai Central"
3. Adds 30 students for class 5
4. Takes attendance (25 present)
5. Submits volunteer report
6. All data synced to cloud
```

### Day 2: Teacher 2 Joins

```
1. Opens app
2. Selects center "Mumbai Central"
3. Clicks sync button
4. Downloads 30 students
5. Downloads attendance from Day 1
6. Downloads volunteer report
7. Can now add more students or attendance
8. All new data syncs back to Teacher 1
```

### Day 3: Both Teachers Working

```
Teacher 1:
- Takes attendance for class 5
- Adds 5 new students
- Submits volunteer report

Teacher 2:
- Takes attendance for class 6
- Edits student information
- Submits volunteer report

Result:
- All data synced between both
- Both see all students and records
- No conflicts or duplicates
```

---

## 🚀 Deployment Checklist

### Before Publishing

- [ ] Supabase tables created
- [ ] Cloud sync service tested
- [ ] Multi-teacher sync tested
- [ ] Offline mode tested
- [ ] Conflict resolution tested
- [ ] Error handling tested
- [ ] Documentation updated

### After Publishing

- [ ] Monitor sync performance
- [ ] Check for sync errors
- [ ] Gather user feedback
- [ ] Update as needed

---

## 📞 Support

### Common Questions

**Q: Can teachers from different centers see each other's data?**
A: No. Data is segregated by center. Each center only sees its own data.

**Q: What if internet is slow?**
A: Sync will take longer but will complete. App shows progress.

**Q: Can I edit data while syncing?**
A: Yes, but changes won't sync until current sync completes.

**Q: What if two teachers add same student?**
A: System checks roll number + class + center. If all match, considered same student.

**Q: How often should I sync?**
A: Sync automatically on app load. Manual sync available anytime.

---

## ✨ Summary

**Multi-Teacher Features:**
- ✅ All teachers in same center access same data
- ✅ Automatic sync when online
- ✅ Manual sync button available
- ✅ Works offline (syncs when online)
- ✅ No data conflicts
- ✅ Real-time collaboration

**Ready for multi-teacher centers!** 🎉
