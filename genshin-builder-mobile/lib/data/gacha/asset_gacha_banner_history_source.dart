import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/gacha/gacha_banner_schedule.dart';
import '../config/config_load_log.dart';

abstract class GachaBannerHistorySource {
  Future<GachaBannerSchedule> load();
}

const _configKind = 'gacha_banner_history';

class AssetGachaBannerHistorySource implements GachaBannerHistorySource {
  AssetGachaBannerHistorySource({
    AssetBundle? bundle,
    this.assetPath = 'assets/config/gacha_banner_history.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  @override
  Future<GachaBannerSchedule> load() async {
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
      return GachaBannerSchedule.fromJson(map);
    } on FormatException catch (e) {
      throw configLoadFromFormatException(kind: _configKind, error: e);
    } catch (_) {
      throw const ConfigLoadException(
        kind: _configKind,
        failure: ConfigLoadFailureKind.unexpected,
      );
    }
  }
}
