# SARAL App - Working with Existing Supabase Tables

## ✅ Good News!

The "teachers" table already exists in your Supabase database. This means you've already started the setup.

---

## 🔍 Step 1: Check What Tables Exist

### 1.1 View All Tables

```
1. Go to Supabase Dashboard
2. Click "Table Editor" in left sidebar
3. You should see existing tables:
   - teachers (already exists ✅)
   - students (check if exists)
   - attendance_records (check if exists)
   - volunteer_reports (check if exists)
   - centers (check if exists)
```

### 1.2 Check Table Structure

```
1. Click on "teachers" table
2. View columns:
   - id (UUID)
   - email (TEXT)
   - name (TEXT)
   - phone_number (TEXT)
   - center_name (TEXT)
   - role (TEXT)
   - is_active (BOOLEAN)
   - created_at (TIMESTAMP)
   - updated_at (TIMESTAMP)
```

---

## 📊 Step 2: Create Missing Tables

### 2.1 Check if Students Table Exists

```
1. Look in Table Editor
2. If "students" table exists → Skip to Step 2.2
3. If NOT exists → Run this SQL:
```

```sql
-- Go to SQL Editor → New Query
-- Only run if students table doesn't exist

CREATE TABLE IF NOT EXISTS students (
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

CREATE INDEX IF NOT EXISTS idx_students_center ON students(center_name);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(class_batch);
CREATE INDEX IF NOT EXISTS idx_students_roll ON students(roll_no);
```

### 2.2 Check if Attendance Records Table Exists

```
1. Look in Table Editor
2. If "attendance_records" table exists → Skip to Step 2.3
3. If NOT exists → Run this SQL:
```

```sql
-- Go to SQL Editor → New Query
-- Only run if attendance_records table doesn't exist

CREATE TABLE IF NOT EXISTS attendance_records (
  id BIGSERIAL PRIMARY KEY,
  date DATE NOT NULL,
  center_name TEXT NOT NULL,
  attendance JSONB NOT NULL,
  created_by UUID REFERENCES teachers(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attendance_center ON attendance_records(center_name);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_attendance_center_date ON attendance_records(center_name, date);
```

### 2.3 Check if Volunteer Reports Table Exists

```
1. Look in Table Editor
2. If "volunteer_reports" table exists → Skip to Step 2.4
3. If NOT exists → Run this SQL:
```

```sql
-- Go to SQL Editor → New Query
-- Only run if volunteer_reports table doesn't exist

CREATE TABLE IF NOT EXISTS volunteer_reports (
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

CREATE INDEX IF NOT EXISTS idx_reports_center ON volunteer_reports(center_name);
CREATE INDEX IF NOT EXISTS idx_reports_volunteer ON volunteer_reports(volunteer_name);
CREATE INDEX IF NOT EXISTS idx_reports_date ON volunteer_reports(created_at);
```

### 2.4 Check if Centers Table Exists

```
1. Look in Table Editor
2. If "centers" table exists → Skip to Step 3
3. If NOT exists → Run this SQL:
```

```sql
-- Go to SQL Editor → New Query
-- Only run if centers table doesn't exist

CREATE TABLE IF NOT EXISTS centers (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  location TEXT,
  admin_email TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO centers (name, location) VALUES
  ('Mumbai Central', 'Dadar, Mumbai'),
  ('Pune East Center', 'Kothrud, Pune'),
  ('Nashik Hub', 'College Road, Nashik'),
  ('Nagpur Center', 'Sitabuldi, Nagpur'),
  ('Thane Branch', 'Ghodbunder, Thane');
```

---

## 🔒 Step 3: Enable Row Level Security (RLS)

### 3.1 Check if RLS is Enabled

```
1. Go to Table Editor
2. Click on "teachers" table
3. Look for "RLS" toggle in top right
4. If toggle is OFF (gray) → Enable it
5. If toggle is ON (blue) → Already enabled ✅
```

### 3.2 Enable RLS on All Tables

```
1. For each table (teachers, students, attendance_records, volunteer_reports):
   a. Click on table name
   b. Click "RLS" toggle in top right
   c. Toggle should turn blue (ON)
   d. Click "Enable" if prompted
```

### 3.3 Create RLS Policies for Teachers Table

```sql
-- Go to SQL Editor → New Query

-- Check if policies exist first
-- If they don't, run these:

CREATE POLICY "Teachers can view own record"
  ON teachers FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Teachers can update own record"
  ON teachers FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all teachers"
  ON teachers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM teachers t
      WHERE t.id = auth.uid() AND t.role = 'admin'
    )
  );
```

### 3.4 Create RLS Policies for Students Table

```sql
-- Go to SQL Editor → New Query

CREATE POLICY "Teachers can view center students"
  ON students FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can insert center students"
  ON students FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can update center students"
  ON students FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can delete center students"
  ON students FOR DELETE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );
```

### 3.5 Create RLS Policies for Attendance Records Table

```sql
-- Go to SQL Editor → New Query

CREATE POLICY "Teachers can view center attendance"
  ON attendance_records FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can insert center attendance"
  ON attendance_records FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can update center attendance"
  ON attendance_records FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );
```

### 3.6 Create RLS Policies for Volunteer Reports Table

```sql
-- Go to SQL Editor → New Query

CREATE POLICY "Teachers can view center reports"
  ON volunteer_reports FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can insert center reports"
  ON volunteer_reports FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can update center reports"
  ON volunteer_reports FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );
```

---

## 👥 Step 4: Create Teacher Accounts

### 4.1 Create Auth Users

```
1. Go to Authentication → Users
2. Click "Add user"
3. Enter email: teacher1@saral.com
4. Enter password: (auto-generated)
5. Click "Create user"
6. Note the UUID (copy it)
7. Repeat for other teachers
```

### 4.2 Create Teacher Records

```sql
-- Go to SQL Editor → New Query
-- Replace UUIDs with actual user IDs from Authentication

INSERT INTO teachers (id, email, name, center_name, role) VALUES
  ('PASTE_UUID_HERE', 'teacher1@saral.com', 'Teacher 1', 'Mumbai Central', 'teacher'),
  ('PASTE_UUID_HERE', 'teacher2@saral.com', 'Teacher 2', 'Mumbai Central', 'teacher'),
  ('PASTE_UUID_HERE', 'teacher3@saral.com', 'Teacher 3', 'Pune East Center', 'teacher'),
  ('PASTE_UUID_HERE', 'admin@saral.com', 'Admin', 'Mumbai Central', 'admin');
```

### 4.3 How to Get UUIDs

```
1. Go to Authentication → Users
2. For each user, click on the user row
3. Copy the "User ID" (UUID)
4. Paste into the SQL query above
5. Replace PASTE_UUID_HERE with actual UUID
6. Run the query
```

---

## 🔑 Step 5: Update App with Supabase Credentials

### 5.1 Get Your Credentials

```
1. Go to Supabase Dashboard
2. Click Project Settings (gear icon)
3. Click "API" in left sidebar
4. Copy:
   - Project URL (looks like: https://xxxxx.supabase.co)
   - anon key (long string starting with eyJ...)
```

### 5.2 Update main.dart

```dart
// In lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with YOUR credentials
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT_ID.supabase.co',  // REPLACE THIS
    anonKey: 'YOUR_ANON_KEY',  // REPLACE THIS
  );
  
  // ... rest of code
}
```

### 5.3 Example

```dart
// Example (replace with your actual values):
await Supabase.initialize(
  url: 'https://abcdefgh.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);
```

---

## 🧪 Step 6: Test Multi-Teacher Login

### 6.1 Test Teacher 1

```
1. Run app: flutter run
2. Login with: teacher1@saral.com / password
3. Select center: "Mumbai Central"
4. Should see dashboard ✅
5. Add a student
6. Take attendance
7. Submit volunteer report
```

### 6.2 Test Teacher 2 (Same Center)

```
1. Logout from Teacher 1
2. Login with: teacher2@saral.com / password
3. Select center: "Mumbai Central"
4. Click sync button
5. Should see student from Teacher 1 ✅
6. Should see attendance from Teacher 1 ✅
7. Should see volunteer report from Teacher 1 ✅
```

### 6.3 Test Teacher 3 (Different Center)

```
1. Logout from Teacher 2
2. Login with: teacher3@saral.com / password
3. Select center: "Pune East Center"
4. Should NOT see data from Mumbai Central ✅
5. Add student for Pune center
6. Teacher 1 should NOT see this student ✅
```

---

## ✅ Verification Checklist

### Tables
- [ ] teachers table exists
- [ ] students table exists
- [ ] attendance_records table exists
- [ ] volunteer_reports table exists
- [ ] centers table exists

### RLS
- [ ] RLS enabled on all tables
- [ ] Policies created for teachers table
- [ ] Policies created for students table
- [ ] Policies created for attendance_records table
- [ ] Policies created for volunteer_reports table

### Teachers
- [ ] Auth users created
- [ ] Teacher records created in database
- [ ] UUIDs match between auth and database

### App
- [ ] Supabase URL updated in main.dart
- [ ] Supabase anon key updated in main.dart
- [ ] App compiles without errors
- [ ] Multi-teacher login works
- [ ] Data sync works

---

## 🆘 Troubleshooting

### Problem: "Relation already exists"

**Solution:**
- Table already created ✅
- Skip that CREATE TABLE step
- Use CREATE TABLE IF NOT EXISTS instead

### Problem: "Permission denied"

**Solution:**
1. Check RLS policies are created
2. Verify teacher record exists in database
3. Check UUID matches between auth and database
4. Verify center_name is correct

### Problem: "Data not syncing"

**Solution:**
1. Check internet connection
2. Verify RLS policies allow access
3. Check cloud_sync_service is called
4. Check logs for errors

### Problem: "Can't see other teacher's data"

**Solution:**
1. Verify both teachers are in same center
2. Check RLS policies are correct
3. Click sync button to refresh
4. Check center_name matches exactly

---

## 📋 Quick Commands

### Check Table Exists

```sql
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'teachers'
);
```

### Check RLS Enabled

```sql
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname IN ('teachers', 'students', 'attendance_records', 'volunteer_reports');
```

### View All Policies

```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('teachers', 'students', 'attendance_records', 'volunteer_reports');
```

### Check Teacher Records

```sql
SELECT id, email, name, center_name, role 
FROM teachers;
```

---

## 🎯 Next Steps

1. ✅ Verify all tables exist
2. ✅ Enable RLS on all tables
3. ✅ Create RLS policies
4. ✅ Create teacher accounts
5. ✅ Update app credentials
6. ✅ Test multi-teacher login
7. ✅ Test data sync
8. ✅ Deploy to production

---

## 📞 Support

### If You Get Errors

1. Check the error message carefully
2. Look in Troubleshooting section
3. Check Supabase logs for details
4. Verify table/policy names match exactly
5. Check UUIDs are correct

### Common Issues

- **"relation already exists"** → Table already created, skip that step
- **"permission denied"** → RLS policy issue, check policies
- **"foreign key violation"** → UUID doesn't match, check teacher records
- **"data not found"** → RLS blocking access, check policies

---

**You're on the right track! The teachers table already exists.** ✅

**Follow the steps above to complete the setup.** 🚀
