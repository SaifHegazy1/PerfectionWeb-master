-- Migration: Add lecture metadata columns to session_records table
-- This migration adds columns to store lecture name and feature toggles for admin control

-- Add columns if they don't exist
ALTER TABLE session_records
ADD COLUMN IF NOT EXISTS lecture_name TEXT,
ADD COLUMN IF NOT EXISTS exam_name TEXT,
ADD COLUMN IF NOT EXISTS has_exam_grade BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS has_payment BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS has_time BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS start_time TIMESTAMP WITH TIME ZONE;

-- Create index on lecture_name for faster queries
CREATE INDEX IF NOT EXISTS idx_session_records_lecture_name ON session_records(lecture_name);

-- Update the view to include new columns
CREATE OR REPLACE VIEW session_records_view AS
SELECT 
    id,
    student_id,
    student_name,
    parent_no,
    session_number,
    group_name,
    is_general_exam,
    lecture_name,
    exam_name,
    quiz_mark,
    start_time,
    finish_time,
    has_exam_grade,
    has_payment,
    has_time,
    attendance,
    payment,
    homework_status,
    pokin,
    student_no,
    created_at,
    updated_at,
    CASE 
        WHEN homework_status IS NULL OR homework_status = 0 THEN 'completed'
        WHEN homework_status = 1 THEN 'no_hw'
        WHEN homework_status = 2 THEN 'not_completed'
        WHEN homework_status = 3 THEN 'cheated'
        ELSE 'unknown'
    END as homework_status_text
FROM session_records;
