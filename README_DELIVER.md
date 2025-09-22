
EDU_BUDDY — README_DELIVER.md (Delivery / Quickstart & Runbook)
EDU_BUDDY — README_DELIVER.md (Delivery / Quickstart & Runbook)

This file explains exactly how to run the project locally, how to build the Flutter web bundle, and how to deploy the API to Render and the frontend to Netlify.
It's written so a non-expert can follow step-by-step. Follow the Windows instructions unless you are on macOS/Linux (Bash commands are provided).

Quick summary (one-line)

•	Start backend: create venv → install requirements → uvicorn app:app --host 0.0.0.0 --port 8000
•	Build frontend: flutter build web --release --dart-define=API_BASE=https://<your-render-url>
•	Serve the build locally: python -m http.server 8080 (from learning_styles_app/build/web)
•	Deploy backend to Render (rootDir = api, build: pip install -r requirements.txt, start: uvicorn app:app --host 0.0.0.0 --port 10000)
•	Deploy frontend to Netlify (drag/drop build/web or Netlify Git build)

0 — Requirements (install first)

Install these before attempting to run:
•	Git — https://git-scm.com
•	Python 3.11+ — https://www.python.org
•	pip (comes with Python)
•	Flutter SDK — https://flutter.dev (for building web)
•	Node.js & npm (optional; for Netlify CLI) — https://nodejs.org
•	Docker Desktop (optional; for running the API in Docker) — https://www.docker.com
•	Netlify account (optional) — https://app.netlify.com
•	Render account — https://dashboard.render.com
•	A code editor (VS Code recommended)
•	A modern browser (Chrome recommended for dev tools)

1 — Before you start: important repo hygiene

1.	Ensure .gitignore contains:
2.	# virtual envs
3.	.venv/
4.	venv/
5.	api/.venv/
6.	learning_styles_app/.dart_tool/
7.	learning_styles_app/build/
8.	Do not commit  .venv or build artifacts (unless you intend to deliver the learning_styles_app/build/web bundle).
9.	Make sure api/models_bundles/ is included and contains your model files — the API needs these.

2 — Running the API locally (Windows — PowerShell)

Open PowerShell and run these commands from the repo root.
Step A — create & activate venv (once)
cd C:\path\to\edu_buddy\api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
Step B — install dependencies
If you shipped a wheels/ directory (faster):
pip install --upgrade pip
pip install --no-index --find-links=./wheels -r requirements.txt
Otherwise:
pip install --upgrade pip
pip install -r requirements.txt
Step C — (optional) set model path env var (session)
$env:MODEL_DIR = (Resolve-Path .\models_bundles).Path
$env:SCHEMA_PATH = (Resolve-Path .\models_bundles\feature_columns.json).Path  # if used by your code
Step D — run the API
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
•	Visit http://localhost:8000/health to verify the API is up.
•	Visit http://localhost:8000/docs for FastAPI interactive docs (if present).

3 — Running the API locally (macOS / Linux — Bash)

cd /path/to/edu_buddy/api
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
export MODEL_DIR="$(pwd)/models_bundles"
export SCHEMA_PATH="$(pwd)/models_bundles/feature_columns.json"  # if used
uvicorn app:app --host 0.0.0.0 --port 8000 --reload

4 — (Optional) Running API in Docker (recommended for parity)
From the repo root (where api/Dockerfile is located):
Build:
cd C:\path\to\edu_buddy
docker build -t edreco-api -f api/Dockerfile .
Run (mount models into container):
docker run --rm -p 8000:8000 -e MODEL_DIR=/models -v "${PWD}\api\models_bundles:/models" edreco-api
•	The container will run uvicorn (depending on your Dockerfile). Adjust the port if needed.
5 — Flutter: run dev & build web
•	5.1 Development run (hot reload)
Open a new terminal window and run:
cd C:\path\to\edu_buddy\learning_styles_app
flutter clean
flutter pub get
flutter run -d web-server --dart-define=API_BASE=http://localhost:8000
•	This opens a Chrome window with the Flutter app pointing to your local backend.

5.2 Build production web bundle
Decide whether you want the built frontend to call the local API or the deployed Render API:
•	To target the deployed Render API (recommended when preparing the delivery):
•	cd learning_styles_app
•	flutter clean
•	flutter pub get
•	flutter build web --release --dart-define=API_BASE=https://ed-reco.onrender.com
Replace https://ed-reco.onrender.com with your actual Render URL.
•	To target local API for production-like testing:
•	flutter build web --release --dart-define=API_BASE=http://localhost:8000
Output folder: learning_styles_app/build/web/
________________________________________
6 — Serve the built web locally (quick test)
From the built web folder:
cd learning_styles_app\build\web
python -m http.server 8080
# Open: http://localhost:8080
Or use Docker nginx:
docker run --rm -p 8080:80 -v "${PWD}:/usr/share/nginx/html:ro" nginx:alpine
________________________________________
7 — Deploy the API to Render (UI steps)
(A) Create a Render account and connect to your GitHub repo.
(B) Create a new Web Service:
•	Environment: Python 3
•	Root Directory: api
•	Build Command: pip install -r requirements.txt
(or: pip install --no-index --find-links=./wheels -r requirements.txt if you included wheels/)
•	Start Command: uvicorn app:app --host 0.0.0.0 --port 10000
•	Health check path: /health
•	Plan: free (or higher if you need)
•	Set environment variables: if your app expects MODEL_DIR or SCHEMA_PATH, set them in the Render service env vars. Example:
o	MODEL_DIR = /opt/render/project/src/api/models_bundles
o	SCHEMA_PATH = /opt/render/project/src/api/models_bundles/feature_columns.json
Deploy — after build you’ll get a URL like https://ed-reco.onrender.com. Use that as API_BASE for frontend builds.
Alternative: Use the render.yaml (if included). Render will use those settings automatically when creating the service with the "Use render.yaml" option.
________________________________________
8 — Deploy the frontend to Netlify
A — Drag & drop (fast)
•	1.	Build the web bundle (see Step 5.2).
•	2.	Go to Netlify → New site from drag & drop → upload the contents of learning_styles_app/build/web.
•	3.	Netlify gives you a site URL.
B — Git-based (recommended)
•	1.	Connect Netlify to your GitHub repo.
•	2.	Set the site build settings:
o	Base directory: learning_styles_app
o	Build command:
o	flutter build web --release --dart-define=API_BASE=https://ed-reco.onrender.com
o	Publish directory: learning_styles_app/build/web
1.	Netlify will run that build and publish automatically on each push.
Important: If your Flutter project uses --dart-define=API_BASE=..., ensure the Netlify build command includes the correct Render URL.
________________________________________
9 — What to open & when (non-technical guide)
•	When setting up locally:
o	Open PowerShell / Terminal A: run the backend (API).
o	Open PowerShell / Terminal B: run Flutter dev or build the web bundle.
o	Open Browser (Chrome): use it to open http://localhost:8080 (frontend), http://localhost:8000/health (backend health), and http://localhost:8000/docs (API docs).
When deploying:
o	Log in to Render to watch the API deploy logs.
o	Log in to Netlify to watch the frontend deploy logs.
________________________________________
10 — Troubleshooting (common issues)
A. ClientException: Failed to fetch in Flutter web
•	•	Usually the frontend cannot reach the API or CORS blocked.
•	•	Fixes:
•	1.	Ensure you built the frontend with the correct API_BASE (--dart-define).
•	2.	Ensure the API is reachable (test curl http://localhost:8000/health).
•	3.	If CORS errors appear in browser console, ensure app.py has correct CORS middleware:
•	4.	from fastapi.middleware.cors import CORSMiddleware
•	5.	app.add_middleware(
•	6.	    CORSMiddleware,
•	7.	    allow_origins=["*"],   # dev only - restrict in prod
•	8.	    allow_credentials=True,
•	9.	    allow_methods=["*"],
•	10.	    allow_headers=["*"],
•	11.	)
B. 404 on / after deploy
•	•	Add a root route to api/app.py:
•	•	@app.get("/")
•	•	def read_root():
•	•	    return {"message": "Welcome to Style Recommender API"}
C. Git push rejected due to large files
•	•	Do not commit .venv or .dll files. Add .venv/ to .gitignore. If large files are already committed, remove them from history (use git filter-repo or start a fresh repo).
D. Render build says “no Dockerfile” or expects Docker
•	•	If you created a Docker service, ensure a Dockerfile exists in repo root. If you want to use Render's Python environment instead, create the service as a Python service and set rootDir=api.
E. Models not found at runtime
•	•	Ensure MODEL_DIR is correctly set for your runtime:
o	Locally: set $env:MODEL_DIR before running uvicorn.
o	On Render: configure MODEL_DIR environment variable to point to api/models_bundles.
________________________________________
11 — Useful commands (copy/paste)
Backend (Windows PowerShell)
cd C:\path\to\edu_buddy\api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
$env:MODEL_DIR = (Resolve-Path .\models_bundles).Path
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
Build frontend (Windows PowerShell)
cd C:\path\to\edu_buddy\learning_styles_app
flutter clean
flutter pub get
flutter build web --release --dart-define=API_BASE=https://ed-reco.onrender.com
Serve built web locally
cd learning_styles_app\build\web
python -m http.server 8080
# open http://localhost:8080
Docker build & run (optional)
cd C:\path\to\edu_buddy
docker build -t edreco-api -f api/Dockerfile .
docker run --rm -p 8000:8000 -e MODEL_DIR=/models -v "${PWD}\api\models_bundles:/models" edreco-api
________________________________________
12 — What I included in this delivery
•	api/ (source code, models_bundles/, requirements.txt)
•	learning_styles_app/build/web/ (production web bundle) 
•	render.yaml (optional)
•	README_DELIVER.md (this file)
•	run_local.ps1 and run_local.sh (helper scripts) — optional
________________________________________
13 — Contact & support
If you encounters issues, please provide:
•	OS (Windows/macOS/Linux),
•	Which step failed (commands copied and exact error output),
•	The logs from the backend uvicorn window or Render logs.
