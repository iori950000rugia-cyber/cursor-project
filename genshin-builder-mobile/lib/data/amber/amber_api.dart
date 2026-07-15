import 'dart:isolate';

import 'package:http/http.dart' as http;

import '../artifact_score/artifact_score_type_override_registry.dart';
import '../config/remote_json_fetch.dart';
import '../models/master_models.dart';
import '../../domain/artifact_score.dart';
import 'amber_constants.dart';
import 'amber_master_parsers.dart';

class AmberApi {
  AmberApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const name = 'project-amber';
  static const _apiPrefix = '/api/v2/jp';
  static const _timeout = Duration(seconds: 30);
  static const _masterMaxBytes = 8 * 1024 * 1024;
  static const _detailMaxBytes = 2 * 1024 * 1024;
  static const _staticMaxBytes = 4 * 1024 * 1024;

  Future<Map<String, dynamic>> _fetchItems(String path) async {
    final json = await fetchRemoteJsonMap(
      client: _client,
      url: '$amberBaseUrl$_apiPrefix$path',
      kind: 'amber-master',
      timeout: _timeout,
      maxBytes: _masterMaxBytes,
    );
    if (json['response'] != 200) {
      throw const FormatException('Invalid Amber response status');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic> ||
        data['items'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid Amber items payload');
    }
    final items = data['items'] as Map<String, dynamic>;
    if (items.isEmpty) {
      throw const FormatException('Empty Amber items payload');
    }
    return items;
  }

  Future<Map<String, dynamic>> _fetchDetail(String path) async {
    final json = await fetchRemoteJsonMap(
      client: _client,
      url: '$amberBaseUrl$_apiPrefix$path',
      kind: 'amber-detail',
      timeout: _timeout,
      maxBytes: _detailMaxBytes,
    );
    if (json['response'] != 200) {
      throw const FormatException('Invalid Amber response status');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid Amber detail payload');
    }
    return data;
  }

  /// 言語非依存の static データ（成長曲線など）を取得する。
  /// 例: `/avatarCurve`, `/weaponCurve`
  Future<Map<String, dynamic>> fetchStaticData(String path) async {
    final json = await fetchRemoteJsonMap(
      client: _client,
      url: '$amberBaseUrl/api/v2/static$path',
      kind: 'amber-static',
      timeout: _timeout,
      maxBytes: _staticMaxBytes,
    );
    if (json['response'] != 200) {
      throw const FormatException('Invalid Amber response status');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid Amber static payload');
    }
    return data;
  }

  Future<List<MasterCharacter>> fetchCharacters() async {
    final overrideRegistry = ArtifactScoreTypeOverrideRegistry.instance;
    await overrideRegistry.ensureLoaded();
    final nameOverrides = overrideRegistry.byName;

    final items = await _fetchItems('/avatar');
    final payload = <String, dynamic>{
      'items': items,
      'nameOverrides': {
        for (final e in nameOverrides.entries)
          e.key: artifactScoreTypeToStorage(e.value),
      },
    };
    final characters = await Isolate.run(
      () => parseCharactersIsolatePayload(payload),
    );
    _validateUniqueSnapshot(
      characters,
      (item) => item.id,
      isValid: (item) => item.rarity == 4 || item.rarity == 5,
    );
    return characters;
  }

  Future<List<MasterWeapon>> fetchWeapons() async {
    final items = await _fetchItems('/weapon');
    final weapons = await Isolate.run(() => parseWeaponsFromAmberItems(items));
    _validateUniqueSnapshot(
      weapons,
      (item) => item.id,
      isValid: (item) => item.rarity >= 1 && item.rarity <= 5,
    );
    return weapons;
  }

  Future<List<MasterMaterial>> fetchMaterials() async {
    final items = await _fetchItems('/material');
    final materials = await Isolate.run(
      () => parseMaterialsFromAmberItems(items),
    );
    _validateUniqueSnapshot(
      materials,
      (item) => item.id,
      isValid:
          (item) =>
              item.rarity == null || (item.rarity! >= 1 && item.rarity! <= 5),
    );
    return materials;
  }

  /// 一覧件数のみ（プローブ用。突破詳細は取得しない）。3 エンドポイント並列。
  Future<({int characters, int weapons, int materials})>
  fetchMasterListCounts() async {
    final results = await Future.wait([
      _fetchItems('/avatar'),
      _fetchItems('/weapon'),
      _fetchItems('/material'),
    ]);
    final avatars = results[0];
    final weapons = results[1];
    final materials = results[2];
    return (
      characters: countSyncableCharactersFromAmberItems(avatars),
      weapons: weapons.length,
      materials: materials.length,
    );
  }

  Future<Map<String, dynamic>> fetchAvatarDetail(String id) =>
      _fetchDetail('/avatar/$id');

  Future<Map<String, dynamic>> fetchWeaponDetail(String id) =>
      _fetchDetail('/weapon/$id');

  Future<Map<String, dynamic>> fetchReliquaryItems() async {
    return _fetchItems('/reliquary');
  }

  void close() => _client.close();

  void dispose() => close();
}

void _validateUniqueSnapshot<T>(
  List<T> items,
  String Function(T item) idOf, {
  required bool Function(T item) isValid,
}) {
  if (items.isEmpty) {
    throw const FormatException('Empty master snapshot');
  }
  final ids = <String>{};
  for (final item in items) {
    final id = idOf(item).trim();
    if (id.isEmpty || id == 'null' || !ids.add(id) || !isValid(item)) {
      throw const FormatException('Invalid master record');
    }
  }
}
