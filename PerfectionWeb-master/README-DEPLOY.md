# Deployment Guide: PerfectionWeb Frontend + Backend

Complete step-by-step instructions to deploy the Angular frontend on Vercel and Flask backend on Google Cloud Run (free tier).

## Architecture
- **Frontend**: Vercel (static Angular build) → Serves parent/admin dashboards
- **Backend**: Google Cloud Run (containerized Python) → Handles Excel uploads, authentication, API
- **Database**: Supabase (PostgreSQL) → Managed cloud database

## Prerequisites
1. GitHub account with your repo pushed.
2. Vercel account (free) at https://vercel.com
3. Google Cloud account (free tier) at https://cloud.google.com
   - Create a new project
   - Enable Cloud Run API
   - Set up a service account with Editor role
4. Supabase credentials (`SUPABASE_URL`, `SUPABASE_KEY`) from your project.

---

## PHASE 1: Test Locally (5 min)

### 1.1 Frontend Build Test
From project root:
```bash
npm install
npm run build
```
Check that `dist/prefectionweb/` folder exists with index.html inside.

### 1.2 Backend Test (optional, but recommended)
From `backend/` folder:
```bash
pip install -r requirements.txt
python app.py
```
Visit `http://localhost:5000/api/health` — should return `{"status":"ok", ...}`.

---

## PHASE 2: Frontend to Vercel (10 min)

### 2.1 Create Vercel Project
1. Go to https://vercel.com/dashboard
2. Click **Add New** → **Project**
3. Select **Import Git Repository** → find your GitHub repo and click **Import**
4. Framework Preset: Select **Other** (since it's Angular, which Vercel may not auto-detect)
5. Configure:
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist/prefectionweb`
   - **Install Command**: `npm install`
6. Click **Deploy** — wait for build to complete (2–3 min).

### 2.2 Set Frontend Environment Variables
After deployment:
1. Go to project **Settings** → **Environment Variables**
2. Add:
   - **Name**: `API_BASE_URL`
   - **Value**: `http://localhost:5000` (temporary for testing, you'll update this after Render URL is live)
   - **Environments**: Development, Preview, Production
3. Click **Add**
4. Redeploy: Click **Deployments** → latest → **Redeploy**

### 2.3 Verify Frontend
Click the deployment URL (e.g., `https://your-project.vercel.app`). You should see the login page.

**Note**: The parent dashboard will show "error loading sessions" because the backend isn't live yet. That's normal.

---

## PHASE 3: Backend to Google Cloud Run (15 min)

### 3.1 Setup Google Cloud Project
1. Go to https://console.cloud.google.com
2. Create a new project or select existing
3. Enable Cloud Run API:
   - Search "Cloud Run" in search bar → click **Cloud Run**
   - Click **Enable** if not already enabled
4. Enable Artifact Registry API:
   - Search "Artifact Registry" → click **Enable**

### 3.2 Install gcloud CLI (if not already installed)
From your machine:
```bash
# Windows: Download from https://cloud.google.com/sdk/docs/install-sdk
# Or use chocolatey:
choco install google-cloud-sdk

# macOS:
brew install google-cloud-sdk

# After install, initialize:
gcloud init
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 3.3 Deploy Backend to Cloud Run
From repo root, run:
```bash
cd backend
gcloud run deploy perfectionweb-backend --source . --region us-central1 --allow-unauthenticated --set-env-vars SUPABASE_URL=<YOUR_URL>,SUPABASE_KEY=<YOUR_KEY>
```

Replace:
- `<YOUR_URL>` with your Supabase URL (e.g., `https://xxx.supabase.co`)
- `<YOUR_KEY>` with your Supabase anon key

**First deployment takes 2–3 minutes.** Wait for:
```
Service [perfectionweb-backend] revision [XX] has been deployed...
Service URL: https://perfectionweb-backend-xxxxx.run.app
```

### 3.4 Verify Backend
Copy the **Service URL** from the output above and test in browser:
```
https://perfectionweb-backend-xxxxx.run.app/api/health
```

Expected response:
```json
{"status":"ok", "message":"Flask backend is running"}
```

If error:
- Check logs: `gcloud run logs read perfectionweb-backend --region us-central1 --limit 50`
- Verify environment variables: `gcloud run services describe perfectionweb-backend --region us-central1`
- Ensure `SUPABASE_URL` and `SUPABASE_KEY` are correctly set

---

## PHASE 4: Connect Frontend ↔ Backend (5 min)

### 4.1 Update Frontend API URL
1. Go back to Vercel dashboard → Project **Settings** → **Environment Variables**
2. Update `API_BASE_URL`:
   - **Value**: `https://perfectionweb-backend-xxxxx.run.app` (replace with your Cloud Run service URL from Phase 3.3)
   - Environments: Production
3. Click **Save** → Redeploy:
   - **Deployments** → latest → **Redeploy**
4. Wait for redeploy to complete.

### 4.2 Test Integration
1. Open your Vercel frontend URL: `https://your-project.vercel.app/login`
2. Login with a parent phone number + password.
3. Navigate to parent dashboard → should see students and sessions loading from Cloud Run backend.
4. Try uploading an Excel file (admin portal) — should succeed.

---

## PHASE 5: Final Verification Checklist

- [ ] Frontend loads on Vercel without errors
- [ ] Backend /api/health returns 200
- [ ] Parent can login with phone number
- [ ] Sessions load on parent dashboard
- [ ] Excel upload works from admin dashboard
- [ ] Logout button appears and works
- [ ] Start time displays in DD/MM/YYYY HH:MM:SS ص/م format
- [ ] No console errors in browser (F12 → Console tab)

---

## Troubleshooting

### Frontend shows "error loading sessions"
- Check browser console (F12) for network errors.
- Verify `API_BASE_URL` environment variable is set to the correct Render URL.
- Ensure Render backend is running (check Render dashboard logs).

### Render backend shows error "Module not found"
- Run locally: `cd backend && pip install -r requirements.txt`
- Check that all imports in `app.py` are listed in `requirements.txt`.
- Verify Python version matches (Render uses Python 3.x; check logs for exact version).

### Vercel build fails
- Check **Build Logs** in Vercel dashboard.
- Run locally: `npm run build` to reproduce error.
- Verify `dist/prefectionweb/` is created (Angular default output folder).

### 404 on /api/upload-excel
- Ensure Cloud Run backend is live.
- Check logs: `gcloud run logs read perfectionweb-backend --region us-central1 --limit 50`
- Verify `SUPABASE_URL` and `SUPABASE_KEY` are correct in Cloud Run environment variables.

---

## Monitoring & Logs

**Vercel**:
- Dashboard → Deployments → select a deployment → Logs tab

**Google Cloud Run**:
- Command: `gcloud run logs read perfectionweb-backend --region us-central1 --limit 50`
- Or via console: https://console.cloud.google.com → Cloud Run → select service → Logs

---

## Optional: Custom Domain

### Vercel
1. **Settings** → **Domains** → add your domain (e.g., `app.yourdomain.com`)
2. Follow DNS setup instructions provided by Vercel.

### Google Cloud Run
1. Go to Cloud Run → select service → **Manage Custom Domains**
2. Add your domain (e.g., `api.yourdomain.com`)
3. Follow DNS setup instructions provided by Google Cloud.

---

## Cost (Free Tier)
- **Vercel**: Free for static sites, includes 100GB bandwidth/month.
- **Google Cloud Run**: Free tier includes 2M requests/month + 360K compute seconds. Perfect for low-traffic apps.
  - After free tier: pay-per-use (~$0.40 per 1M requests + compute time).
- **Supabase**: Free tier includes 500MB database + 1GB bandwidth.

---

## Summary of Files Added/Updated
- `vercel.json` — Vercel build config for Angular static site
- `backend/Dockerfile` — Docker container config for Cloud Run
- `backend/app.yaml` — App Engine config (alternative to Dockerfile)
- `backend/requirements.txt` — Python dependencies for Render
- `backend/Procfile` — Render startup command
- `.env` (already exists) — local Supabase credentials (never commit)

Push all changes to GitHub, then proceed with Vercel + Render setup above.

---

## Support
- Vercel docs: https://vercel.com/docs
- Render docs: https://render.com/docs
- Angular deployment: https://angular.io/guide/deployment
