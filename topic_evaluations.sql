
-- Topic Evaluations Table
-- Stores individual student evaluations for specific topics taught by volunteers

CREATE TABLE IF NOT EXISTS topic_evaluations (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    student_id BIGINT REFERENCES students(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    topic TEXT NOT NULL,
    evaluation TEXT NOT NULL CHECK (evaluation IN ('good', 'average', 'poor')),
    evaluated_by TEXT NOT NULL, -- Volunteer name
    evaluated_on TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_topic_evaluations_student_id ON topic_evaluations(student_id);
CREATE INDEX IF NOT EXISTS idx_topic_evaluations_subject_topic ON topic_evaluations(subject, topic);
CREATE INDEX IF NOT EXISTS idx_topic_evaluations_evaluated_on ON topic_evaluations(evaluated_on DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_topic_evaluations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_topic_evaluations_updated_at_trigger
    BEFORE UPDATE ON topic_evaluations
    FOR EACH ROW
    EXECUTE FUNCTION update_topic_evaluations_updated_at();

-- Sample queries for the application

-- Get all evaluations for a specific student
-- SELECT * FROM topic_evaluations WHERE student_id = ? ORDER BY evaluated_on DESC;

-- Get evaluations for a specific student and subject
-- SELECT * FROM topic_evaluations WHERE student_id = ? AND subject = ? ORDER BY evaluated_on DESC;

-- Get latest evaluation for a specific student and topic
-- SELECT * FROM topic_evaluations
-- WHERE student_id = ? AND subject = ? AND topic = ?
-- ORDER BY evaluated_on DESC LIMIT 1;

-- Get evaluation statistics for a topic across all students
-- SELECT evaluation, COUNT(*) as count
-- FROM topic_evaluations
-- WHERE subject = ? AND topic = ?
-- GROUP BY evaluation;

-- Get all evaluations by a specific volunteer
-- SELECT * FROM topic_evaluations WHERE evaluated_by = ? ORDER BY evaluated_on DESC;

-- Get evaluations for a center (assuming students table has center_id)
-- SELECT te.* FROM topic_evaluations te
-- JOIN students s ON te.student_id = s.id
-- WHERE s.center_id = ?
-- ORDER BY te.evaluated_on DESC;
