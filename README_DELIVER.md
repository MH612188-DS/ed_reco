# 🎓 EDU_BUDDY — Quickstart & Runbook

A step-by-step guide for running, building, and deploying the EDU_BUDDY project (API & Flutter web app). Written for beginners—just follow along!

---

## 🚀 Quick Summary

- **Start backend:**  
  `python -m venv .venv` → `pip install -r requirements.txt` → `uvicorn app:app --host 0.0.0.0 --port 8000`
- **Build frontend:**  
  `flutter build web --release --dart-define=API_BASE=https://<your-render-url>`
- **Serve locally:**  
  `python -m http.server 8080` (from `learning_styles_app/build/web`)
- **Deploy backend:**  
  Render (see below)
- **Deploy frontend:**  
  Netlify (see below)

---

## 🧰 Requirements

Install these first:

- [Git](https://git-scm.com)
- [Python 3.11+](https://www.python.org)
- pip (comes with Python)
- [Flutter SDK](https://flutter.dev)
- [Node.js & npm](https://nodejs.org) _(optional: Netlify CLI)_
- [Docker Desktop](https://www.docker.com) _(optional)_
- Netlify account _(optional)_: [Sign up](https://app.netlify.com)
- Render account: [Sign up](https://dashboard.render.com)
- Code editor _(VS Code recommended)_
- Modern browser _(Chrome recommended)_

---

## 🧹 Repo Hygiene

- Ensure `.gitignore` contains:
  ```
  # virtual envs
  .venv/
  venv/
  api/.venv/
  learning_styles_app/.dart_tool/
  learning_styles_app/build/
  ```
- **Do not commit:** `.venv` or build artifacts (unless delivering `learning_styles_app/build/web`)
- **Models:** Verify `api/models_bundles/` exists and contains model files.

---

## 🏗️ Running the API Locally

### On Windows (PowerShell):

```powershell
cd C:\path\to\edu_buddy\api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt

# (Optional) set model env vars
$env:MODEL_DIR = (Resolve-Path .\models_bundles).Path
$env:SCHEMA_PATH = (Resolve-Path .\models_bundles\feature_columns.json).Path

# Run API
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

- Visit [http://localhost:8000/health](http://localhost:8000/health) (API health)
- Visit [http://localhost:8000/docs](http://localhost:8000/docs) (FastAPI docs)

---

### On macOS / Linux (Bash):

```bash
cd /path/to/edu_buddy/api
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

export MODEL_DIR="$(pwd)/models_bundles"
export SCHEMA_PATH="$(pwd)/models_bundles/feature_columns.json"

uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

---

## 🐳 (Optional) Run API in Docker

From repo root (where `api/Dockerfile` exists):

```bash
cd /path/to/edu_buddy
docker build -t edreco-api -f api/Dockerfile .
docker run --rm -p 8000:8000 -e MODEL_DIR=/models -v "${PWD}/api/models_bundles:/models" edreco-api
```

---

## 💻 Flutter Frontend

### Development (hot reload)

```bash
cd /path/to/edu_buddy/learning_styles_app
flutter clean
flutter pub get
flutter run -d web-server --dart-define=API_BASE=http://localhost:8000
```
- Opens Chrome with app using your local backend.

---

### Production Build

- **To target deployed API:**  
  Replace with your Render URL.

  ```bash
  cd learning_styles_app
  flutter clean
  flutter pub get
  flutter build web --release --dart-define=API_BASE=https://ed-reco.onrender.com
  ```
- **To target local API:**  
  ```bash
  flutter build web --release --dart-define=API_BASE=http://localhost:8000
  ```

- Output: `learning_styles_app/build/web/`

---

## 🌐 Serve Built Frontend Locally

```bash
cd learning_styles_app/build/web
python -m http.server 8080
# Open http://localhost:8080
```
**Or** (Docker nginx):

```bash
docker run --rm -p 8080:80 -v "${PWD}:/usr/share/nginx/html:ro" nginx:alpine
```

---

## 🚢 Deploy Backend to Render

1. **Create account & connect GitHub repo**
2. **New Web Service:**
   - Environment: Python 3
   - Root Directory: `api`
   - Build Command:  
     `pip install -r requirements.txt`  
     _(or `pip install --no-index --find-links=./wheels -r requirements.txt` if using wheels)_
   - Start Command:  
     `uvicorn app:app --host 0.0.0.0 --port 10000`
   - Health Check Path: `/health`
   - Set environment variables if needed:
     ```
     MODEL_DIR = /opt/render/project/src/api/models_bundles
     SCHEMA_PATH = /opt/render/project/src/api/models_bundles/feature_columns.json
     ```
3. **Get your API URL** (e.g., `https://ed-reco.onrender.com`)
4. **Alternative:**  
   Use `render.yaml` if included.

---

## 🚀 Deploy Frontend to Netlify

### **A. Drag & Drop**

1. Build web bundle (see above).
2. Go to Netlify → New site from drag & drop → upload contents of `learning_styles_app/build/web`.
3. Netlify gives you a site URL.

### **B. Git-based (recommended):**

1. Connect Netlify to GitHub.
2. Site build settings:
   - Base directory: `learning_styles_app`
   - Build command:  
     `flutter build web --release --dart-define=API_BASE=https://ed-reco.onrender.com`
   - Publish directory: `learning_styles_app/build/web`
3. Netlify builds & publishes on every push.

**Important:**  
If using `--dart-define=API_BASE=...`, set correct Render URL in Netlify build command!

---

## 🗂️ What to Open (When)

- **Local setup:**  
  - PowerShell/Terminal A: run backend (API)
  - PowerShell/Terminal B: run Flutter dev/build web bundle
  - Browser:  
    - [http://localhost:8080](http://localhost:8080) (frontend)  
    - [http://localhost:8000/health](http://localhost:8000/health) (backend health)  
    - [http://localhost:8000/docs](http://localhost:8000/docs) (API docs)
- **Deployment:**  
  - Log in to Render (API deploy logs)
  - Log in to Netlify (frontend deploy logs)

---

## 🛠️ Troubleshooting

### **A. Flutter web: `ClientException: Failed to fetch`**

- **Causes:** Frontend can't reach API / CORS blocked.
- **Fixes:**
  1. Build frontend with correct `API_BASE`
  2. Test API is reachable:  
     `curl http://localhost:8000/health`
  3. If CORS errors:  
     Add FastAPI CORS middleware in `app.py`:

     ```python
     from fastapi.middleware.cors import CORSMiddleware
     app.add_middleware(
         CORSMiddleware,
         allow_origins=["*"],      # Dev only; restrict in production
         allow_credentials=True,
         allow_methods=["*"],
         allow_headers=["*"],
     )
     ```

### **B. 404 on `/` after deploy**

Add a root route in `api/app.py`:

```python
@app.get("/")
def read_root():
    return {"message": "Welcome to Style Recommender API"}
```

### **C. Git push rejected (large files)**

- Don't commit `.venv` or `.dll` files.
- Add `.venv/` to `.gitignore`.
- Remove large files from history if already committed.

### **D. Render build issues ("no Dockerfile")**

- For Docker service: ensure `Dockerfile` exists in repo root.
- For Python service: set rootDir=`api`.

### **E. Models not found at runtime**

- Locally: set `$env:MODEL_DIR` before running uvicorn.
- On Render: configure `MODEL_DIR` env variable to point to `api/models_bundles`.

---

## 📝 Useful Commands

**Backend (Windows PowerShell):**

```powershell
cd C:\path\to\edu_buddy\api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
$env:MODEL_DIR = (Resolve-Path .\models_bundles).Path
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

**Build frontend:**

```powershell
cd C:\path\to\edu_buddy\learning_styles_app
flutter clean
flutter pub get
flutter build web --release --dart-define=API_BASE=https://ed-reco.onrender.com
```

**Serve built web locally:**

```powershell
cd learning_styles_app\build\web
python -m http.server 8080
# Open http://localhost:8080
```

**Docker build & run (optional):**

```powershell
cd C:\path\to\edu_buddy
docker build -t edreco-api -f api/Dockerfile .
docker run --rm -p 8000:8000 -e MODEL_DIR=/models -v "${PWD}\api\models_bundles:/models" edreco-api
```

---

## 📦 Delivery Contents

- `api/` (source code, `models_bundles/`, `requirements.txt`)
- `learning_styles_app/build/web/` (production web bundle)
- `render.yaml` (optional)
- `README_DELIVER.md` (this file)
- `run_local.ps1` and `run_local.sh` (helper scripts, optional)

---

## 💬 Contact & Support

If you encounter issues, please provide:

- OS (Windows/macOS/Linux)
- Which step failed (commands & error output)
- Backend logs (uvicorn or Render)

---

**Happy Learning! 🚀**
