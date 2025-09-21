# app.py
# FastAPI wrapper around predict.py + simple recommend endpoint

from __future__ import annotations
import io, os, typing as T
from pathlib import Path
import pandas as pd
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
# api/app.py
try:
    # When run as a package (e.g., uvicorn api.app:app)
    from .predict import StyleInferenceService, TAGS
except ImportError:
    # When run as a flat module (e.g., inside Docker: uvicorn app:app)
    from predict import StyleInferenceService, TAGS


# --- Model paths (default: ./models_bundles next to this file) ---
HERE = Path(__file__).resolve().parent
MODEL_DIR = os.environ.get("MODEL_DIR", str(HERE / "models_bundles"))
SCHEMA_PATH = os.environ.get("SCHEMA_PATH", str(Path(MODEL_DIR) / "feature_columns.json"))

app = FastAPI(title="Style Recommender Inference API", version="1.1.0")

# --- CORS (allow local dev; tighten for prod) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        #"https://edreco-web.onrender.com"
       # "http://localhost:5173","http://127.0.0.1:5173",
        #"http://localhost:8080","http://127.0.0.1:8080",
       # "http://localhost:8000","http://127.0.0.1:8000",
       "*"
    ],
    allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
)

# ---------- Lazy-loaded singleton service ----------
_SERVICE: StyleInferenceService | None = None
def _svc() -> StyleInferenceService:
    global _SERVICE
    if _SERVICE is None:
        _SERVICE = StyleInferenceService(model_dir=MODEL_DIR, schema_path=SCHEMA_PATH)
    return _SERVICE

# ---------- DTOs ----------
class PredictRequest(BaseModel):
    records: T.Union[T.Dict[str, T.Any], T.List[T.Dict[str, T.Any]]]

class PredictResponseItem(BaseModel):
    row_id: int
    proba_visual_verbal: float
    proba_active_reflective: float
    proba_global_sequential: float

class PredictResponse(BaseModel):
    results: T.List[PredictResponseItem]

class RecommendRequest(BaseModel):
    id_student: int
    row: T.Dict[str, T.Any]
    topK: int = 3

# ---------- Strategy catalog + heuristic ----------
STRATEGIES = {
    # Visual / Verbal
    'V1': 'Create a concept map for current topic',
    'V2': 'Sketchnote main ideas from the last module',
    'V3': 'Color-code summary sheets',
    'B1': 'Explain the topic aloud (rubber-duck for 3 min)',
    'B2': 'Write a 150-word summary',
    'B3': 'Record a 60-sec audio memo of key takeaways',
    # Active / Reflective
    'A1': 'Attempt 5 practice quiz items now',
    'A2': 'Post a one-question prompt on the forum',
    'A3': 'Do a quick self-test (10 flashcards)',
    'R1': 'Read module page & note 3 reflections',
    'R2': 'Pause video every 3 min to note 1 insight',
    'R3': 'Rewrite the steps of a worked example',
    # Global / Sequential
    'G1': 'Preview the whole module outline first',
    'G2': 'Draft a one-page overview connecting sections',
    'S1': 'Follow step-by-step checklist for this unit',
    'S2': 'Study subtopic → mini-quiz → next subtopic loop',
}

def candidate_arms(p_vv: float, p_ar: float, p_sg: float):
    arms: list[tuple[str, float]] = []
    # Visual vs Verbal
    if p_vv >= 0.6:
        arms += [('V1', p_vv), ('V2', p_vv*0.95), ('V3', p_vv*0.9)]
    else:
        inv = 1 - p_vv
        arms += [('B1', inv), ('B2', inv*0.95), ('B3', inv*0.9)]
    # Active vs Reflective
    if p_ar >= 0.6:
        arms += [('A1', p_ar), ('A2', p_ar*0.95), ('A3', p_ar*0.9)]
    else:
        inv = 1 - p_ar
        arms += [('R1', inv), ('R2', inv*0.95), ('R3', inv*0.9)]
    # Global vs Sequential
    if p_sg >= 0.6:
        arms += [('G1', p_sg), ('G2', p_sg*0.95)]
    else:
        inv = 1 - p_sg
        arms += [('S1', inv), ('S2', inv*0.95)]

    # dedupe keeping max weight, then sort desc
    best: dict[str, float] = {}
    for a, w in arms:
        if a not in best or w > best[a]:
            best[a] = w
    return sorted(best.items(), key=lambda t: t[1], reverse=True)

# ---------- Routes ----------
@app.get("/health")
def health():
    try:
        svc = _svc()
        return {"status": "ok", "model_dir": MODEL_DIR, "n_features": len(svc.feature_names), "tags": list(TAGS)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/feature-names")
def feature_names():
    svc = _svc()
    return {"feature_names": svc.feature_names}

@app.post("/predict", response_model=PredictResponse)
def predict_json(req: PredictRequest):
    svc = _svc()
    recs = req.records
    if isinstance(recs, dict):
        recs = [recs]
    if not isinstance(recs, list) or not recs:
        raise HTTPException(status_code=400, detail="Provide non-empty 'records' (dict or list of dicts).")
    df = pd.DataFrame(recs)
    preds = svc.predict(df)
    results = [
        {
            "row_id": int(i),
            "proba_visual_verbal": float(r["proba_visual_verbal"]),
            "proba_active_reflective": float(r["proba_active_reflective"]),
            "proba_global_sequential": float(r["proba_global_sequential"]),
        }
        for i, (_, r) in enumerate(preds.iterrows())
    ]
    return {"results": results}

@app.post("/predict-csv")
async def predict_csv(file: UploadFile = File(...)):
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")
    content = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(content))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not read CSV: {e}")
    svc = _svc()
    preds = svc.predict(df)
    out = df.copy()
    out["proba_visual_verbal"]     = preds["proba_visual_verbal"].values
    out["proba_active_reflective"] = preds["proba_active_reflective"].values
    out["proba_global_sequential"] = preds["proba_global_sequential"].values
    buf = io.StringIO()
    out.to_csv(buf, index=False)
    buf.seek(0)
    return {"filename": file.filename, "rows": int(out.shape[0]), "cols": int(out.shape[1]), "csv": buf.getvalue()}

@app.post("/recommend")
def recommend(req: RecommendRequest):
    """
    Minimal heuristic recommender:
    - uses model probabilities from StyleInferenceService
    - ranks a fixed strategy catalog by those probs
    - returns topK [(arm_id, text, score), ...] plus meta (p vector)
    """
    svc = _svc()
    df = pd.DataFrame([req.row])
    pred = svc.predict(df).iloc[0]
    p_vv = float(pred["proba_visual_verbal"])
    p_ar = float(pred["proba_active_reflective"])
    p_sg = float(pred["proba_global_sequential"])

    ranked = candidate_arms(p_vv, p_ar, p_sg)
    top = ranked[: max(1, int(req.topK))]
    recs = [(a, STRATEGIES.get(a, a), float(s)) for a, s in top]
    meta = {"id_student": int(req.id_student), "p": [p_vv, p_ar, p_sg]}
    return {"recs": recs, "meta": meta}

@app.post("/reload")
def reload_models():
    global _SERVICE
    _SERVICE = None
    _ = _svc()  # re-init to validate
    return {"status": "reloaded"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=int(os.getenv("PORT", 8000)), reload=False)
