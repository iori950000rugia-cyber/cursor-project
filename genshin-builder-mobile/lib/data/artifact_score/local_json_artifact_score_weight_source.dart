import 'dart:convert';

import 'package:flutter/services.dart';

import 'artifact_score_weight.dart';
import 'artifact_score_weight_source.dart';

class LocalJsonArtifactScoreWeightSource implements ArtifactScoreWeightSource {
  LocalJsonArtifactScoreWeightSource({
    AssetBundle? bundle,
    this.assetPath = 'assets/config/artifact_score_weights.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;
  List<ArtifactScoreWeightProfile>? _cache;

  @override
  Future<List<ArtifactScoreWeightProfile>> loadProfiles() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['profiles'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ArtifactScoreWeightProfile.fromJson)
        .toList(growable: false);
    _cache = items;
    return items;
  }
}
