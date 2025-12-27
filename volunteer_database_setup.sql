-- Simple Volunteer Management Database Setup
-- Note: volunteer_reports table already exists

-- 1. Create volunteers table to track volunteer attendance
CREATE TABLE IF NOT EXISTS public.volunteers (
    id bigserial PRIMARY KEY,
    name text NOT NULL,
    center_name text NOT NULL,
    attendance_count integer DEFAULT 1,
    first_report_date date NOT NULL,
    last_report_date date NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(name, center_name)
);

-- 2. Enable RLS
ALTER TABLE public.volunteers ENABLE ROW LEVEL SECURITY;

-- 3. Basic RLS policy - teachers can access volunteers from their center
CREATE POLICY "volunteers_policy" ON public.volunteers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.teachers 
            WHERE teachers.id = auth.uid() 
            AND teachers.center_name = volunteers.center_name
        )
    );

-- 4. Grant permissions
GRANT ALL ON public.volunteers TO authenticated;
GRANT ALL ON SEQUENCE volunteers_id_seq TO authenticated;

-- 5. Function for autocomplete - gets volunteers sorted by activity
CREATE OR REPLACE FUNCTION get_volunteer_suggestions(center_name_param text)
RETURNS TABLE(volunteer_name text, attendance_count integer, last_report_date date) AS $$
BEGIN
    RETURN QUERY
    SELECT v.name, v.attendance_count, v.last_report_date
    FROM public.volunteers v
    WHERE v.center_name = center_name_param
    ORDER BY v.attendance_count DESC, v.last_report_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_volunteer_suggestions(text) TO authenticated;

-- 6. Function for monthly reports - gets volunteer attendance for a specific month
CREATE OR REPLACE FUNCTION get_monthly_volunteer_report(
    center_name_param text, 
    report_month_param date DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    volunteer_name text, 
    attendance_count integer, 
    first_report_date date, 
    last_report_date date,
    days_active integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.name,
        v.attendance_count,
        v.first_report_date,
        v.last_report_date,
        (v.last_report_date - v.first_report_date + 1) as days_active
    FROM public.volunteers v
    WHERE v.center_name = center_name_param
    AND DATE_TRUNC('month', v.last_report_date) = DATE_TRUNC('month', report_month_param)
    ORDER BY v.attendance_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_monthly_volunteer_report(text, date) TO authenticated;

-- 7. Optional: Sync existing volunteer_reports data into volunteers table
-- Run this if you want to populate volunteers table with existing data
/*
INSERT INTO public.volunteers (name, center_name, attendance_count, first_report_date, last_report_date)
SELECT 
    volunteer_name,
    center_name,
    COUNT(*) as attendance_count,
    MIN(created_at::date) as first_report_date,
    MAX(created_at::date) as last_report_date
FROM public.volunteer_reports 
WHERE volunteer_name IS NOT NULL AND volunteer_name != ''
GROUP BY volunteer_name, center_name
ON CONFLICT (name, center_name) DO UPDATE SET
    attendance_count = GREATEST(volunteers.attendance_count, EXCLUDED.attendance_count),
    first_report_date = LEAST(volunteers.first_report_date, EXCLUDED.first_report_date),
    last_report_date = GREATEST(volunteers.last_report_date, EXCLUDED.last_report_date);
*/