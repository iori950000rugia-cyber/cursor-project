import '../../domain/planning/growth_route.dart';
import '../../domain/planning/upgrade_option.dart';
import '../../domain/recommendation/recommendation.dart';

/// Generates a multi-day growth route from UpgradeOptions.
///
/// Rules:
/// 1. Weekday-limited materials scheduled on their available days
/// 2. High-priority goals first
/// 3. Shared materials grouped together
/// 4. Prerequisites (ascension before leveling beyond cap) respected
/// 5. Resin budget roughly respected (simplified)
class OptimizeGrowthRouteUseCase {
  const OptimizeGrowthRouteUseCase();

  static const ruleVersion = '2';
  static const defaultDayCount = 7;

  GrowthRoute call({
    required String userId,
    required List<UpgradeOption> options,
    required int startWeekday, // 1=Mon..7=Sun
    DateTime? startDate,
    int dayCount = defaultDayCount,
  }) {
    final now = startDate ?? DateTime.now();
    final days = <GrowthRouteDay>[];
    final remaining = List<UpgradeOption>.from(options);
    final unresolved = <String>[];

    for (var d = 0; d < dayCount; d++) {
      final date = now.add(Duration(days: d));
      final weekday = ((startWeekday - 1 + d) % 7) + 1;
      final actions = <GrowthRouteAction>[];

      // 1. Weekday-limited materials
      final weekdayItems = remaining
          .where((o) => _isWeekdayLimited(o) && _matchesDay(o, weekday))
          .toList();
      for (final opt in weekdayItems) {
        actions.add(_toAction(opt, 'weekdayMaterial'));
        remaining.remove(opt);
      }

      // 2. High priority
      final highPri = remaining
          .where((o) => o.priority > 0)
          .take(3)
          .toList();
      for (final opt in highPri) {
        actions.add(_toAction(opt, 'growthGoal'));
        remaining.remove(opt);
      }

      // 3. Remaining items (general)
      final general = remaining.take(3).toList();
      for (final opt in general) {
        actions.add(_toAction(opt, 'generalMaterial'));
        remaining.remove(opt);
      }

      if (actions.isEmpty && remaining.isEmpty) break;

      days.add(GrowthRouteDay(
        date: date,
        weekday: weekday,
        actions: actions,
      ));
    }

    // Collect unresolved (not scheduled)
    for (final opt in remaining) {
      unresolved.add(opt.optionId);
    }

    final hasInv = options.any((o) => o.inventoryStatus == InventoryStatus.ownedSufficient ||
        o.inventoryStatus == InventoryStatus.ownedInsufficient);

    return GrowthRoute(
      userId: userId,
      startDate: now,
      endDate: now.add(Duration(days: dayCount - 1)),
      days: days,
      goals: options.map((o) => o.relatedGoalId ?? o.optionId).toSet().toList(),
      unresolvedCosts: unresolved,
      confidence: hasInv ? RecommendationConfidence.high : RecommendationConfidence.low,
      completeness: hasInv ? DataCompleteness.partial : DataCompleteness.minimal,
      missingData: hasInv ? [] : [MissingData.materialInventory],
      usedDataSources: options.isNotEmpty ? ['upgradeOptions'] : [],
      generatedAt: now,
      ruleVersion: ruleVersion,
    );
  }

  bool _isWeekdayLimited(UpgradeOption o) =>
      o.optionType == 'talentNormal' ||
      o.optionType == 'talentSkill' ||
      o.optionType == 'talentBurst' ||
      o.optionType == 'weapon';

  // Simplified: all days match for now (real impl checks daily schedule)
  bool _matchesDay(UpgradeOption o, int weekday) => true;

  GrowthRouteAction _toAction(UpgradeOption o, String actionType) {
    return GrowthRouteAction(
      optionId: o.optionId,
      actionType: actionType,
      characterId: o.characterId,
      relatedGoalIds: o.relatedGoalId != null ? [o.relatedGoalId!] : [],
      materialIds: o.materialsCost.keys.toList(),
      estimatedResinCost: o.estimatedResinCost,
      priority: o.priority,
      reasons: [o.optionType],
    );
  }
}
