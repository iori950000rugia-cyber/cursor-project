/// User account snapshot for recommendation and diagnosis.
///
/// Built by [BuildAccountSnapshotUseCase] from multiple repositories.
/// Contains only normalized domain data — no external API DTOs or DB rows.
library;

import '../recommendation/recommendation.dart';
import '../planning/growth_goal.dart';

class CharacterSnapshot {
  const CharacterSnapshot({
    required this.characterId,
    required this.name,
    required this.element,
    required this.weaponType,
    required this.rarity,
    required this.region,
    required this.isOwned,
    this.level = 1,
    this.ascension = 0,
    this.constellation = 0,
    this.talentNormal = 1,
    this.talentSkill = 1,
    this.talentBurst = 1,
    this.equippedWeaponId,
    this.equippedWeaponName,
    this.weaponLevel = 1,
    this.weaponRefinement = 1,
    this.artifactCompletion = 0.0,
    this.artifactCompletionAvailable = false,
    this.memo,
  });

  final String characterId;
  final String name;
  final String element;
  final String weaponType;
  final int rarity;
  final String region;
  final bool isOwned;
  final int level;
  final int ascension;
  final int constellation;
  final int talentNormal;
  final int talentSkill;
  final int talentBurst;
  final String? equippedWeaponId;
  final String? equippedWeaponName;
  final int weaponLevel;
  final int weaponRefinement;
  final double artifactCompletion;
  final bool artifactCompletionAvailable;
  final String? memo;
}

class AccountSnapshot {
  const AccountSnapshot({
    required this.userId,
    this.characters = const [],
    this.materialInventory = const {},
    this.savedTeams = const [],
    this.activeGoals = const [],
    this.currentResin,
    this.maxResin,
    this.weekday,
    this.acquiredAt,
    this.sources = const [],
    this.confidence = RecommendationConfidence.unknown,
    this.completeness = DataCompleteness.unavailable,
    this.missingData = const [],
  });

  final String userId;
  final List<CharacterSnapshot> characters;
  final Map<String, int> materialInventory;
  final List<dynamic> savedTeams; // Team from domain/team
  final List<GrowthGoal> activeGoals;
  final int? currentResin;
  final int? maxResin;
  final int? weekday; // 1=Mon..7=Sun
  final DateTime? acquiredAt;
  final List<String> sources;
  final RecommendationConfidence confidence;
  final DataCompleteness completeness;
  final List<MissingData> missingData;

  int get ownedCount => characters.where((c) => c.isOwned).length;
  int get totalCharacters => characters.length;
}
