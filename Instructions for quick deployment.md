# 🚀 Client Instructions — Deploy from GitHub Repo

## 1 — Prerequisites

- **GitHub account**  
  (Already public repo: [MH612188-DS/ed_reco](https://github.com/MH612188-DS/ed_reco))

- **Render account**  
  [Create/Access account](https://dashboard.render.com)

- **Netlify account**  
  [Create/Access account](https://app.netlify.com)

> That’s all you need.  
> **No local Python/Flutter required** unless you want to develop locally.

---

## 2 — Deploy Backend (FastAPI) on Render

1. **Log in to Render** → Dashboard
2. Click **New** → **Web Service**
3. Select **Build from GitHub** and connect your GitHub account
4. Select repo: `ed_reco`
5. Configure:
    - **Root Directory:** `api`
    - **Environment:** Python 3
    - **Build Command:**  
      ```bash
      pip install --upgrade pip && pip install -r requirements.txt
      ```
      _or, if using wheels included:_  
      ```bash
      pip install --no-index --find-links=./wheels -r requirements.txt
      ```
    - **Start Command:**  
      ```bash
      uvicorn app:app --host 0.0.0.0 --port 10000
      ```
    - **Health Check Path:** `/health`
    - Free Plan is fine
    - _(Optional)_ Add environment variables if models are used:  
      ```
      MODEL_DIR = /opt/render/project/src/api/models_bundles
      ```
6. Click **Deploy**
7. After a few minutes, you’ll get a live URL, e.g.:  
   `https://ed-reco.onrender.com`
8. Test in browser:  
   [https://ed-reco.onrender.com/health](https://ed-reco.onrender.com/health)

---

## 3 — Deploy Frontend (Flutter Web) on Netlify

### Option A — Drag & Drop (fastest)
1. Go to Netlify → **Add new site** → **Deploy manually**
2. Download the `learning_styles_app/build/web/` folder from the GitHub repo (already built)
3. Drag & drop **the contents** of `build/web/` (not the folder itself, but files inside it)
4. Netlify gives you a live URL (e.g. `https://edubuddy-client.netlify.app`)

> ⚠️ This build is **pre-configured for `http://localhost:8000`** unless rebuilt.  
> To connect to your Render API, **rebuild the frontend with the correct API URL** (see Option B).

---

### Option B — Netlify Git Build (recommended)
1. On Netlify → **New site from Git**
2. Choose GitHub → select repo `ed_reco`
3. Configure:
    - **Base directory:** `learning_styles_app`
    - **Build command:**  
      ```bash
      flutter build web --release --dart-define=API_BASE=https://ed-reco.onrender.com
      ```
      (Replace `https://ed-reco.onrender.com` with your actual Render API URL)
    - **Publish directory:**  
      ```
      learning_styles_app/build/web
      ```
4. **Deploy**  
   Netlify builds Flutter frontend and publishes it
5. Open the given Netlify URL and test — it should call your Render API backend

---

## 4 — Verification

- Visit Netlify URL → you should see your Flutter web app
- The app should successfully call the Render API (check browser console for errors)
- Backend health check: [https://ed-reco.onrender.com/health](https://ed-reco.onrender.com/health)

---

## 5 — Optional: Local Run (if client wants)

If the client wants to run locally instead of Render/Netlify:

### Backend
```bash
cd api
python -m venv .venv
.\.venv\Scripts\activate    # On Windows
# or
source .venv/bin/activate   # On Mac/Linux
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000
```

### Frontend
```bash
cd learning_styles_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000
```

---

## ✅ Summary

- **Render** → backend (FastAPI) from `/api`
- **Netlify** → frontend (Flutter Web) from `/learning_styles_app/build/web` (drag/drop) **OR** Netlify Git build with `flutter build web`
