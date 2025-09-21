# EduBuddy Web App — One‑Pager Ops Runbook

**Components**
- **Backend**: FastAPI (Python) under `api/`
- **Frontend**: Flutter Web static bundle under `learning_styles_app/build/web/`

**Key Paths**
- Backend code: `api/app.py`, `api/predict.py`
- Backend artifacts: `api/models_bundles/`
- Frontend static bundle: `learning_styles_app/build/web/`
- Render manifest: `render.yaml`

---

## Run Backend Locally (Python)
```bash
# From repo root
python -m venv .venv
.venv\Scripts\Activate # Windows: .venv\Scripts\activate 
pip install -r api/requirements.txt
uvicorn api.app:app --host 0.0.0.0 --port 8000 --reload
```


# Open another terminal in root folder while keeping the previous one running

**Health check**

```bash
curl http://localhost:8000/health
```

**Predict (example POST)**
```bash
curl.exe -X POST http://localhost:8000/predict   -H "Content-Type: application/json"   -d '{"features": {"age": 21, "hours_study": 2.5}}'
```

---

## Run Backend in Docker
First start docker in the background
```bash
# From repo root
docker build -t edubuddy-api ./api
docker run --rm -p 8000:8000 edubuddy-api
# Health
curl http://localhost:8000/health
```

---

## Host Frontend (Static)
You already have a production build at `learning_styles_app/build/web/`.

**Option A — Netlify (drag & drop)**
1) Go to app.netlify.com → Add new site → Deploy manually.  
2) Drag `learning_styles_app/build/web/` folder.  
3) After deploy, open the site URL.

**Option B — Vercel (static)**
1) Create a new project, framework: "Other".  
2) Set build output directory to `learning_styles_app/build/web`.  
3) Deploy.

**Option C — Any static server (local)**
```bash
# Python 3
cd learning_styles_app/build/web
python -m http.server 8080
# Open http://localhost:8080
```

> Ensure the frontend calls the correct backend base URL configured in `learning_styles_app/lib/api.dart` before building.

---

## Deploy on Render (API + Static Site)
Render can deploy the API as a **Web Service** (Docker) and the frontend as a **Static Site**.

1) Push repo to GitHub.  
2) In Render, "New +" → **Web Service** → select repo → root is `/` → it will build via `api/Dockerfile`.  
3) Expose port **8000** (or as defined by your app).  
4) "New +" → **Static Site** → set "Publish Directory" to `learning_styles_app/build/web`.  
5) Open the Static Site URL and verify it can reach your API.

---

## CORS
If your frontend is on a different origin, enable CORS in FastAPI (in `api/app.py`):
```python
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten to your domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## Rebuild Frontend (only if you change `api.dart`)
```bash
# Install Flutter if needed, then:
cd learning_styles_app
flutter clean
flutter build web --release
# Output at: learning_styles_app/build/web/
```

---

## Quick Verification Checklist
- API `/health` returns 200 locally and in the cloud.
- Frontend can load JS bundle and call the API (check browser DevTools → Network).
- CORS: No blocked requests in console.
- Docker image starts and binds to 0.0.0.0:8000.
- Render Static Site "Publish Directory" is `learning_styles_app/build/web`.
