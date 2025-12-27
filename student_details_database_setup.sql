-- Student Details Database Setup
-- This script creates the student_details table for storing comprehensive enrollment information

-- Create student_details table
CREATE TABLE IF NOT EXISTS public.student_details (
    student_id bigint PRIMARY KEY REFERENCES public.students(id) ON DELETE CASCADE,
    
    -- Identification
    aadhaar_id text,
    
    -- Parent/Guardian Information
    parent_guardian_name text NOT NULL DEFAULT 'Unknown',
    parent_guardian_relationship text,
    parent_guardian_phone text,
    parent_guardian_email text,
    parent_guardian_occupation text,
    
    -- Address Information
    address_line1 text,
    address_line2 text,
    city text,
    state text,
    pincode text,
    country text DEFAULT 'India',
    
    -- Medical Information
    blood_group text,
    allergies text,
    medical_conditions text,
    current_medications text,
    
    -- Disability Information
    has_disability boolean DEFAULT false,
    disability_type text,
    disability_certificate_number text,
    special_needs text,
    
    -- Emergency Contact
    emergency_contact_name text,
    emergency_contact_relationship text,
    emergency_contact_phone text,
    
    -- Academic Information
    medium_of_instruction text DEFAULT 'English',
    enrollment_date date,
    previous_school text,
    transfer_certificate_number text,
    
    -- Timestamps
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_student_details_student_id ON public.student_details(student_id);
CREATE INDEX IF NOT EXISTS idx_student_details_enrollment_date ON public.student_details(enrollment_date);

-- Enable Row Level Security (RLS)
ALTER TABLE public.student_details ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS (adjust based on your authentication setup)
-- Allow authenticated users to read all student details
CREATE POLICY "Allow authenticated users to read student details" ON public.student_details
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow authenticated users to insert student details
CREATE POLICY "Allow authenticated users to insert student details" ON public.student_details
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update student details
CREATE POLICY "Allow authenticated users to update student details" ON public.student_details
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete student details
CREATE POLICY "Allow authenticated users to delete student details" ON public.student_details
    FOR DELETE USING (auth.role() = 'authenticated');

-- Create trigger to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_student_details_updated_at 
    BEFORE UPDATE ON public.student_details 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions (adjust based on your setup)
GRANT ALL ON public.student_details TO authenticated;
GRANT ALL ON public.student_details TO service_role;

-- Comments for documentation
COMMENT ON TABLE public.student_details IS 'Comprehensive enrollment details for students';
COMMENT ON COLUMN public.student_details.student_id IS 'Foreign key reference to students table';
COMMENT ON COLUMN public.student_details.parent_guardian_name IS 'Name of parent or guardian (required field)';
COMMENT ON COLUMN public.student_details.has_disability IS 'Boolean flag indicating if student has any disability';
COMMENT ON COLUMN public.student_details.enrollment_date IS 'Date when student was enrolled';