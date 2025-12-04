-- ============================================================================
-- SAMADHAN APP - COMPLETE SUPABASE SETUP
-- ============================================================================
-- This SQL file sets up the complete database for Samadhan app with:
-- - Multi-teacher authentication
-- - Center-based data segregation
-- - Offline sync support
-- - Row Level Security (RLS)
-- ============================================================================

-- ============================================================================
-- 1. CREATE TEACHERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  phone_number TEXT,
  center_name TEXT NOT NULL,
  role TEXT DEFAULT 'teacher',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teachers_center ON teachers(center_name);
CREATE INDEX IF NOT EXISTS idx_teachers_email ON teachers(email);

-- ============================================================================
-- 2. CREATE CENTERS TABLE
-- ============================================================================

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

-- ============================================================================
-- 3. CREATE STUDENTS TABLE
-- ============================================================================

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

-- ============================================================================
-- 4. CREATE ATTENDANCE RECORDS TABLE
-- ============================================================================

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

-- ============================================================================
-- 5. CREATE VOLUNTEER REPORTS TABLE
-- ============================================================================

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

-- ============================================================================
-- 6. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_reports ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 7. DROP EXISTING POLICIES (if any)
-- ============================================================================

DROP POLICY IF EXISTS "Teachers can view own record" ON teachers;
DROP POLICY IF EXISTS "Teachers can update own record" ON teachers;
DROP POLICY IF EXISTS "Admins can view all teachers" ON teachers;
DROP POLICY IF EXISTS "Teachers can view center students" ON students;
DROP POLICY IF EXISTS "Teachers can insert center students" ON students;
DROP POLICY IF EXISTS "Teachers can update center students" ON students;
DROP POLICY IF EXISTS "Teachers can delete center students" ON students;
DROP POLICY IF EXISTS "Teachers can view center attendance" ON attendance_records;
DROP POLICY IF EXISTS "Teachers can insert center attendance" ON attendance_records;
DROP POLICY IF EXISTS "Teachers can update center attendance" ON attendance_records;
DROP POLICY IF EXISTS "Teachers can view center reports" ON volunteer_reports;
DROP POLICY IF EXISTS "Teachers can insert center reports" ON volunteer_reports;
DROP POLICY IF EXISTS "Teachers can update center reports" ON volunteer_reports;

-- ============================================================================
-- 8. CREATE RLS POLICIES FOR TEACHERS TABLE
-- ============================================================================

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

-- ============================================================================
-- 9. CREATE RLS POLICIES FOR STUDENTS TABLE
-- ============================================================================

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

-- ============================================================================
-- 10. CREATE RLS POLICIES FOR ATTENDANCE RECORDS TABLE
-- ============================================================================

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

-- ============================================================================
-- 11. CREATE RLS POLICIES FOR VOLUNTEER REPORTS TABLE
-- ============================================================================

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

-- ============================================================================
-- 12. VERIFICATION QUERIES
-- ============================================================================

SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('teachers', 'students', 'attendance_records', 'volunteer_reports', 'centers');

SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname IN ('teachers', 'students', 'attendance_records', 'volunteer_reports');

SELECT * FROM centers;
