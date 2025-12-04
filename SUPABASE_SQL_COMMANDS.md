# SARAL App - Supabase SQL Commands (Copy & Paste Ready)

## 🎯 How to Use This Guide

1. Go to Supabase Dashboard
2. Click "SQL Editor" in left sidebar
3. Click "New Query"
4. Copy the SQL command below
5. Paste into the editor
6. Click "Run"
7. Check for success message

---

## 📊 Command 1: Create Students Table

```sql
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

**Status**: ✅ Run this if students table doesn't exist

---

## 📊 Command 2: Create Attendance Records Table

```sql
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

**Status**: ✅ Run this if attendance_records table doesn't exist

---

## 📊 Command 3: Create Volunteer Reports Table

```sql
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

**Status**: ✅ Run this if volunteer_reports table doesn't exist

---

## 📊 Command 4: Create Centers Table

```sql
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
  ('Thane Branch', 'Ghodbunder, Thane')
ON CONFLICT (name) DO NOTHING;
```

**Status**: ✅ Run this if centers table doesn't exist

---

## 🔒 Command 5: Enable RLS on Teachers Table

```sql
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;

-- Teachers can view own record
CREATE POLICY IF NOT EXISTS "Teachers can view own record"
  ON teachers FOR SELECT
  USING (auth.uid() = id);

-- Teachers can update own record
CREATE POLICY IF NOT EXISTS "Teachers can update own record"
  ON teachers FOR UPDATE
  USING (auth.uid() = id);

-- Admins can view all teachers
CREATE POLICY IF NOT EXISTS "Admins can view all teachers"
  ON teachers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM teachers t
      WHERE t.id = auth.uid() AND t.role = 'admin'
    )
  );
```

**Status**: ✅ Run this to enable RLS on teachers

---

## 🔒 Command 6: Enable RLS on Students Table

```sql
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Teachers can view students from their center
CREATE POLICY IF NOT EXISTS "Teachers can view center students"
  ON students FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can insert students in their center
CREATE POLICY IF NOT EXISTS "Teachers can insert center students"
  ON students FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can update students in their center
CREATE POLICY IF NOT EXISTS "Teachers can update center students"
  ON students FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can delete students in their center
CREATE POLICY IF NOT EXISTS "Teachers can delete center students"
  ON students FOR DELETE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );
```

**Status**: ✅ Run this to enable RLS on students

---

## 🔒 Command 7: Enable RLS on Attendance Records Table

```sql
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- Teachers can view attendance from their center
CREATE POLICY IF NOT EXISTS "Teachers can view center attendance"
  ON attendance_records FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can insert attendance for their center
CREATE POLICY IF NOT EXISTS "Teachers can insert center attendance"
  ON attendance_records FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can update attendance from their center
CREATE POLICY IF NOT EXISTS "Teachers can update center attendance"
  ON attendance_records FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );
```

**Status**: ✅ Run this to enable RLS on attendance_records

---

## 🔒 Command 8: Enable RLS on Volunteer Reports Table

```sql
ALTER TABLE volunteer_reports ENABLE ROW LEVEL SECURITY;

-- Teachers can view reports from their center
CREATE POLICY IF NOT EXISTS "Teachers can view center reports"
  ON volunteer_reports FOR SELECT
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can insert reports for their center
CREATE POLICY IF NOT EXISTS "Teachers can insert center reports"
  ON volunteer_reports FOR INSERT
  WITH CHECK (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );

-- Teachers can update reports from their center
CREATE POLICY IF NOT EXISTS "Teachers can update center reports"
  ON volunteer_reports FOR UPDATE
  USING (
    center_name IN (
      SELECT center_name FROM teachers WHERE id = auth.uid()
    )
  );
```

**Status**: ✅ Run this to enable RLS on volunteer_reports

---

## 👥 Command 9: Create Teacher Records

```sql
-- IMPORTANT: Replace UUIDs with actual user IDs from Authentication
-- Get UUIDs from: Authentication → Users → Click user → Copy User ID

INSERT INTO teachers (id, email, name, center_name, role) VALUES
  ('REPLACE_WITH_UUID_1', 'teacher1@saral.com', 'Teacher 1', 'Mumbai Central', 'teacher'),
  ('REPLACE_WITH_UUID_2', 'teacher2@saral.com', 'Teacher 2', 'Mumbai Central', 'teacher'),
  ('REPLACE_WITH_UUID_3', 'teacher3@saral.com', 'Teacher 3', 'Pune East Center', 'teacher'),
  ('REPLACE_WITH_UUID_4', 'admin@saral.com', 'Admin', 'Mumbai Central', 'admin')
ON CONFLICT (id) DO NOTHING;
```

**Status**: ⚠️ Replace UUIDs before running!

---

## 🔍 Command 10: Verify Setup

```sql
-- Check all tables exist
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('teachers', 'students', 'attendance_records', 'volunteer_reports', 'centers');

-- Check RLS is enabled
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname IN ('teachers', 'students', 'attendance_records', 'volunteer_reports');

-- Check teacher records
SELECT id, email, name, center_name, role FROM teachers;

-- Check centers
SELECT * FROM centers;
```

**Status**: ✅ Run this to verify everything is set up

---

## 📋 Quick Setup Order

### Run These Commands in Order:

1. ✅ Command 1: Create Students Table
2. ✅ Command 2: Create Attendance Records Table
3. ✅ Command 3: Create Volunteer Reports Table
4. ✅ Command 4: Create Centers Table
5. ✅ Command 5: Enable RLS on Teachers
6. ✅ Command 6: Enable RLS on Students
7. ✅ Command 7: Enable RLS on Attendance Records
8. ✅ Command 8: Enable RLS on Volunteer Reports
9. ⚠️ Command 9: Create Teacher Records (after replacing UUIDs)
10. ✅ Command 10: Verify Setup

---

## 🆘 Troubleshooting Commands

### Check if Table Exists

```sql
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'students'
);
```

### Check RLS Status

```sql
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname = 'students';
```

### Check Policies

```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'students';
```

### Check Teacher Records

```sql
SELECT id, email, name, center_name, role 
FROM teachers 
ORDER BY created_at DESC;
```

### Check Data in Students Table

```sql
SELECT id, name, roll_no, class_batch, center_name 
FROM students 
LIMIT 10;
```

### Delete All Data (Reset)

```sql
-- WARNING: This deletes all data!
DELETE FROM volunteer_reports;
DELETE FROM attendance_records;
DELETE FROM students;
DELETE FROM teachers;
DELETE FROM centers;
```

---

## 🎯 Common Errors & Solutions

### Error: "relation already exists"

```
Cause: Table already created
Solution: Skip that command or use CREATE TABLE IF NOT EXISTS
Status: Already included in commands above ✅
```

### Error: "permission denied"

```
Cause: RLS policy issue
Solution: Check RLS is enabled and policies are created
Command: Run Command 10 to verify
```

### Error: "foreign key violation"

```
Cause: UUID doesn't exist in teachers table
Solution: Make sure teacher record exists before referencing
Command: Run Command 9 with correct UUIDs
```

### Error: "duplicate key value"

```
Cause: Record already exists
Solution: Use ON CONFLICT DO NOTHING (already included)
Status: Already handled in commands ✅
```

---

## ✅ Success Indicators

### After Running All Commands:

```
✅ All 5 tables exist
✅ RLS enabled on all tables
✅ Policies created for all tables
✅ Teacher records inserted
✅ Centers populated
✅ No errors in logs
```

---

## 📞 Need Help?

### If a Command Fails:

1. Read the error message carefully
2. Check the table name is correct
3. Check the column names are correct
4. Check UUIDs are valid
5. Try the verification command (Command 10)

### Common Issues:

- **"already exists"** → Table already created, skip it
- **"permission denied"** → RLS issue, check policies
- **"foreign key"** → UUID issue, check teacher records
- **"duplicate key"** → Record exists, use ON CONFLICT

---

## 🚀 You're Ready!

All commands are ready to copy and paste. Just:

1. Go to Supabase SQL Editor
2. Copy each command
3. Paste and run
4. Check for success
5. Move to next command

**That's it! Multi-teacher setup complete!** ✅
