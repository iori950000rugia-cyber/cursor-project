import '../models/artifact_state.dart';
import '../models/master_models.dart';

/// ダメージ計算の入力コンテキスト（将来のダメ計用）。
/// 現状はスケルトン。stats エンジン拡張時にフィールドを増やす。
class DamageContext {
  const DamageContext({
    required this.character,
    required this.level,
    this.talentNormal = 1,
    this.talentSkill = 1,
    this.talentBurst = 1,
    this.constellation = 0,
    this.weaponId,
    this.weaponLevel = 1,
    this.artifacts,
    this.enemyLevel = 100,
    this.enemyResistance = 0.1,
    this.activeBuffIds = const [],
  });

  final MasterCharacter character;
  final int level;
  final int talentNormal;
  final int talentSkill;
  final int talentBurst;
  final int constellation;
  final String? weaponId;
  final int weaponLevel;
  final ArtifactState? artifacts;
  final int enemyLevel;
  final double enemyResistance;
  final List<String> activeBuffIds;
}

/// ダメージ計算結果のプレースホルダ。
class DamageEstimate {
  const DamageEstimate({
    this.average = 0,
    this.crit = 0,
    this.nonCrit = 0,
    this.notes = const [],
  });

  final double average;
  final double crit;
  final double nonCrit;
  final List<String> notes;
}

/// 将来のダメ計エントリポイント。未実装時はゼロ結果を返す。
DamageEstimate estimateDamage(DamageContext context) {
  return const DamageEstimate(
    notes: ['Damage calculator is not implemented yet'],
  );
}
