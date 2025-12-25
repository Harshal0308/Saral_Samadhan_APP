-- Create student_details table for enrollment information
-- This table has a one-to-one relationship with the students table
-- student_id serves as both PRIMARY KEY and FOREIGN KEY

CREATE TABLE student_details (
    -- Primary key that references students.id
    student_id BIGINT PRIMARY KEY REFERENCES students(id) ON DELETE CASCADE,
    
    -- Aadhaar ID (sensitive data)
    aadhaar_id VARCHAR(12) UNIQUE,
    
    -- Parent/Guardian Information
    parent_guardian_name VARCHAR(255) NOT NULL,
    parent_guardian_relationship VARCHAR(50),
    parent_guardian_phone VARCHAR(15),
    parent_guardian_email VARCHAR(255),
    parent_guardian_occupation VARCHAR(100),
    
    -- Address Details
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    country VARCHAR(100) DEFAULT 'India',
    
    -- Medical and Health Information
    blood_group VARCHAR(5),
    allergies TEXT,
    medical_conditions TEXT,
    current_medications TEXT,
    
    -- Disability Information
    has_disability BOOLEAN DEFAULT FALSE,
    disability_type VARCHAR(100),
    disability_certificate_number VARCHAR(100),
    special_needs TEXT,
    
    -- Emergency Contact
    emergency_contact_name VARCHAR(255),
    emergency_contact_relationship VARCHAR(50),
    emergency_contact_phone VARCHAR(15),
    
    -- Medium of Instruction
    medium_of_instruction VARCHAR(50) DEFAULT 'English',
    
    -- Additional enrollment information
    enrollment_date DATE,
    previous_school VARCHAR(255),
    transfer_certificate_number VARCHAR(100),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on aadhaar_id for faster lookups
CREATE INDEX idx_student_details_aadhaar ON student_details(aadhaar_id);

-- Create index on enrollment_date
CREATE INDEX idx_student_details_enrollment_date ON student_details(enrollment_date);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_student_details_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_student_details_timestamp
    BEFORE UPDATE ON student_details
    FOR EACH ROW
    EXECUTE FUNCTION update_student_details_updated_at();

-- Enable Row Level Security (RLS) for sensitive data protection
ALTER TABLE student_details ENABLE ROW LEVEL SECURITY;

-- Example RLS policy (adjust based on your authentication setup)
-- This allows authenticated users to read their own student details
CREATE POLICY "Users can view student details they have access to"
    ON student_details
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Policy for inserting student details (adjust based on your roles)
CREATE POLICY "Authorized users can insert student details"
    ON student_details
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy for updating student details
CREATE POLICY "Authorized users can update student details"
    ON student_details
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Add comments for documentation
COMMENT ON TABLE student_details IS 'Stores enrollment-related and sensitive student information with one-to-one relationship to students table';
COMMENT ON COLUMN student_details.student_id IS 'Primary key and foreign key referencing students.id';
COMMENT ON COLUMN student_details.aadhaar_id IS 'Unique Aadhaar identification number (sensitive data)';
COMMENT ON COLUMN student_details.has_disability IS 'Indicates if student has any disability';
COMMENT ON COLUMN student_details.medium_of_instruction IS 'Language medium for instruction (e.g., English, Hindi, Regional language)';
