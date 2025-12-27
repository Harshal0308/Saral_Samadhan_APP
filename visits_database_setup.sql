-- Visits Database Setup
-- Run this to add visit tracking functionality

-- 1. Create visits table
CREATE TABLE IF NOT EXISTS public.visits (
    id bigserial PRIMARY KEY,
    name text NOT NULL,
    contact text NOT NULL,
    purpose text NOT NULL,
    visit_date timestamp with time zone NOT NULL,
    timestamp timestamp with time zone DEFAULT now(),
    center_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;

-- 3. RLS policy - teachers can access visits from their center
CREATE POLICY "visits_policy" ON public.visits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.teachers 
            WHERE teachers.id = auth.uid() 
            AND teachers.center_name = visits.center_name
        )
    );

-- 4. Grant permissions
GRANT ALL ON public.visits TO authenticated;
GRANT ALL ON SEQUENCE visits_id_seq TO authenticated;

-- 5. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_visits_center_name ON public.visits(center_name);
CREATE INDEX IF NOT EXISTS idx_visits_visit_date ON public.visits(visit_date DESC);