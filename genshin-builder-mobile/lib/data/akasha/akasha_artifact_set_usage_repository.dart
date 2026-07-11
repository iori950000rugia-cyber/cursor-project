import 'akasha_artifact_set_usage.dart';
import 'akasha_weapon_usage_api.dart';

/// キャラ別聖遺物セット使用率の取得・キャッシュ
class AkashaArtifactSetUsageRepository {
  AkashaArtifactSetUsageRepository({
    AkashaWeaponUsageApi? api,
    this.cacheTtl = const Duration(hours: 6),
    this.pages = 3,
    this.pageSize = 40,
    this.minPieces = 2,
  }) : _api = api ?? AkashaWeaponUsageApi();

  final AkashaWeaponUsageApi _api;
  final Duration cacheTtl;
  final int pages;
  final int pageSize;
  final int minPieces;

  final Map<String, CharacterArtifactSetUsageSnapshot> _cache = {};
  final Map<String, Future<CharacterArtifactSetUsageSnapshot>> _inflight = {};

  Future<CharacterArtifactSetUsageSnapshot> getUsageRates(String characterId) {
    final cached = _cache[characterId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < cacheTtl) {
      return Future.value(cached);
    }

    return _inflight.putIfAbsent(characterId, () async {
      try {
        final snap = await _fetch(characterId);
        if (snap.sampleSize > 0) {
          _cache[characterId] = snap;
          return snap;
        }
        return _empty(characterId);
      } catch (_) {
        return _empty(characterId);
      } finally {
        _inflight.remove(characterId);
      }
    });
  }

  /// 複数キャラを並列取得（同時実行数制限付き）
  Future<List<CharacterArtifactSetUsageSnapshot>> getUsageRatesForCharacters(
    List<String> characterIds, {
    int concurrency = 4,
  }) async {
    final ids = characterIds.where((id) => id.isNotEmpty).toList();
    final results = <CharacterArtifactSetUsageSnapshot>[];
    for (var i = 0; i < ids.length; i += concurrency) {
      final chunk = ids.skip(i).take(concurrency);
      final snaps = await Future.wait(chunk.map(getUsageRates));
      results.addAll(snaps);
    }
    return results;
  }

  Future<CharacterArtifactSetUsageSnapshot> _fetch(String characterId) async {
    final counts = <String, int>{};
    var sampleSize = 0;

    for (var page = 1; page <= pages; page++) {
      final builds = await _api.fetchBuildsPage(
        characterId: characterId,
        page: page,
        size: pageSize,
      );
      if (builds.isEmpty) break;
      sampleSize += builds.length;
      final pageCounts = countArtifactSetsFromBuilds(
        builds,
        minPieces: minPieces,
      );
      for (final e in pageCounts.entries) {
        counts[e.key] = (counts[e.key] ?? 0) + e.value;
      }
    }

    return CharacterArtifactSetUsageSnapshot(
      characterId: characterId,
      rates: artifactSetRatesFromCounts(counts, sampleSize),
      sampleSize: sampleSize,
      source: 'akasha.cv/api/builds',
      fetchedAt: DateTime.now(),
    );
  }

  CharacterArtifactSetUsageSnapshot _empty(String characterId) =>
      CharacterArtifactSetUsageSnapshot(
        characterId: characterId,
        rates: const {},
        sampleSize: 0,
        source: 'heuristic',
        fetchedAt: DateTime.now(),
      );

  void dispose() {
    _api.dispose();
    _cache.clear();
    _inflight.clear();
  }
}
