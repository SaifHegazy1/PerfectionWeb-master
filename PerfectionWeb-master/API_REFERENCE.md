# API Reference Guide

Complete API documentation for PerfectionWeb after enhancements.

---

## Authentication Endpoints

### 1. Parent Login
**Endpoint:** `POST /api/auth/login`

**Request:**
```json
{
  "phone_number": "01012345678",
  "password": "test123"
}
```

**Response (200):**
```json
{
  "success": true,
  "parent_id": 1,
  "name": "Ahmed Hassan",
  "phone_number": "01012345678"
}
```

**Response (401):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

### 2. Admin Login
**Endpoint:** `POST /api/admin/login`

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response (200):**
```json
{
  "success": true,
  "admin_id": 1,
  "username": "admin"
}
```

---

### 3. Change Password (Parent)
**Endpoint:** `POST /api/auth/change-password`

**NEW ENDPOINT** ✅

**Request:**
```json
{
  "phone_number": "01012345678",
  "current_password": "test123",
  "new_password": "newtest123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Response (401):**
```json
{
  "success": false,
  "message": "Current password is incorrect"
}
```

---

### 4. Change Password (Admin)
**Endpoint:** `POST /api/admin/change-password`

**NEW ENDPOINT** ✅

**Request:**
```json
{
  "username": "admin",
  "current_password": "admin123",
  "new_password": "newadmin123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## Data Retrieval Endpoints

### 5. Get Groups
**Endpoint:** `GET /api/groups`

**Response (200):**
```json
{
  "groups": [
    "cam1",
    "maimi",
    "cam2",
    "west",
    "station1",
    "station2",
    "station3"
  ]
}
```

---

### 6. Get Available Sessions
**Endpoint:** `GET /api/sessions`

**Response (200):**
```json
{
  "sessions": [1, 2, 3, 4, 5, 6, 7, 8]
}
```

---

### 7. Get Parent Sessions
**Endpoint:** `GET /api/parent/sessions?phone_number=01012345678`

**MODIFIED ENDPOINT** ✅

**Query Parameters:**
- `phone_number` (required): Parent's phone number

**Response (200):**
```json
{
  "success": true,
  "sessions": [
    {
      "id": 1,
      "lecture_name": "Physics - Chapter 5",
      "exam_name": null,
      "startTime": "2024-01-15T09:00:00",
      "endTime": "2024-01-15T11:00:00",
      "quizCorrect": 8,
      "quizTotal": 10,
      "payment": 500,
      "status": "completed"
    },
    {
      "id": 2,
      "lecture_name": null,
      "exam_name": "Mid-Term Exam",
      "startTime": "2024-01-20T10:00:00",
      "endTime": null,
      "quizCorrect": null,
      "quizTotal": null,
      "payment": null,
      "status": "completed"
    }
  ]
}
```

**Field Visibility Logic:**
- `quizCorrect` & `quizTotal`: Included only if `has_exam_grade == true`
- `payment`: Included only if `has_payment == true`
- `endTime`: Included only if `has_time == true`
- `lecture_name` or `exam_name`: Always included

---

## Upload Endpoints

### 8. Upload Excel File
**Endpoint:** `POST /api/upload-excel`

**NEW PARAMETERS** ✅

**Request (FormData):**
```
Content-Type: multipart/form-data

file: [Excel file] (required)
session_number: 1 (required)
group: "cam1" (required)
is_general_exam: false (required)
lecture_name: "Physics - Chapter 5" (required if not general exam)
exam_name: "Mid-Term" (required if general exam)
has_exam_grade: true (boolean, optional, default: true)
has_payment: true (boolean, optional, default: true)
has_time: true (boolean, optional, default: true)
quiz_mark: 95.5 (float, optional)
finish_time: "11:00" (string HH:MM, optional)
```

**Example cURL:**
```bash
curl -X POST http://localhost:5000/api/upload-excel \
  -F "file=@students.xlsx" \
  -F "session_number=1" \
  -F "group=cam1" \
  -F "is_general_exam=false" \
  -F "lecture_name=Physics - Chapter 5" \
  -F "has_exam_grade=true" \
  -F "has_payment=true" \
  -F "has_time=true" \
  -F "quiz_mark=95.5" \
  -F "finish_time=11:00"
```

**Response (200):**
```json
{
  "success": true,
  "message": "Excel file uploaded and processed successfully",
  "records_processed": 45,
  "records_inserted": 35,
  "records_updated": 10
}
```

**Response (400):**
```json
{
  "success": false,
  "error": "Missing required file or parameters"
}
```

---

## Student Endpoints

### 9. Get Student Details
**Endpoint:** `GET /api/student/{student_id}`

**Response (200):**
```json
{
  "id": 1,
  "name": "Ahmed Ali",
  "group": "cam1",
  "phone_number": "01123456789",
  "parent_phone_number": "01012345678",
  "avg_quiz_mark": 7.8
}
```

---

## Excel File Format

### Required Columns for Normal Lecture:
| Column | Type | Example | Required |
|--------|------|---------|----------|
| Student ID | Number | 1001 | Yes |
| Student Name | Text | Ahmed Ali | Yes |
| Attendance | Text | Present/Absent | Yes |
| Quiz Mark | Number | 8 | No (if has_exam_grade=false) |
| Homework Status | Text | Done/Pending | Yes |

### Required Columns for General Exam:
| Column | Type | Example | Required |
|--------|------|---------|----------|
| Student ID | Number | 1001 | Yes |
| Student Name | Text | Ahmed Ali | Yes |
| General Exam Mark | Number | 85 | Yes |

---

## Database Schema (New Columns)

### session_records Table Changes:

```sql
-- New columns:
- lecture_name VARCHAR(255) -- Name of the lecture
- exam_name VARCHAR(255) -- Name of the exam
- has_exam_grade BOOLEAN DEFAULT true -- Show quiz marks to parent
- has_payment BOOLEAN DEFAULT true -- Show payment to parent
- has_time BOOLEAN DEFAULT true -- Show finish time to parent
- start_time TIMESTAMP -- When session starts

-- New index:
CREATE INDEX idx_session_records_lecture_name 
ON session_records(lecture_name);

-- Deduplication constraint:
UNIQUE (student_id, session_number, group_name, is_general_exam)
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "Invalid request format",
  "details": "Missing required field: lecture_name"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Invalid credentials or password incorrect"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Internal server error",
  "details": "Database connection failed"
}
```

---

## Frontend Service Methods

### ExcelUploadService

```typescript
// Get available groups
getGroups(): Observable<string[]>

// Get available sessions
getSessions(): Observable<number[]>

// Upload Excel with metadata
uploadExcel(
  file: File,
  sessionNumber: number,
  group: string,
  isGeneralExam: boolean,
  lectureName: string = '',
  examName: string = '',
  hasExamGrade: boolean = true,
  hasPayment: boolean = true,
  hasTime: boolean = true,
  quizMark?: number,
  finishTime?: string
): Observable<UploadResponse>
```

### AuthService

```typescript
// Parent login
parentLogin(phoneNumber: string, password: string): Observable<{ success: boolean }>

// Admin login
adminLogin(username: string, password: string): Observable<{ success: boolean }>

// Change password (parent or admin)
changePassword(
  currentPassword: string,
  newPassword: string
): Observable<{ success: boolean; message?: string }>
```

### StudentService

```typescript
// Get parent's students
getStudents(phoneNumber: string): Observable<Student[]>

// Get student sessions
getStudentSessions(phoneNumber: string): Observable<Session[]>
```

---

## Request/Response Examples

### Example 1: Upload Lecture with All Features Enabled

**Request:**
```bash
curl -X POST http://localhost:5000/api/upload-excel \
  -F "file=@physics_chapter5.xlsx" \
  -F "session_number=3" \
  -F "group=cam1" \
  -F "is_general_exam=false" \
  -F "lecture_name=Physics - Chapter 5: Thermodynamics" \
  -F "has_exam_grade=true" \
  -F "has_payment=true" \
  -F "has_time=true" \
  -F "quiz_mark=90" \
  -F "finish_time=11:00"
```

**Database Result:**
```sql
INSERT INTO session_records (
  student_id, session_number, group_name, is_general_exam,
  lecture_name, has_exam_grade, has_payment, has_time, start_time
) VALUES (
  1001, 3, 'cam1', false,
  'Physics - Chapter 5: Thermodynamics', true, true, true, NOW()
);
```

**Parent Dashboard Shows:**
```
Lecture: Physics - Chapter 5: Thermodynamics
Start: Jan 15, 2024 9:00 AM
Finish: Jan 15, 2024 11:00 AM
Quiz: 8/10 ✓
Payment: 500 EGP ✓
```

---

### Example 2: Upload Exam with Limited Features

**Request:**
```bash
curl -X POST http://localhost:5000/api/upload-excel \
  -F "file=@midterm_exam.xlsx" \
  -F "session_number=5" \
  -F "group=maimi" \
  -F "is_general_exam=true" \
  -F "exam_name=Mid-Term Exam - Physics" \
  -F "has_exam_grade=true" \
  -F "has_payment=false" \
  -F "has_time=false"
```

**Database Result:**
```sql
INSERT INTO session_records (
  student_id, session_number, group_name, is_general_exam,
  exam_name, has_exam_grade, has_payment, has_time
) VALUES (
  1001, 5, 'maimi', true,
  'Mid-Term Exam - Physics', true, false, false
);
```

**Parent Dashboard Shows:**
```
Exam: Mid-Term Exam - Physics
Start: Jan 20, 2024 10:00 AM
Quiz: 85/100 ✓
Payment: [HIDDEN]
Finish: [HIDDEN]
```

---

## Rate Limiting (Recommended for Production)

```
POST /api/auth/change-password: 5 requests per minute per user
POST /api/upload-excel: 10 requests per hour per admin
```

---

## Versioning

**Current API Version:** 1.0
**Last Updated:** 2024
**Breaking Changes:** None (backwards compatible with existing endpoints)

---

## Authentication Header (Future)

For future JWT implementation:
```
Authorization: Bearer <token>
```

Currently, authentication is session-based with phone_number or username.
