-- ============================================================================
-- RUN THIS IN SUPABASE SQL EDITOR NOW!
-- ============================================================================
-- This will fix your attendance corruption issue
-- 
-- IMPORTANT: The app code has been updated to use ROLL NUMBERS instead of IDs
-- This SQL script will:
-- 1. Merge duplicate attendance records
-- 2. Add unique constraint to prevent future duplicates
-- 3. Clean up corrupted data
--
-- After running this, you MUST clear local app data (uninstall/reinstall)
-- ============================================================================

-- STEP 1: See the problem (check for duplicates)
SELECT 
  date::DATE as attendance_date,
  center_name,
  COUNT(*) as how_many_duplicates,
  STRING_AGG(id::TEXT, ', ') as duplicate_ids
FROM attendance_records
GROUP BY date::DATE, center_name
HAVING COUNT(*) > 1
ORDER BY date DESC;

-- If you see rows above, you have duplicates! Continue below.
-- If no rows, skip to STEP 4.

-- ============================================================================

-- STEP 2: Merge duplicate attendance data
WITH duplicate_groups AS (
  SELECT 
    date::DATE as attendance_date,
    center_name,
    JSONB_OBJECT_AGG(key, value) as merged_attendance
  FROM attendance_records,
  LATERAL JSONB_EACH(attendance)
  GROUP BY date::DATE, center_name
  HAVING COUNT(DISTINCT id) > 1
),
first_records AS (
  SELECT DISTINCT ON (date::DATE, center_name)
    id,
    date::DATE as attendance_date,
    center_name
  FROM attendance_records
  ORDER BY date::DATE, center_name, updated_at DESC NULLS LAST, created_at DESC
)
UPDATE attendance_records ar
SET 
  attendance = dg.merged_attendance,
  updated_at = NOW()
FROM duplicate_groups dg
JOIN first_records fr ON 
  fr.attendance_date = dg.attendance_date AND 
  fr.center_name = dg.center_name
WHERE ar.id = fr.id;

-- ============================================================================

-- STEP 3: Delete the duplicate records (keep the merged one)
WITH ranked_records AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (
      PARTITION BY date::DATE, center_name 
      ORDER BY updated_at DESC NULLS LAST, created_at DESC, id DESC
    ) as rn
  FROM attendance_records
)
DELETE FROM attendance_records
WHERE id IN (
  SELECT id FROM ranked_records WHERE rn > 1
);

-- ============================================================================

-- STEP 4: Add unique constraint (prevents future duplicates)
ALTER TABLE attendance_records
DROP CONSTRAINT IF EXISTS attendance_records_date_center_unique;

ALTER TABLE attendance_records
ADD CONSTRAINT attendance_records_date_center_unique 
UNIQUE (date, center_name);

-- ============================================================================

-- STEP 5: Verify it worked (should show 0 rows)
SELECT 
  date::DATE,
  center_name,
  COUNT(*) as count
FROM attendance_records
GROUP BY date::DATE, center_name
HAVING COUNT(*) > 1;

-- If you see 0 rows above, SUCCESS! ✅

-- ============================================================================

-- STEP 6: View your clean data
SELECT 
  id,
  date::DATE as attendance_date,
  center_name,
  JSONB_OBJECT_KEYS(attendance) as student_identifiers,
  attendance,
  created_at,
  updated_at
FROM attendance_records
ORDER BY date DESC
LIMIT 20;

-- ============================================================================
-- STEP 7: Check what format your attendance is using
-- ============================================================================

-- This will show you if attendance is using IDs (old) or roll numbers (new)
SELECT 
  id,
  date::DATE,
  center_name,
  attendance,
  CASE 
    WHEN JSONB_OBJECT_KEYS(attendance) ~ '^[0-9]+$' THEN '⚠️ OLD FORMAT (using IDs)'
    ELSE '✅ NEW FORMAT (using roll numbers)'
  END as format_status
FROM attendance_records
ORDER BY date DESC
LIMIT 5;

-- ============================================================================
-- IMPORTANT NOTES:
-- ============================================================================
-- 
-- 📌 OLD FORMAT (will cause issues):
--    {"1": true, "2": false, "3": true}  ← Using numeric IDs
--
-- ✅ NEW FORMAT (correct):
--    {"R001": true, "R002": false, "R003": true}  ← Using roll numbers
--
-- If you see OLD FORMAT above, that data was saved before the code fix.
-- It will be replaced when you take new attendance after clearing local data.
--
-- ============================================================================
-- DONE! Now go to your app and:
-- ============================================================================
-- 1. Uninstall and reinstall the app (to clear corrupted local data)
--    OR add a debug button to clear attendance store
-- 2. Login and tap Sync (downloads clean data from Supabase)
-- 3. Take new attendance (will use roll numbers now)
-- 4. Save and sync
-- 5. Check this query again - should show NEW FORMAT ✅
-- ============================================================================
