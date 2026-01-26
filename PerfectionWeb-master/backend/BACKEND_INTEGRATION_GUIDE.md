# Backend Integration - Setup Guide

This document outlines the backend changes and how to deploy them.

## Changes Made

### 1. Database Schema Migration
A new migration file has been created: `migration_add_lecture_metadata.sql`

This migration adds the following columns to the `session_records` table:
- `lecture_name` TEXT - Name of the lecture (for normal lectures)
- `exam_name` TEXT - Name of the exam (for general exams)
- `has_exam_grade` BOOLEAN (default: true) - Show exam grade in parent dashboard
- `has_payment` BOOLEAN (default: true) - Show payment in parent dashboard
- `has_time` BOOLEAN (default: true) - Show finish time in parent dashboard
- `start_time` TIMESTAMP - Start time from Excel sheet

### 2. Upload Endpoint Updates
**Route:** `POST /api/upload-excel`

**New Form Parameters:**
- `lecture_name` (string, optional) - Lecture name for normal lectures
- `exam_name` (string, optional) - Exam name for general exams
- `has_exam_grade` (boolean, default: true) - Admin toggle to show/hide exam grade
- `has_payment` (boolean, default: true) - Admin toggle to show/hide payment
- `has_time` (boolean, default: true) - Admin toggle to show/hide finish time

**Backend Logic:**
- The upload endpoint now stores these flags in the `session_records` table
- Metadata is stored per session for easy filtering in parent dashboard

### 3. Parent Sessions Endpoint Updates
**Route:** `GET /api/parent/sessions`

**Behavior:**
- Now respects the `has_exam_grade`, `has_payment`, and `has_time` flags
- Conditionally includes:
  - `quizCorrect` and `quizTotal` only if `has_exam_grade` is true
  - `payment` only if `has_payment` is true
  - `endTime` only if `has_time` is true
- Includes `startTime` from start_time column
- Shows `lecture_name` or `exam_name` in session display

### 4. Change Password Endpoints

#### Parent Change Password
**Route:** `POST /api/auth/change-password`

**Request Body:**
```json
{
  "phone_number": "01234567890",
  "current_password": "oldpassword",
  "new_password": "newpassword123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

#### Admin Change Password
**Route:** `POST /api/admin/change-password`

**Request Body:**
```json
{
  "username": "admin",
  "current_password": "oldpassword",
  "new_password": "newpassword123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

## Deployment Steps

### Step 1: Run Database Migration
1. Go to Supabase SQL Editor
2. Copy and paste the contents of `migration_add_lecture_metadata.sql`
3. Click "Run" to execute the migration

### Step 2: Restart Backend Server
```bash
cd backend
python app.py
```

### Step 3: Test Endpoints

#### Test Upload with New Fields
```bash
curl -X POST http://localhost:5000/api/upload-excel \
  -F "file=@students.xlsx" \
  -F "session_number=1" \
  -F "group=cam1" \
  -F "is_general_exam=false" \
  -F "lecture_name=Chapter 5: Electricity" \
  -F "has_exam_grade=true" \
  -F "has_payment=true" \
  -F "has_time=true"
```

#### Test Change Password
```bash
curl -X POST http://localhost:5000/api/auth/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "01234567890",
    "current_password": "oldpass",
    "new_password": "newpass123"
  }'
```

## Frontend Integration

The Angular frontend has already been updated to:
1. Send the new metadata fields from the upload form
2. Respect the feature flags when displaying session cards
3. Call the change-password endpoints from the settings modal
4. Support bilingual Arabic/English UI with RTL layout

## Notes

- **Password Hashing:** Current implementation uses plain text comparison. For production, implement proper password hashing (bcrypt, argon2, etc.)
- **Database Uniqueness:** Sessions are uniquely identified by (student_id, session_number, group_name, is_general_exam) to prevent duplicates
- **Feature Flags:** Default to `true` for backward compatibility; can be set to `false` by admin to hide fields from parent dashboard
