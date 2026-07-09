import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/artifact_score.dart';
import 'artifact_score_type_override.dart';

class LocalJsonArtifactScoreTypeOverrideSource {
  LocalJsonArtifactScoreTypeOverrideSource({
    AssetBundle? bundle,
    this.assetPath = 'assets/config/artifact_score_type_overrides.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;
  Map<String, ArtifactScoreType>? _byNameCache;
  Map<String, ArtifactScoreType>? _byIdCache;

  Future<List<ArtifactScoreTypeOverride>> loadOverrides() async {
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (decoded['overrides'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ArtifactScoreTypeOverride.fromJson)
        .toList(growable: false);
  }

  Future<Map<String, ArtifactScoreType>> loadByName() async {
    if (_byNameCache != null) return _byNameCache!;
    final overrides = await loadOverrides();
    _byNameCache = {
      for (final item in overrides)
        if (item.name.isNotEmpty) item.name: item.scoreType,
    };
    return _byNameCache!;
  }

  Future<Map<String, ArtifactScoreType>> loadByCharacterId() async {
    if (_byIdCache != null) return _byIdCache!;
    final overrides = await loadOverrides();
    _byIdCache = {
      for (final item in overrides)
        if (item.characterId.isNotEmpty) item.characterId: item.scoreType,
    };
    return _byIdCache!;
  }
}
