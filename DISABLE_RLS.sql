-- ============================================================================
-- DISABLE RLS TEMPORARILY
-- ============================================================================
-- This disables RLS policies to allow the app to work while we debug
-- In production, you should have proper RLS policies

ALTER TABLE students DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE teachers DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname IN ('teachers', 'students', 'attendance_records', 'volunteer_reports');
