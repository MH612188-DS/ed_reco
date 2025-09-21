// lib/models.dart
typedef Json = Map<String, dynamic>;

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

/// ---------- /predict ----------

class PredictRequest {
  final Json features; // one feature row
  PredictRequest(this.features);

  // API expects { "records": [ { ... } ] }
  Json toJson() => {"records": [features]};
}

class PredictResponse {
  final double pVv, pAr, pSg;

  PredictResponse({
    required this.pVv,
    required this.pAr,
    required this.pSg,
  });

  // API returns { "results": [ { proba_* } ] }
  factory PredictResponse.fromJson(Json json) {
    final list = (json["results"] as List);
    final row = list.first as Json;
    return PredictResponse(
      pVv: _asDouble(row["proba_visual_verbal"]),
      pAr: _asDouble(row["proba_active_reflective"]),
      pSg: _asDouble(row["proba_global_sequential"]),
    );
  }
}

/// ---------- /recommend ----------

class RecommendRequest {
  final int idStudent;
  final Json features;
  final int topK;

  RecommendRequest({
    required this.idStudent,
    required this.features,
    this.topK = 3,
  });

  // Backend expects { "id_student": ..., "row": { ... }, "topK": ... }
  Json toJson() => {
        "id_student": idStudent,
        "row": features,
        "topK": topK,
      };
}

class Recommendation {
  final String armId;
  final String text;
  final double score;

  Recommendation({
    required this.armId,
    required this.text,
    required this.score,
  });

  // Backend sends tuples: ["V1", "Create a concept map...", 0.873]
  factory Recommendation.fromTuple(List<dynamic> t) => Recommendation(
        armId: (t[0] as String),
        text: (t[1] as String),
        score: _asDouble(t[2]),
      );
}

class RecommendResponse {
  final List<Recommendation> recs;
  final Json meta;

  RecommendResponse({required this.recs, required this.meta});

  // Backend returns { "recs": [ [..], [..] ], "meta": {...} }
  factory RecommendResponse.fromJson(Json json) {
    final recsJson = (json["recs"] as List).cast<List<dynamic>>();
    return RecommendResponse(
      recs: recsJson.map(Recommendation.fromTuple).toList(),
      meta: (json["meta"] as Json?) ?? <String, dynamic>{},
    );
  }
}
