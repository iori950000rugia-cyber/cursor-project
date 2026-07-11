import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/calculation_models.dart';
import 'level_exp_table_builder.dart';

/// `assets/config/level_exp_table.json` からレベル EXP セグメントを読み込む。
class LevelExpTableSource {
  LevelExpTableSource({
    AssetBundle? bundle,
    this.assetPath = 'assets/config/level_exp_table.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  List<LevelExpSegment>? _cache;

  Future<List<LevelExpSegment>> loadSegments() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cache = LevelExpTableBuilder.buildFromJson(decoded);
    return _cache!;
  }
}
