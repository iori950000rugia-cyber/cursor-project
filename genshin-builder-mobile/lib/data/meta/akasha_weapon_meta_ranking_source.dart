import '../../domain/meta/meta_ranking_source.dart';
import '../akasha/akasha_weapon_usage_repository.dart';

/// Akasha 武器使用率を MetaRankingSource として公開するアダプタ。
class AkashaWeaponMetaRankingSource implements MetaRankingSource {
  AkashaWeaponMetaRankingSource(this._usage);

  final AkashaWeaponUsageRepository _usage;

  static const kindWeaponUsage = 'weapon_usage';

  @override
  Future<MetaRankingSnapshot> fetchRanking({
    required String kind,
    required String contextId,
  }) async {
    if (kind != kindWeaponUsage) {
      return MetaRankingSnapshot(
        contextId: contextId,
        entries: const [],
        source: 'unsupported:$kind',
        fetchedAt: DateTime.now(),
      );
    }

    final snap = await _usage.getUsageRates(contextId);
    final entries = [
      for (final e in snap.rates.entries)
        MetaRankingEntry(
          entityId: e.key,
          score: e.value,
          sampleSize: snap.sampleSize,
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return MetaRankingSnapshot(
      contextId: contextId,
      entries: entries,
      source: snap.source,
      fetchedAt: snap.fetchedAt,
      sampleSize: snap.sampleSize,
    );
  }
}
