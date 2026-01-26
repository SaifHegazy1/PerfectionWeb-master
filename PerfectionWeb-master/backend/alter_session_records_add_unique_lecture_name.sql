-- Migration: Add lecture_name to session_records uniqueness key
-- File: backend/alter_session_records_add_unique_lecture_name.sql
-- Date: 2025-12-20
-- PURPOSE: Safely add lecture_name into the uniqueness constraint/index for session_records.
-- IMPORTANT: Review and run these steps in order. Some commands (CREATE INDEX CONCURRENTLY) must be run outside a transaction.

-- =========================
-- 1) Create a backup of session_records (recommended)
-- Run inside a transaction or via your SQL console
BEGIN;
CREATE TABLE IF NOT EXISTS session_records_backup AS TABLE public.session_records;
COMMIT;

-- =========================
-- 2) Inspect existing unique constraints / indexes on session_records
-- Run and note the constraint/index name so you can drop it later if needed.
-- Unique constraints
SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.session_records'::regclass
  AND contype = 'u';

-- Unique indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'session_records' AND indexdef ILIKE '%UNIQUE%';

-- =========================
-- 3) Check for duplicates under the NEW key (student_id, session_number, group_name, is_general_exam, lecture_name)
SELECT student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name,'') AS lecture_name, COUNT(*) AS cnt
FROM public.session_records
GROUP BY student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name,'')
HAVING COUNT(*) > 1
LIMIT 100;

-- If the query above returns rows, you MUST resolve duplicates before creating the unique index.

-- =========================
-- 4) Two deduplication options. PICK ONE depending on your retention rule.
-- Option A (recommended): Keep the newest row per key using `created_at` (if that column exists).
-- Run only if you have a `created_at` timestamp column and want to keep the latest row.
WITH duplicates AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name,'')
           ORDER BY created_at DESC, id DESC
         ) AS rn
  FROM public.session_records
)
DELETE FROM public.session_records
WHERE id IN (SELECT id FROM duplicates WHERE rn > 1);

-- Option B: Keep the row with the smallest id (if you prefer deterministic oldest retention)
WITH duplicates AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name,'')
           ORDER BY id ASC
         ) AS rn
  FROM public.session_records
)
DELETE FROM public.session_records
WHERE id IN (SELECT id FROM duplicates WHERE rn > 1);

-- NOTE: Always verify results of the dedupe (re-run the duplicates-check query in step 3).

-- =========================
-- 5) Create the new UNIQUE index including lecture_name
-- IMPORTANT: `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block. Run this line by itself in your SQL console.
-- Recommended command (treat NULL lecture_name as empty string so NULLs don't bypass uniqueness):

CREATE UNIQUE INDEX CONCURRENTLY idx_session_records_unique_student_session_group_exam_lecture
ON public.session_records (student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name, ''));

-- Alternative (if you are okay with brief locking window and cannot use CONCURRENTLY in your environment):
-- CREATE UNIQUE INDEX idx_session_records_unique_student_session_group_exam_lecture
-- ON public.session_records (student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name, ''));

-- =========================
-- 6) Drop the old unique constraint or index (run only after verifying the new index exists and works)
-- Replace old_constraint_name / old_index_name with the name you discovered in step 2.
-- Example for constraint:
-- ALTER TABLE public.session_records DROP CONSTRAINT IF EXISTS old_constraint_name;
-- Example for index:
-- DROP INDEX IF EXISTS old_index_name;

-- =========================
-- 7) Verification
SELECT student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name,'') AS lecture_name, COUNT(*) AS cnt
FROM public.session_records
GROUP BY student_id, session_number, group_name, is_general_exam, COALESCE(lecture_name,'')
HAVING COUNT(*) > 1;

-- Check the new index exists
SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'session_records' AND indexname ILIKE '%idx_session_records_unique%';

-- =========================
-- 8) Clean up (optional)
-- Once you are confident everything is fine, you may drop the backup table to reclaim space:
-- DROP TABLE IF EXISTS public.session_records_backup;

-- END OF FILE
