/// Supplement data for AccountSnapshot from HoYoLAB cache.
/// Pure Dart — no DTOs, no cookies, no auth tokens.
class AccountSnapshotSupplement {
  const AccountSnapshotSupplement({
    this.currentResin,
    this.maxResin,
    this.resinRecoveryAt,
    this.acquiredAt,
    this.status = SnapshotSupplementStatus.unlinked,
    this.characters = const {},
  });

  final int? currentResin;
  final int? maxResin;
  final DateTime? resinRecoveryAt;
  final DateTime? acquiredAt;
  final SnapshotSupplementStatus status;
  final Map<String, CharacterSnapshotSupplement> characters;
}

enum SnapshotSupplementStatus { linked, unlinked, expired }

class CharacterSnapshotSupplement {
  const CharacterSnapshotSupplement({
    this.level,
    this.ascension,
    this.constellation,
    this.talentNormal,
    this.talentSkill,
    this.talentBurst,
    this.weaponId,
    this.weaponName,
    this.weaponLevel,
    this.weaponRefinement,
    this.artifactCompletion,
  });

  final int? level;
  final int? ascension;
  final int? constellation;
  final int? talentNormal;
  final int? talentSkill;
  final int? talentBurst;
  final String? weaponId;
  final String? weaponName;
  final int? weaponLevel;
  final int? weaponRefinement;
  final double? artifactCompletion;
}
