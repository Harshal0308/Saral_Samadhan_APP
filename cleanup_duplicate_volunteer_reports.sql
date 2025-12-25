-- Cleanup script for duplicate volunteer reports in Supabase
-- Run this in the Supabase SQL Editor

-- Step 1: View all reports with their dates (for verification)
SELECT 
    id,
    volunteer_name,
    center_name,
    created_at,
    TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as formatted_date
FROM volunteer_reports
ORDER BY created_at DESC;

-- Step 2: Identify invalid reports (before year 2000 or NULL created_at)
SELECT 
    id,
    volunteer_name,
    center_name,
    created_at
FROM volunteer_reports
WHERE created_at < '2000-01-01' OR created_at IS NULL;

-- Step 3: Delete invalid reports (before year 2000)
DELETE FROM volunteer_reports
WHERE created_at < '2000-01-01' OR created_at IS NULL;

-- Step 4: View duplicates (for verification)
SELECT 
    created_at, 
    center_name, 
    volunteer_name,
    COUNT(*) as duplicate_count
FROM volunteer_reports
GROUP BY created_at, center_name, volunteer_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 5: Delete duplicates, keeping only the first occurrence
-- This uses a CTE to identify duplicates and delete all but the one with the lowest ID
WITH duplicates AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (
            PARTITION BY created_at, center_name 
            ORDER BY id ASC
        ) as row_num
    FROM volunteer_reports
)
DELETE FROM volunteer_reports
WHERE id IN (
    SELECT id 
    FROM duplicates 
    WHERE row_num > 1
);

-- Step 6: Add a unique constraint to prevent future duplicates
-- This ensures that no two reports can have the same created_at and center_name
ALTER TABLE volunteer_reports
ADD CONSTRAINT volunteer_reports_unique_created_at_center 
UNIQUE (created_at, center_name);

-- Step 7: Verify cleanup
SELECT 
    COUNT(*) as total_reports,
    COUNT(DISTINCT created_at) as unique_reports,
    MIN(created_at) as oldest_report,
    MAX(created_at) as newest_report
FROM volunteer_reports;

-- Step 8: Check if any duplicates remain
SELECT 
    created_at, 
    center_name, 
    volunteer_name,
    COUNT(*) as duplicate_count
FROM volunteer_reports
GROUP BY created_at, center_name, volunteer_name
HAVING COUNT(*) > 1;

-- Step 9: View final clean data
SELECT 
    id,
    volunteer_name,
    center_name,
    TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as date,
    class_batch
FROM volunteer_reports
ORDER BY created_at DESC
LIMIT 20;
