/// Upgrade evaluation models for growth planning.
library;

class UpgradeImpact {
  const UpgradeImpact({
    required this.relativeEffect,
    required this.area,
    this.confidence = 'low',
    this.notes,
  });

  /// Relative effect estimate (e.g. 0.064 = +6.4%).
  final double relativeEffect;

  /// Area of impact (e.g. 'singleTarget', 'survivability', 'support').
  final String area;

  /// Confidence level for this estimate.
  final String confidence;

  final String? notes;
}

class UpgradeOption {
  const UpgradeOption({
    required this.characterId,
    required this.optionType,
    this.fromLevel,
    this.toLevel,
    this.materialsCost = const {},
    this.moraCost = 0,
    this.estimatedResinCost,
    this.impact,
    this.priority = 0,
  });

  final String characterId;

  /// level, ascension, talentNormal, talentSkill, talentBurst, weapon.
  final String optionType;

  final int? fromLevel;
  final int? toLevel;
  final Map<String, int> materialsCost;
  final int moraCost;
  final int? estimatedResinCost;
  final UpgradeImpact? impact;
  final int priority;
}
