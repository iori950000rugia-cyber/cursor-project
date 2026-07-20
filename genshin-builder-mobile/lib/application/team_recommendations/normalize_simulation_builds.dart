import '../../data/hoyolab/hoyolab_relic_sync.dart';
import '../../data/hoyolab/models/game_record.dart';
import '../../domain/hoyolab_stat_normalize.dart';
import '../../domain/models/master_models.dart';
import '../../domain/team_recommendation/team_recommendation.dart';

List<SimulationBuildSnapshot> normalizeSimulationBuilds({
  required List<MasterCharacter> characters,
  required Map<String, HoyolabCharacterBuild> hoyolabBuilds,
  required Map<String, UserProgress> localProgress,
}) {
  return characters.map((character) {
    final build = hoyolabBuilds[character.id];
    final progress = localProgress[character.id];
    if (build == null && progress == null) {
      return SimulationBuildSnapshot(
        characterId: character.id,
        element: character.element.toLowerCase(),
        rarity: character.rarity,
        isOwned: false,
        level: 1,
        ascension: 0,
        constellation: 0,
        inputQuality: SimulationInputQuality.unsupported,
        defaultedFields: const [
          'level',
          'ascension',
          'constellation',
          'talents',
          'weapon',
          'artifacts',
        ],
      );
    }

    final defaulted = <String>[];
    final talents = _talents(build?.talents ?? const []);
    if (talents == null) defaulted.add('talents');
    final weapon = build?.weapon;
    if (weapon == null || weapon.id.isEmpty) defaulted.add('weapon');
    final artifactStats = _artifactStats(build?.relics ?? const []);
    if (build == null || build.relics.isEmpty) defaulted.add('artifacts');
    // Game Recordの聖遺物にはセット名だけがあり、安定したsetIdがないため推測しない。
    if (build?.relics.isNotEmpty == true) defaulted.add('artifactSets');

    return SimulationBuildSnapshot(
      characterId: character.id,
      element: character.element.toLowerCase(),
      rarity: character.rarity,
      isOwned: build?.isOwned ?? true,
      level: build?.level ?? progress?.level ?? 1,
      ascension: build?.promoteLevel ?? progress?.ascension ?? 0,
      constellation: build?.constellation ?? progress?.constellation ?? 0,
      talents:
          talents ??
          (progress == null
              ? null
              : {
                'normal': progress.talentNormal,
                'skill': progress.talentSkill,
                'burst': progress.talentBurst,
              }),
      weapon:
          weapon != null && weapon.id.isNotEmpty
              ? {
                'weaponId': weapon.id,
                'level': weapon.level,
                'ascension': weapon.promoteLevel,
                'refinement': weapon.refinement,
              }
              : null,
      artifacts:
          build?.relics.isNotEmpty == true
              ? {'sets': const <Object>[], 'stats': artifactStats}
              : null,
      inputQuality:
          defaulted.isEmpty
              ? SimulationInputQuality.exact
              : SimulationInputQuality.partial,
      defaultedFields: defaulted,
    );
  }).toList();
}

Map<String, int>? _talents(List<GameRecordTalent> talents) {
  int? normal;
  int? skill;
  int? burst;
  for (final talent in talents) {
    final name = talent.name.toLowerCase();
    if (name.contains('通常') || name.contains('normal')) normal = talent.level;
    if (name.contains('スキル') || name.contains('skill')) skill = talent.level;
    if (name.contains('爆発') || name.contains('burst')) burst = talent.level;
  }
  return normal != null && skill != null && burst != null
      ? {'normal': normal, 'skill': skill, 'burst': burst}
      : null;
}

Map<String, double> _artifactStats(List<GameRecordRelic> relics) {
  final result = <String, double>{};
  for (final relic in relics) {
    final props = [
      if (relic.mainStat != null) relic.mainStat!,
      ...relic.subStats,
    ];
    for (final prop in props) {
      final normalized = normalizeSubStatLabel(prop.label) ?? prop.label;
      final key = _statKey(normalized);
      if (key == null) continue;
      result[key] = (result[key] ?? 0) + parseStatValue(prop.value);
    }
  }
  return result;
}

String? _statKey(String label) => switch (label.replaceAll('％', '%')) {
  'HP' => 'hpFlat',
  'HP%' => 'hpPercent',
  '攻撃力' => 'atkFlat',
  '攻撃力%' => 'atkPercent',
  '防御力' => 'defFlat',
  '防御力%' => 'defPercent',
  '会心率' => 'critRate',
  '会心ダメージ' => 'critDamage',
  '元素チャージ効率' => 'energyRecharge',
  '元素熟知' => 'elementalMastery',
  '炎元素ダメージ' => 'pyroDamageBonus',
  '水元素ダメージ' => 'hydroDamageBonus',
  '雷元素ダメージ' => 'electroDamageBonus',
  '氷元素ダメージ' => 'cryoDamageBonus',
  '風元素ダメージ' => 'anemoDamageBonus',
  '岩元素ダメージ' => 'geoDamageBonus',
  '草元素ダメージ' => 'dendroDamageBonus',
  '物理ダメージ' => 'physicalDamageBonus',
  _ => null,
};
