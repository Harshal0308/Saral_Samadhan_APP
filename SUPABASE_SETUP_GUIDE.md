# SARAL App - Supabase Setup Guide for Multi-Teacher Login

## 🎯 Overview

This guide walks you through setting up Supabase for multi-teacher authentication and data sharing.

---

## 📋 Prerequisites

- Supabase account (free tier available at https://supabase.com)
- SARAL app code
- Basic understanding of databases

---

## 🚀 Step 1: Create Supabase Project

### 1.1 Go to Supabase Dashboard
```
1. Visit https://supabase.com
2. Click "Sign In" or "Start Your Project"
3. Sign up with email or GitHub
```

### 1.2 Create New Project
```
1. Click "New Project"
2. Enter project name: "SARAL"
3. Enter database password (save this!)
4. Select region closest to you
5. Click "Create new project"
6. Wait for project to initialize (2-3 minutes)
```

### 1.3 Get Project Credentials
```
1. Go to Project Settings (gear icon)
2. Click "API" in left sidebar
3. Copy these values:
   - Project URL (save as SUPABASE_URL)
   - anon key (save as SUPABASE_ANON_KEY)
   - service_role key (save for later)
```

---

## 🔐 Step 2: Set Up Authentication

### 2.1 Enable Email Authentication
```
1. Go to Authentication → Providers
2. Find "Email" provider
3. Click to expand
4. Toggle "Enable Email provider" ON
5. Keep default settings
6. Click "Save"
```

### 2.2 Configure Email Settings (Optional)
```
1. Go to Authentication → Email Templates
2. Customize welcome email if desired
3. Keep default templates for now
```

### 2.3 Set Up Auth Redirects
```
1. Go to Authentication → URL Configuration
2. Under "Redirect URLs", add:
   - http://localhost:3000 (for testing)
   - Your app's URL (for production)
3. Click "Save"
```

---

## 📊 Step 3: Create Database Tables

### 3.1 Create Teachers Table

```sql
-- Go to SQL Editor → New Query
-- Copy and paste this SQL:

CREATE TABLE teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  phone_number TEXT,
  center_name TEXT NOT NULL,
  role TEXT DEFAULT 'teacher', -- 'teacher' or 'admin'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_teachers_center ON teachers(center_name);
CREATE INDEX idx_teachers_email ON teachers(email);

-- Run the query
```

### 3.2 Create Students Table

```sql
-- Go to SQL Editor → New Query

CREATE TABLE students (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  roll_no TEXT NOT NULL,
  class_batch TEXT NOT NULL,
  center_name TEXT NOT NULL,
  lessons_learned TEXT[] DEFAULT '{}',
  test_results JSONB DEFAULT '{}',
  embeddings FLOAT8[][] DEFAULT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(roll_no, class_batch, center_name)
);

-- Create indexes
CREATE INDEX idx_students_center ON students(center_name);
CREATE INDEX idx_students_class ON students(class_batch);
CREATE INDEX idx_students_roll ON students(roll_no);

-- Run the query
```

### 3.3 Create Attendance Records Table

```sql
-- Go to SQL Editor → New Query

CREATE TABLE attendance_records (
  id BIGSERIAL PRIMARY KEY,
  date DATE NOT NULL,
  center_name TEXT NOT NULL,
  attendance JSONB NOT NULL, -- {student_id: true/false}
  created_by UUID REFERENCES teachers(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_attendance_center ON attendance_records(center_name);
CREATE INDEX idx_attendance_date ON attendance_records(date);
CREATE INDEX idx_attendance_center_date ON attendance_records(center_name, date);

-- Run the query
```

### 3.4 Create Volunteer Reports Table

```sql
-- Go to SQL Editor → New Query

CREATE TABLE volunteer_reports (
  id BIGSERIAL PRIMARY KEY,
  volunteer_name TEXT NOT NULL,
  selected_students INTEGER[] NOT NULL,
  class_batch TEXT NOT NULL,
  center_name TEXT NOT NULL,
  in_time TEXT NOT NULL,
  out_time TEXT NOT NULL,
  activity_taught TEXT NOT NULL,
  test_conducted BOOLEAN DEFAULT false,
  test_topic TEXT,
  marks_grade TEXT,
  test_students INTEGER[] DEFAULT '{}',
  test_marks JSONB DEFAULT '{}',
  created_by UUID REFERENCES teachers(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_reports_center ON volunteer_reports(center_name);
CREATE INDEX idx_reports_volunteer ON volunteer_reports(volunteer_name);
CREATE INDEX idx_reports_date ON volunteer_reports(created_at);

-- Run the query
```

### 3.5 Create Centers Table

```sql
-- Go to SQL Editor → New Query

CREATE TABLE centers (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  location TEXT,
  admin_email TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample centers
INSERT INTO centers (name, location) VALUES
  ('Mumbai Central', 'Dadar, Mumbai'),
  ('Pune East Center', 'Kothrud, Pune'),
  ('Nashik Hub', 'College Road, Nashik'),
  ('Nagpur Center', 'Sitabuldi, Nagpur'),
  ('Thane Branch', 'Ghodbunder, Thane');

-- Run the query
```

---

## 🔒 Step 4: Set Up Row Level Security (RLS)

### 4.1 Enable RLS on Teachers Table

```sql
-- Go to SQL Editor → New Query

-- Enable RLS
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;

-- Teachers can only see their own record
CREATE POLICY "Teachers can view own record"
  ON teachers FOR SELECT
  USING (auth.uid() = id);

-- Teachers can update their own record
CREATE POLICY "Teachers can update own record"
  ON teachers FOR UPDATE
  USING (auth.uid() = id);

-- Admins can view all teachers
CREATE POLICY "Admins can view all teachers"
  ON teachers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM teachers t
      WHERE t.id = auth.uid() AND t.role = 'admin'
    )
  );

-- Run the query
```

### 4.2 Enable RLS on Students Table

```sql
-- Go to SQL Editor → New Query

-- Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Teachers can view students from their center
CREATE POLICY "Teachers can view center students"
  ON students FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can insert students in their center
CREATE POLICY "Teachers can insert center students"
  ON students FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can update students in their center
CREATE POLICY "Teachers can update center students"
  ON students FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can delete students in their center
CREATE POLICY "Teachers can delete center students"
  ON students FOR DELETE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Run the query
```

### 4.3 Enable RLS on Attendance Records Table

```sql
-- Go to SQL Editor → New Query

-- Enable RLS
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- Teachers can view attendance from their center
CREATE POLICY "Teachers can view center attendance"
  ON attendance_records FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can insert attendance for their center
CREATE POLICY "Teachers can insert center attendance"
  ON attendance_records FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can update attendance from their center
CREATE POLICY "Teachers can update center attendance"
  ON attendance_records FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Run the query
```

### 4.4 Enable RLS on Volunteer Reports Table

```sql
-- Go to SQL Editor → New Query

-- Enable RLS
ALTER TABLE volunteer_reports ENABLE ROW LEVEL SECURITY;

-- Teachers can view reports from their center
CREATE POLICY "Teachers can view center reports"
  ON volunteer_reports FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can insert reports for their center
CREATE POLICY "Teachers can insert center reports"
  ON volunteer_reports FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can update reports from their center
CREATE POLICY "Teachers can update center reports"
  ON volunteer_reports FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Run the query
```

---

## 👥 Step 5: Create Teacher Accounts

### 5.1 Create Teachers via SQL (For Testing)

```sql
-- Go to SQL Editor → New Query

-- First, create auth users
-- Note: You'll need to do this via Supabase UI or API

-- Then insert teacher records
INSERT INTO teachers (id, email, name, center_name, role) VALUES
  ('teacher-uuid-1', 'teacher1@saral.com', 'Teacher 1', 'Mumbai Central', 'teacher'),
  ('teacher-uuid-2', 'teacher2@saral.com', 'Teacher 2', 'Mumbai Central', 'teacher'),
  ('teacher-uuid-3', 'teacher3@saral.com', 'Teacher 3', 'Pune East Center', 'teacher'),
  ('admin-uuid-1', 'admin@saral.com', 'Admin', 'Mumbai Central', 'admin');

-- Run the query
```

### 5.2 Create Teachers via Supabase UI

```
1. Go to Authentication → Users
2. Click "Add user"
3. Enter email: teacher1@saral.com
4. Enter password: (auto-generated or custom)
5. Click "Create user"
6. Repeat for other teachers
7. Note the UUID for each user
```

### 5.3 Link Auth Users to Teachers Table

```sql
-- Go to SQL Editor → New Query
-- Replace UUIDs with actual user IDs from Authentication

UPDATE teachers SET id = 'actual-uuid-from-auth' WHERE email = 'teacher1@saral.com';
UPDATE teachers SET id = 'actual-uuid-from-auth' WHERE email = 'teacher2@saral.com';
UPDATE teachers SET id = 'actual-uuid-from-auth' WHERE email = 'teacher3@saral.com';

-- Run the query
```

---

## 🔑 Step 6: Update App Configuration

### 6.1 Update main.dart with Supabase Credentials

```dart
// In lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with your credentials
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT_ID.supabase.co',  // Replace with your URL
    anonKey: 'YOUR_ANON_KEY',  // Replace with your anon key
  );
  
  // ... rest of initialization
}
```

### 6.2 Get Your Credentials

```
1. Go to Supabase Dashboard
2. Click Project Settings (gear icon)
3. Click "API" in left sidebar
4. Copy:
   - Project URL (looks like: https://xxxxx.supabase.co)
   - anon key (long string starting with eyJ...)
5. Paste into main.dart
```

---

## 🧪 Step 7: Test Multi-Teacher Login

### 7.1 Test Teacher 1 Login

```
1. Run app: flutter run
2. Login with: teacher1@saral.com / password
3. Select center: "Mumbai Central"
4. Should see dashboard
5. Add a student
6. Take attendance
7. Submit volunteer report
```

### 7.2 Test Teacher 2 Login (Same Center)

```
1. Logout from Teacher 1
2. Login with: teacher2@saral.com / password
3. Select center: "Mumbai Central"
4. Click sync button
5. Should see student added by Teacher 1
6. Should see attendance from Teacher 1
7. Should see volunteer report from Teacher 1
```

### 7.3 Test Teacher 3 Login (Different Center)

```
1. Logout from Teacher 2
2. Login with: teacher3@saral.com / password
3. Select center: "Pune East Center"
4. Should NOT see data from Mumbai Central
5. Add student for Pune center
6. Teacher 1 should NOT see this student
```

---

## 📱 Step 8: Update Cloud Sync Service

### 8.1 Update cloud_sync_service.dart

The service is already configured to use Supabase. Just verify:

```dart
// In lib/services/cloud_sync_service.dart

final _supabase = Supabase.instance.client;

// All methods use _supabase to access cloud data
// No changes needed if Supabase is initialized in main.dart
```

---

## 🔄 Step 9: Test Data Sync

### 9.1 Test Student Sync

```
1. Teacher 1 adds student "Raj"
2. Teacher 1 goes offline
3. Teacher 2 clicks sync
4. Teacher 2 should see "Raj"
5. Teacher 2 adds student "Priya"
6. Teacher 1 comes online
7. Teacher 1 clicks sync
8. Teacher 1 should see "Priya"
```

### 9.2 Test Attendance Sync

```
1. Teacher 1 takes attendance
2. Teacher 2 clicks sync
3. Teacher 2 should see same attendance
4. Teacher 2 can view attendance details
```

### 9.3 Test Volunteer Report Sync

```
1. Teacher 1 submits volunteer report
2. Teacher 2 clicks sync
3. Teacher 2 should see report
4. Both can view same report details
```

---

## 🛡️ Step 10: Security Best Practices

### 10.1 Enable HTTPS Only

```
1. Go to Project Settings
2. Click "Security"
3. Enable "Enforce HTTPS"
4. Click "Save"
```

### 10.2 Set Up Backups

```
1. Go to Project Settings
2. Click "Backups"
3. Enable "Automated backups"
4. Set backup frequency to daily
5. Click "Save"
```

### 10.3 Monitor API Usage

```
1. Go to Project Settings
2. Click "API"
3. Check "Rate limiting" settings
4. Set appropriate limits for your app
```

---

## 📊 Step 11: Monitor and Debug

### 11.1 View Logs

```
1. Go to Logs in left sidebar
2. Filter by:
   - API calls
   - Authentication events
   - Database queries
3. Check for errors
```

### 11.2 Check Database

```
1. Go to Table Editor
2. Click on each table
3. Verify data is being stored correctly
4. Check for any errors
```

### 11.3 Test API Calls

```
1. Go to SQL Editor
2. Run test queries
3. Verify data retrieval works
4. Check performance
```

---

## 🚀 Step 12: Deploy to Production

### 12.1 Update Credentials for Production

```dart
// In lib/main.dart
// Use production Supabase URL and key

await Supabase.initialize(
  url: 'https://YOUR_PRODUCTION_URL.supabase.co',
  anonKey: 'YOUR_PRODUCTION_ANON_KEY',
);
```

### 12.2 Enable Production Security

```
1. Go to Project Settings
2. Enable all security features
3. Set up SSL certificate
4. Enable CORS for your domain
5. Set up rate limiting
```

### 12.3 Create Admin Account

```sql
-- Go to SQL Editor

INSERT INTO teachers (id, email, name, center_name, role) VALUES
  ('admin-uuid', 'admin@saral.com', 'Admin', 'All Centers', 'admin');
```

---

## 📋 Verification Checklist

### Before Publishing

- [ ] Supabase project created
- [ ] All tables created
- [ ] RLS policies enabled
- [ ] Teacher accounts created
- [ ] Multi-teacher login tested
- [ ] Data sync tested
- [ ] Offline mode tested
- [ ] Security settings configured
- [ ] Backups enabled
- [ ] Credentials updated in app
- [ ] Production URL configured

### After Publishing

- [ ] Monitor API usage
- [ ] Check error logs
- [ ] Verify data sync working
- [ ] Monitor performance
- [ ] Gather user feedback

---

## 🆘 Troubleshooting

### Problem: "Authentication failed"

**Solution:**
1. Check Supabase URL is correct
2. Check anon key is correct
3. Verify teacher account exists
4. Check email/password is correct

### Problem: "Permission denied" error

**Solution:**
1. Check RLS policies are enabled
2. Verify teacher is in correct center
3. Check teacher record exists in teachers table
4. Verify auth.uid() matches teacher id

### Problem: "Data not syncing"

**Solution:**
1. Check internet connection
2. Verify Supabase is online
3. Check RLS policies allow access
4. Check cloud_sync_service is called
5. Check logs for errors

### Problem: "Seeing other center's data"

**Solution:**
1. Check RLS policies are correct
2. Verify center_name filter is applied
3. Check teacher's center_name is correct
4. Verify SQL policies are enabled

---

## 📞 Support Resources

### Supabase Documentation
- https://supabase.com/docs
- https://supabase.com/docs/guides/auth
- https://supabase.com/docs/guides/database

### SARAL App Documentation
- MULTI_TEACHER_SETUP.md
- PUBLISHING_GUIDE.md
- STORAGE_OPTIMIZATION.md

---

## ✅ Summary

**Multi-Teacher Setup Complete:**
- ✅ Supabase project created
- ✅ Database tables created
- ✅ RLS policies configured
- ✅ Teacher accounts created
- ✅ App configured
- ✅ Data sync working
- ✅ Security enabled

**Ready for multi-teacher deployment!** 🎉
