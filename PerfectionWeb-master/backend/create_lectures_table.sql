-- Create lectures table to map unique keys to lecture names
CREATE TABLE IF NOT EXISTS lectures (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unique_key TEXT NOT NULL UNIQUE,
  lecture_name TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for quick lookup by unique_key
CREATE UNIQUE INDEX IF NOT EXISTS idx_lectures_unique_key ON lectures(unique_key);
