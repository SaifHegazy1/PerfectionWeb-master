# Deployment & Testing Checklist

## Phase 1: Database Migration (Supabase)

### Step 1: Apply Migration
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **SQL Editor**
4. Click **New Query**
5. Copy content from `backend/migration_add_lecture_metadata.sql`
6. Click **Run** to execute migration
7. Verify execution: Check **Logs** tab for success message

### Step 2: Verify Schema Changes
```sql
-- Run this query to verify new columns exist
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'session_records'
ORDER BY ordinal_position;
```

Expected new columns:
- `lecture_name` (varchar, nullable)
- `exam_name` (varchar, nullable)
- `has_exam_grade` (boolean, default true)
- `has_payment` (boolean, default true)
- `has_time` (boolean, default true)
- `start_time` (timestamp, nullable)

---

## Phase 2: Backend Deployment

### Step 1: Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### Step 2: Start Flask Server
```bash
python app.py
```

Expected output:
```
 * Running on http://127.0.0.1:5000
 * Debug mode: off
```

### Step 3: Test Change Password Endpoint (Parent)
```bash
curl -X POST http://localhost:5000/api/auth/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "01012345678",
    "current_password": "test123",
    "new_password": "newtest123"
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

### Step 4: Test Change Password Endpoint (Admin)
```bash
curl -X POST http://localhost:5000/api/admin/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "current_password": "admin123",
    "new_password": "newadmin123"
  }'
```

### Step 5: Test Session Filtering with Feature Flags
```bash
curl -X GET "http://localhost:5000/api/parent/sessions?phone_number=01012345678"
```

Expected response structure (fields included/excluded based on flags):
```json
{
  "sessions": [
    {
      "lecture_name": "Lecture Name",
      "startTime": "2024-01-15T09:00:00",
      "quizCorrect": 8,           // Only if has_exam_grade=true
      "quizTotal": 10,            // Only if has_exam_grade=true
      "payment": 500,             // Only if has_payment=true
      "endTime": "2024-01-15T11:00:00",  // Only if has_time=true
      "status": "completed"
    }
  ]
}
```

---

## Phase 3: Frontend Build & Deployment

### Step 1: Install Angular Dependencies
```bash
cd PerfectionWeb-master
npm install
```

### Step 2: Build Production Bundle
```bash
npm run build
```

Expected output:
```
✔ Copying assets completed
✔ index.html generation completed
Build at: [timestamp]
```

### Step 3: Start Development Server (for testing)
```bash
npm start
```

App should be available at `http://localhost:4200`

### Step 4: Verify Frontend Features

#### 4.1 Test Excel Upload (Admin)
1. Navigate to **Admin Dashboard** → **Excel Upload**
2. Upload Excel file with these steps:
   - **Mode**: Select "Normal Lecture"
   - **Lecture Name**: "Physics Chapter 5"
   - **Session**: Select from dropdown
   - **Group**: Select from dropdown
   - **Show Exam Grade**: Toggle ON
   - **Show Payment**: Toggle ON
   - **Show Time**: Toggle ON
   - **Click Upload**

3. Verify in browser console (F12):
   - FormData should contain all fields
   - Request should go to `/api/upload-excel`
   - Response should include success message

#### 4.2 Test General Exam Mode
1. Return to Excel Upload
2. **Mode**: Select "General Exam"
3. **Exam Name**: "Mid-Term Exam"
4. Upload another Excel file
5. Verify in database that `is_general_exam=true` and `exam_name` is populated

#### 4.3 Test Parent Dashboard
1. Login as parent with credentials from database
2. Verify sessions display with:
   - **Lecture/Exam Name**: From database
   - **Start Time**: From `start_time` column
   - **Finish Time**: Conditionally shown (only if `has_time=true`)
   - **Current Shamel Grade**: Computed from sessions or student average
   - **LAST/NEXT Shamel**: Should NOT appear (removed)
   - **Quiz Marks & Payment**: Only shown if corresponding flags are true

#### 4.4 Test Settings Modal
1. Click **Settings** button in parent dashboard
2. Modal should open with password change form
3. Enter:
   - **Current Password**: Parent's current password
   - **New Password**: New password (8+ chars recommended)
   - **Confirm Password**: Same as new password
4. Click **Submit**
5. Verify success message appears
6. Try login with new password to confirm change

#### 4.5 Test Language Toggle
1. Click **AR** button in top-right
2. Page should switch to Arabic:
   - Text direction: Right-to-left (RTL)
   - Labels in Arabic: "الجلسات", "الامتحانات", "الدرجات", etc.
   - Layout elements reversed (margins, text-align, flex direction)
3. Click **EN** to switch back

#### 4.6 Test Responsive Design
1. Open DevTools (F12)
2. Toggle **Device Toolbar** (Ctrl+Shift+M)
3. Test at breakpoints:
   - **Desktop (1024px)**: All elements visible
   - **Tablet (768px)**: Hero section hidden, cards responsive
   - **Mobile (375px)**: Single-column layout, compact spacing
4. Verify no horizontal scrolling at any breakpoint

#### 4.7 Test Login Error Display
1. Go to login page
2. Enter invalid credentials
3. Verify red error alert appears **in UI** (not console only)
4. Error message should match backend response

---

## Phase 4: Production Deployment

### For AWS/Heroku Backend:
```bash
cd backend
git push heroku main  # or AWS CodeDeploy
```

### For Firebase/Vercel Frontend:
```bash
npm run build
firebase deploy --only hosting  # or vercel
```

### Update Backend URL in Frontend:
Edit `src/environments/environment.prod.ts`:
```typescript
export const environment = {
  production: true,
  apiUrl: 'https://your-backend-domain.com/api'
};
```

---

## Phase 5: Post-Deployment Verification

### Manual Testing Checklist:
- [ ] Admin can upload Excel in lecture mode
- [ ] Admin can upload Excel in general exam mode
- [ ] Lecture metadata is stored in database
- [ ] Feature flags (has_exam_grade, has_payment, has_time) are stored
- [ ] Parent dashboard shows/hides fields based on flags
- [ ] Parent can change password via settings modal
- [ ] Change password validation works (current password verification)
- [ ] Language toggle switches between English and Arabic
- [ ] RTL layout is applied correctly for Arabic
- [ ] Mobile responsive at 768px breakpoint
- [ ] Mobile responsive at 480px breakpoint
- [ ] No console errors (F12 → Console)
- [ ] Network requests show correct payload (F12 → Network)

### Database Verification:
```sql
-- Check that new columns have data
SELECT 
  id,
  student_id,
  lecture_name,
  exam_name,
  has_exam_grade,
  has_payment,
  has_time,
  start_time
FROM session_records
WHERE lecture_name IS NOT NULL OR exam_name IS NOT NULL
LIMIT 5;

-- Check index creation
SELECT indexname FROM pg_indexes 
WHERE tablename = 'session_records' AND indexname LIKE '%lecture%';
```

---

## Troubleshooting

### Issue: Backend returns 404 on new endpoints
**Solution**: Ensure `app.py` file is updated with new routes. Restart Flask server with `python app.py`

### Issue: Frontend shows old version
**Solution**: Clear cache (Ctrl+Shift+Delete in Chrome) or do hard refresh (Ctrl+Shift+R)

### Issue: Database columns don't exist
**Solution**: Verify migration ran successfully. Check Supabase SQL logs for errors.

### Issue: Password change always fails
**Solution**: Check that plain-text password matching works. For production, implement bcrypt hashing:
```python
# TODO: Implement password hashing
from werkzeug.security import generate_password_hash, check_password_hash
```

### Issue: Arabic text appears left-to-right
**Solution**: Verify `dir="rtl"` attribute is set on document element. Check `:host-context([dir='rtl'])` CSS is loaded.

### Issue: Mobile layout broken at 375px
**Solution**: Check media queries are ordered correctly (desktop-first approach). Verify no overflow issues with padding/margins.

---

## Performance Notes

- **Excel Upload**: Large files (>1MB) may timeout. Consider implementing chunked upload for production.
- **Session Filtering**: Backend filters all fields per request. For 1000+ sessions, consider pagination via `?limit=20&offset=0`
- **Language Toggle**: Client-side only (no API call). Translations embedded in templates.

---

## Security Notes

⚠️ **IMPORTANT FOR PRODUCTION**:
1. **Password Hashing**: Current implementation uses plain text. Implement bcrypt:
   ```python
   from werkzeug.security import generate_password_hash, check_password_hash
   ```

2. **HTTPS**: Ensure all API calls use HTTPS in production environment

3. **CORS**: Update Flask CORS policy for production domain:
   ```python
   CORS(app, resources={r"/api/*": {"origins": ["https://yourdomain.com"]}})
   ```

4. **Rate Limiting**: Add rate limiting to prevent brute-force password attacks:
   ```python
   from flask_limiter import Limiter
   limiter = Limiter(app, key_func=lambda: request.remote_addr)
   @app.route('/api/auth/change-password', methods=['POST'])
   @limiter.limit("5 per minute")
   def change_password():
       ...
   ```

---

## Testing Report Template

After deployment, fill in this checklist:

**Deployed Date**: _______________
**Deployed By**: _______________
**Backend URL**: _______________
**Frontend URL**: _______________

**Test Results**:
- Excel Upload (Lecture Mode): [ ] Pass [ ] Fail
- Excel Upload (General Exam Mode): [ ] Pass [ ] Fail
- Parent Dashboard Display: [ ] Pass [ ] Fail
- Password Change Modal: [ ] Pass [ ] Fail
- Language Toggle: [ ] Pass [ ] Fail
- Mobile Responsive: [ ] Pass [ ] Fail
- Login Error Display: [ ] Pass [ ] Fail
- Database Verification: [ ] Pass [ ] Fail

**Issues Found**: _______________________________________________
**Notes**: _____________________________________________________
