-- ============================================================================
-- AUDIT TRAIL & CONFLICT RESOLUTION SETUP
-- ============================================================================
-- Run this in Supabase SQL Editor to enable audit trail and conflict detection
-- ============================================================================

-- STEP 1: Add audit fields to existing tables
-- ============================================================================

-- Add audit fields to students table
ALTER TABLE students
ADD COLUMN IF NOT EXISTS created_by TEXT,
ADD COLUMN IF NOT EXISTS updated_by TEXT,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add audit fields to attendance_records table
ALTER TABLE attendance_records
ADD COLUMN IF NOT EXISTS created_by TEXT,
ADD COLUMN IF NOT EXISTS updated_by TEXT;
-- created_at and updated_at might already exist, so we skip them if they do

-- Add audit fields to volunteer_reports table  
ALTER TABLE volunteer_reports
ADD COLUMN IF NOT EXISTS created_by TEXT,
ADD COLUMN IF NOT EXISTS updated_by TEXT;
-- created_at might already exist

-- ============================================================================
-- STEP 2: Create audit_log table
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')),
  user_email TEXT NOT NULL,
  user_name TEXT,
  center_name TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  old_data JSONB,
  new_data JSONB,
  changes JSONB,
  conflict_detected BOOLEAN DEFAULT FALSE,
  conflict_resolution TEXT,
  device_info TEXT,
  app_version TEXT,
  notes TEXT
);

-- Create indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_email);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_center ON audit_log(center_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_conflicts ON audit_log(conflict_detected) WHERE conflict_detected = TRUE;

-- ============================================================================
-- STEP 3: Create function to calculate JSON differences
-- ============================================================================

CREATE OR REPLACE FUNCTION jsonb_diff(old_data JSONB, new_data JSONB)
RETURNS JSONB AS $$
DECLARE
  result JSONB := '{}'::JSONB;
  key TEXT;
BEGIN
  -- Find changed keys
  FOR key IN SELECT jsonb_object_keys(new_data)
  LOOP
    IF old_data->key IS DISTINCT FROM new_data->key THEN
      result := result || jsonb_build_object(
        key, jsonb_build_object(
          'old', old_data->key,
          'new', new_data->key
        )
      );
    END IF;
  END LOOP;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 4: Create trigger function for automatic audit logging
-- ============================================================================

CREATE OR REPLACE FUNCTION log_audit_trail()
RETURNS TRIGGER AS $$
DECLARE
  user_email TEXT;
  user_name TEXT;
  center TEXT;
BEGIN
  -- Extract user info from the record
  IF (TG_OP = 'INSERT') THEN
    user_email := COALESCE(NEW.created_by, 'system');
    user_name := user_email;
    center := NEW.center_name;
    
    INSERT INTO audit_log (
      table_name, record_id, operation, 
      user_email, user_name, center_name,
      new_data, timestamp
    ) VALUES (
      TG_TABLE_NAME, 
      NEW.id::TEXT, 
      'CREATE',
      user_email,
      user_name,
      center,
      row_to_json(NEW)::JSONB,
      NOW()
    );
    RETURN NEW;
    
  ELSIF (TG_OP = 'UPDATE') THEN
    user_email := COALESCE(NEW.updated_by, 'system');
    user_name := user_email;
    center := NEW.center_name;
    
    INSERT INTO audit_log (
      table_name, record_id, operation,
      user_email, user_name, center_name,
      old_data, new_data, changes, timestamp
    ) VALUES (
      TG_TABLE_NAME, 
      NEW.id::TEXT, 
      'UPDATE',
      user_email,
      user_name,
      center,
      row_to_json(OLD)::JSONB,
      row_to_json(NEW)::JSONB,
      jsonb_diff(row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB),
      NOW()
    );
    RETURN NEW;
    
  ELSIF (TG_OP = 'DELETE') THEN
    user_email := COALESCE(OLD.updated_by, OLD.created_by, 'system');
    user_name := user_email;
    center := OLD.center_name;
    
    INSERT INTO audit_log (
      table_name, record_id, operation,
      user_email, user_name, center_name,
      old_data, timestamp
    ) VALUES (
      TG_TABLE_NAME, 
      OLD.id::TEXT, 
      'DELETE',
      user_email,
      user_name,
      center,
      row_to_json(OLD)::JSONB,
      NOW()
    );
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: Apply triggers to tables
-- ============================================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS students_audit_trigger ON students;
DROP TRIGGER IF EXISTS attendance_audit_trigger ON attendance_records;
DROP TRIGGER IF EXISTS volunteer_reports_audit_trigger ON volunteer_reports;

-- Create new triggers
CREATE TRIGGER students_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER attendance_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON attendance_records
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER volunteer_reports_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON volunteer_reports
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

-- ============================================================================
-- STEP 6: Create helper functions for querying audit log
-- ============================================================================

-- Function to get audit history for a specific record
CREATE OR REPLACE FUNCTION get_audit_history(
  p_table_name TEXT,
  p_record_id TEXT
)
RETURNS TABLE (
  log_timestamp TIMESTAMPTZ,
  operation TEXT,
  user_email TEXT,
  changes JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.timestamp,
    a.operation,
    a.user_email,
    a.changes
  FROM audit_log a
  WHERE a.table_name = p_table_name
    AND a.record_id = p_record_id
  ORDER BY a.timestamp DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get recent changes by user
CREATE OR REPLACE FUNCTION get_user_activity(
  p_user_email TEXT,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  log_timestamp TIMESTAMPTZ,
  table_name TEXT,
  record_id TEXT,
  operation TEXT,
  changes JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.timestamp,
    a.table_name,
    a.record_id,
    a.operation,
    a.changes
  FROM audit_log a
  WHERE a.user_email = p_user_email
  ORDER BY a.timestamp DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to get conflicts
CREATE OR REPLACE FUNCTION get_conflicts(
  p_center_name TEXT DEFAULT NULL
)
RETURNS TABLE (
  log_timestamp TIMESTAMPTZ,
  table_name TEXT,
  record_id TEXT,
  user_email TEXT,
  old_data JSONB,
  new_data JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.timestamp,
    a.table_name,
    a.record_id,
    a.user_email,
    a.old_data,
    a.new_data
  FROM audit_log a
  WHERE a.conflict_detected = TRUE
    AND (p_center_name IS NULL OR a.center_name = p_center_name)
  ORDER BY a.timestamp DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 7: Enable RLS (Row Level Security) for audit_log
-- ============================================================================

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view audit logs for their center
CREATE POLICY audit_log_select_policy ON audit_log
FOR SELECT
USING (
  center_name IN (
    SELECT center_name FROM teachers WHERE email = auth.email()
  )
);

-- Policy: System can insert audit logs
CREATE POLICY audit_log_insert_policy ON audit_log
FOR INSERT
WITH CHECK (true);

-- ============================================================================
-- STEP 8: Verification queries
-- ============================================================================

-- Check if audit fields were added
SELECT 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'students' 
  AND column_name IN ('created_by', 'updated_by', 'created_at', 'updated_at');

-- Check if audit_log table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'audit_log'
) AS audit_log_exists;

-- Check if triggers exist
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table 
FROM information_schema.triggers 
WHERE trigger_name LIKE '%audit_trigger%';

-- ============================================================================
-- STEP 9: Test the audit trail
-- ============================================================================

-- Insert a test record (will be logged)
-- INSERT INTO students (name, roll_no, class_batch, center_name, created_by)
-- VALUES ('Test Student', 'TEST001', 'Test Class', 'Test Center', 'test@example.com');

-- View the audit log
SELECT 
  id,
  table_name,
  operation,
  user_email,
  timestamp,
  changes
FROM audit_log
ORDER BY timestamp DESC
LIMIT 10;

-- ============================================================================
-- DONE! Audit trail is now active
-- ============================================================================

SELECT 'Audit trail setup complete!' AS status;
