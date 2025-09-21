import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

// Android emulator: 10.0.2.2, iOS simulator: localhost
const String kBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:8000',
);

class ApiClient {
  final http.Client _client;
  ApiClient([http.Client? c]) : _client = c ?? http.Client();

  Uri _u(String path) => Uri.parse('$kBaseUrl$path');

  Future<PredictResponse> predict(PredictRequest req) async {
    final res = await _client.post(
      _u('/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (res.statusCode != 200) {
      throw Exception('Predict failed: ${res.statusCode} ${res.body}');
    }
    return PredictResponse.fromJson(jsonDecode(res.body));
  }

  Future<RecommendResponse> recommend(RecommendRequest req) async {
    final res = await _client.post(
      _u('/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (res.statusCode != 200) {
      throw Exception('Recommend failed: ${res.statusCode} ${res.body}');
    }
    return RecommendResponse.fromJson(jsonDecode(res.body));
  }
}
