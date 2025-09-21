# api/Dockerfile  (context = repo root)
FROM python:3.11-slim

WORKDIR /app
ENV PIP_NO_CACHE_DIR=1 PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Install deps
COPY api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App code (run as flat module inside container)
COPY api/app.py api/predict.py ./

# Model artifacts from your local repo (no downloads)
COPY api/models_bundles/ /models/
ENV MODEL_DIR=/models

EXPOSE 8000
CMD ["uvicorn","app:app","--host","0.0.0.0","--port","8000"]
