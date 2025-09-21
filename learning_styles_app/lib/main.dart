import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'models.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

final featureStateProvider = StateProvider<Map<String, dynamic>>((ref) => {
  // Replace with the columns your backend expects
  "weekly_click_slope": 0.0,
  "wk_entropy_slope": 0.0,
  "content_prop": 0.2,
  "forum_prop": 0.1,
  "quiz_prop": 0.3,
  "url_prop": 0.1,
  "nav_entropy": 0.5,
  "total_clicks": 120,
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Styles',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(featureStateProvider);
    final idCtrl = TextEditingController(text: "10001");

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Styles Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Features", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._featureEditors(ref, features),
          const Divider(height: 32),
          TextField(
            controller: idCtrl,
            decoration: const InputDecoration(
              labelText: "Student ID",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _doPredict(context, ref),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text("Predict"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    final id = int.tryParse(idCtrl.text) ?? 0;
                    _doRecommend(context, ref, id);
                  },
                  icon: const Icon(Icons.recommend_outlined),
                  label: const Text("Recommend"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _featureEditors(WidgetRef ref, Map<String, dynamic> features) {
    final keys = [
      "weekly_click_slope",
      "wk_entropy_slope",
      "content_prop",
      "forum_prop",
      "quiz_prop",
      "url_prop",
      "nav_entropy",
      "total_clicks",
    ];
    return keys.map((k) {
      final ctrl = TextEditingController(text: "${features[k]}");
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: k, border: const OutlineInputBorder()),
          onChanged: (v) {
            final asNum = double.tryParse(v);
            ref.read(featureStateProvider.notifier).update((m) => {
              ...m,
              k: k == "total_clicks" ? (asNum?.toInt() ?? m[k]) : (asNum ?? m[k]),
            });
          },
        ),
      );
    }).toList();
  }

  Future<void> _doPredict(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiProvider);
    final features = ref.read(featureStateProvider);
    try {
      final resp = await api.predict(PredictRequest(features));
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Predictions"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _probTile("Visual vs Verbal", resp.pVv),
              _probTile("Active vs Reflective", resp.pAr),
              _probTile("Global vs Sequential", resp.pSg),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
    } catch (e) {
      _snack(context, "Predict failed: $e");
    }
  }

  Future<void> _doRecommend(BuildContext context, WidgetRef ref, int id) async {
    final api = ref.read(apiProvider);
    final features = ref.read(featureStateProvider);
    try {
      final resp = await api.recommend(RecommendRequest(idStudent: id, features: features));
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => _RecommendationsSheet(resp),
      );
    } catch (e) {
      _snack(context, "Recommend failed: $e");
    }
  }

  ListTile _probTile(String title, double p) {
    final pct = (p * 100).toStringAsFixed(1);
    return ListTile(dense: true, title: Text(title), trailing: Text("$pct%"));
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _RecommendationsSheet extends StatelessWidget {
  final RecommendResponse r;
  const _RecommendationsSheet(this.r, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = (r.meta["p"] as List?)?.cast<num>().map((e) => e.toDouble()).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Recommendations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (p != null) ...[
            const SizedBox(height: 6),
            Text("p_vv=${p[0].toStringAsFixed(2)}  p_ar=${p[1].toStringAsFixed(2)}  p_sg=${p[2].toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.black54)),
          ],
          const SizedBox(height: 12),
          for (final rec in r.recs)
            Card(
              child: ListTile(
                title: Text(rec.text),
                subtitle: Text("Arm: ${rec.armId}"),
                trailing: Text(rec.score.toStringAsFixed(3)),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
