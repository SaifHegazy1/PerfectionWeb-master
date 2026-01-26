# Quick Start Guide - Testing New Features

## What's New

✅ **Excel Upload Dual Mode**
- Choose between "Normal Lecture" or "General Exam" when uploading
- Admin toggles control what data parent can see:
  - Show Exam Grade (quiz marks)
  - Show Payment
  - Show Time (finish time)

✅ **Parent Dashboard Updates**
- Displays lecture name or exam name (based on upload mode)
- Shows start time from admin-provided data
- Shows finish time conditionally (if enabled by admin)
- "Current Shamel" now dynamically shows general exam grade
- Removed "LAST" and "NEXT" Shamel sections

✅ **Settings & Password Change**
- New Settings button in parent dashboard
- Parents can change their password with current password verification
- Admin can change password via settings as well

✅ **Mobile & Language Support**
- Website fully responsive on mobile (375px - 1024px)
- Complete Arabic translation
- Language toggle (EN/AR) in top-right corner
- RTL layout automatically applied for Arabic

✅ **Login Error Display**
- Error messages now visible in UI (red alert box)
- No need to open browser console to see login errors

---

## Running the Application

### Terminal 1: Start Backend
```bash
cd backend
python app.py
```
Backend runs on `http://localhost:5000`

### Terminal 2: Start Frontend
```bash
cd PerfectionWeb-master
npm start
```
Frontend runs on `http://localhost:4200`

---

## Test Scenario

### As Admin:

1. **Upload Lecture**
   - Go to http://localhost:4200/admin/excel-upload
   - Mode: "Normal Lecture"
   - Lecture Name: "Physics - Chapter 5"
   - Session: Select any session
   - Group: Select any group
   - Show Exam Grade: ✓ ON
   - Show Payment: ✓ ON
   - Show Time: ✓ ON
   - Upload Excel file
   - Check that `lecture_name` is saved in database

2. **Upload Exam**
   - Mode: "General Exam"
   - Exam Name: "Mid-Term"
   - Show Exam Grade: ✓ ON
   - Show Payment: ✗ OFF
   - Show Time: ✗ OFF
   - Upload Excel file
   - Check that `exam_name` is saved and flags are set

### As Parent:

1. **Login & View Sessions**
   - Use any parent account credentials
   - In dashboard, you should see:
     - Lecture/Exam name
     - Start time
     - Finish time (only for lecture with time enabled)
     - Quiz marks (only for lecture with exam grade enabled)
     - Payment (only for lecture with payment enabled)

2. **Change Password**
   - Click Settings button (gear icon)
   - Modal opens with form
   - Enter current password
   - Enter new password (8+ characters)
   - Confirm new password
   - Click Submit
   - Success message appears
   - Logout and login with new password to verify

3. **Switch to Arabic**
   - Click "AR" button in top-right
   - Page switches to Arabic
   - Check that text is right-to-left
   - All labels in Arabic:
     - Sessions → الجلسات
     - Grades → الدرجات
     - Settings → الإعدادات
     - Password → كلمة المرور

4. **Test on Mobile**
   - Open DevTools (F12)
   - Click device toggle (Ctrl+Shift+M)
   - Set to iPhone 12 (390x844)
   - Verify:
     - No horizontal scroll
     - All elements visible
     - Text readable
     - Buttons clickable

---

## Database Verification

Connect to your Supabase database and run:

```sql
-- Check that new columns exist and have data
SELECT 
  COUNT(*) as total_sessions,
  COUNT(CASE WHEN lecture_name IS NOT NULL THEN 1 END) as lectures,
  COUNT(CASE WHEN exam_name IS NOT NULL THEN 1 END) as exams,
  COUNT(CASE WHEN has_exam_grade = false THEN 1 END) as no_grade_shown,
  COUNT(CASE WHEN has_payment = false THEN 1 END) as no_payment_shown,
  COUNT(CASE WHEN has_time = false THEN 1 END) as no_time_shown
FROM session_records;
```

Example output:
```
total_sessions | lectures | exams | no_grade_shown | no_payment_shown | no_time_shown
150            | 95       | 55    | 20             | 30               | 25
```

---

## Curl Testing (For Developers)

### 1. Test Parent Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"01012345678","password":"test123"}'
```

### 2. Test Change Password
```bash
curl -X POST http://localhost:5000/api/auth/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number":"01012345678",
    "current_password":"test123",
    "new_password":"newtest123"
  }'
```

### 3. Test Get Sessions with Filtering
```bash
curl -X GET http://localhost:5000/api/parent/sessions?phone_number=01012345678
```

Response shows only enabled fields:
```json
{
  "sessions": [
    {
      "lecture_name": "Physics - Chapter 5",
      "startTime": "2024-01-15T09:00:00",
      "quizCorrect": 8,
      "quizTotal": 10,
      "payment": 500,
      "endTime": "2024-01-15T11:00:00"
    }
  ]
}
```

---

## Known Limitations

1. **Password Hashing**: Currently uses plain text. For production, bcrypt implementation needed:
   ```python
   # In app.py, add:
   from werkzeug.security import generate_password_hash, check_password_hash
   ```

2. **Large Excel Files**: Upload may timeout for files >5MB. Consider chunked upload for production.

3. **Session Pagination**: All parent sessions returned at once. Add pagination for 1000+ sessions:
   ```python
   # Add query parameters:
   # ?limit=20&offset=0
   ```

---

## Troubleshooting

### "Module not found" errors
```bash
pip install -r backend/requirements.txt
npm install
```

### "Cannot POST /api/upload-excel"
- Backend not running. Start it: `python app.py`
- Check Flask logs for errors

### "Connection refused" to database
- Verify Supabase connection string in `.env`
- Ensure migration ran successfully

### Password change returns 500 error
- Check Flask logs for database errors
- Verify users exist in database
- Ensure current password matches exactly (case-sensitive)

### Arabic text not RTL
- Check browser console for CSS errors
- Verify `dir="rtl"` attribute on `<html>` element
- Hard refresh page (Ctrl+Shift+R)

### Mobile layout broken
- Clear browser cache
- Check that viewport meta tag exists in `index.html`
- Verify media query breakpoints (768px, 480px)

---

## Next Steps

1. ✅ Run this Quick Start
2. ✅ Test all scenarios above
3. ✅ Verify database has new columns with data
4. ⬜ Deploy to production
5. ⬜ Implement bcrypt password hashing
6. ⬜ Add rate limiting for security
7. ⬜ Set up monitoring and error tracking

---

**Questions?** Check DEPLOYMENT_CHECKLIST.md for detailed deployment steps.
