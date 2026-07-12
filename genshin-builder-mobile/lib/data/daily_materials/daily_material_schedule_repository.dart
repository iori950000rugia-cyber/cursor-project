import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/daily_materials/daily_material_models.dart';
import '../config/config_load_log.dart';
import '../config/config_validators.dart';

const _configKind = 'daily_material_schedule';

abstract class DailyMaterialScheduleSource {
  Future<DailyMaterialSchedule> load();
}

class LocalJsonDailyMaterialScheduleSource
    implements DailyMaterialScheduleSource {
  LocalJsonDailyMaterialScheduleSource({
    AssetBundle? bundle,
    this.assetPath = 'assets/config/daily_material_schedule.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;
  DailyMaterialSchedule? _cache;

  @override
  Future<DailyMaterialSchedule> load() async {
    if (_cache != null) return _cache!;
    late final String raw;
    try {
      raw = await _bundle.loadString(assetPath);
    } catch (_) {
      throw const ConfigLoadException(
        kind: _configKind,
        failure: ConfigLoadFailureKind.assetMissing,
      );
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const ConfigLoadException(
        kind: _configKind,
        failure: ConfigLoadFailureKind.invalidJson,
      );
    }

    if (decoded is! Map) {
      throw const ConfigLoadException(
        kind: _configKind,
        failure: ConfigLoadFailureKind.invalidRootType,
      );
    }
    final map = Map<String, dynamic>.from(decoded);

    try {
      validateDailyMaterialScheduleJson(map);
    } on FormatException catch (e) {
      throw configLoadFromFormatException(kind: _configKind, error: e);
    }

    try {
      _cache = DailyMaterialSchedule.fromJson(map);
      return _cache!;
    } catch (_) {
      throw const ConfigLoadException(
        kind: _configKind,
        failure: ConfigLoadFailureKind.unexpected,
      );
    }
  }
}

class DailyMaterialScheduleRepository {
  DailyMaterialScheduleRepository(this._source);

  final DailyMaterialScheduleSource _source;

  Future<DailyMaterialSchedule> getSchedule() => _source.load();
}
