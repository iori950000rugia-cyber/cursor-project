import 'dart:convert';

import 'package:http/http.dart' as http;

import 'artifact_score_weight.dart';
import 'artifact_score_weight_source.dart';

class RemoteArtifactScoreWeightSource
    implements RefreshableArtifactScoreWeightSource {
  RemoteArtifactScoreWeightSource({
    required this.url,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final String url;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<List<ArtifactScoreWeightProfile>> loadProfiles() => refreshProfiles();

  @override
  Future<List<ArtifactScoreWeightProfile>> refreshProfiles() async {
    if (url.isEmpty) return const [];
    final response = await _client.get(Uri.parse(url)).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('artifact score weights remote error: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['profiles'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ArtifactScoreWeightProfile.fromJson)
        .toList(growable: false);
    return list;
  }
}
