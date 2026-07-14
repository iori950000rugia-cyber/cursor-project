import '../../domain/account/account_snapshot.dart';
import '../../domain/planning/daily_plan.dart';
import '../../domain/planning/growth_goal.dart';
import '../../domain/recommendation/recommendation.dart';

/// Generates a daily plan from an [AccountSnapshot].
///
/// Priority rules:
/// 1. Weekday-limited materials
/// 2. Weekly boss materials
/// 3. High-priority GrowthGoals
/// 4. Near-completion goals
/// 5. Items achievable with current resin
/// 6. General materials
class GenerateDailyPlanUseCase {
  const GenerateDailyPlanUseCase();

  /// Generate a daily plan for a specific date and weekday.
  DailyPlan call({
    required String userId,
    required AccountSnapshot snapshot,
    required DateTime date,
    required int weekday, // 1=Mon..7=Sun
    DateTime? generatedAt,
  }) {
    final items = <DailyPlanItem>[];
    final goals = snapshot.activeGoals;
    final inventory = snapshot.materialInventory;
    final hasInventory = inventory.isNotEmpty;
    final resin = snapshot.currentResin;
    final missingData = <MissingData>[];

    if (!hasInventory) missingData.add(MissingData.materialInventory);
    if (resin == null) missingData.add(MissingData.materialInventory);

    // 1. Weekday-limited materials from active goals
    for (final goal in goals.where((g) => g.status == GrowthGoalStatus.active)) {
      if (goal.hasAnyTarget) {
        items.add(DailyPlanItem(
          id: 'wd_${goal.id}',
          type: DailyPlanItemType.weekdayMaterial,
          title: _goalSummary(goal),
          characterIds: [goal.characterId],
          priority: 100,
          relatedGoalId: goal.id,
          reasons: ['Today\'s weekday-limited materials for growth goal'],
          confidence: RecommendationConfidence.medium,
          missingData: missingData,
        ));
      }
    }

    // 2. High-priority goals
    for (final goal in goals.where((g) => g.priority > 0).take(2)) {
      items.add(DailyPlanItem(
        id: 'pri_${goal.id}',
        type: DailyPlanItemType.growthGoal,
        title: 'High priority: ${_goalSummary(goal)}',
        characterIds: [goal.characterId],
        priority: 80 + goal.priority,
        relatedGoalId: goal.id,
        reasons: ['High-priority growth goal'],
        estimatedResinCost: resin,
        confidence: hasInventory ? RecommendationConfidence.high : RecommendationConfidence.low,
        missingData: missingData,
      ));
    }

    // 3. Near-completion goals
    for (final goal in goals.where((g) => g.priority <= 0).take(2)) {
      items.add(DailyPlanItem(
        id: 'gen_${goal.id}',
        type: DailyPlanItemType.generalMaterial,
        title: _goalSummary(goal),
        characterIds: [goal.characterId],
        priority: 50,
        relatedGoalId: goal.id,
        reasons: ['General growth material farming'],
        confidence: hasInventory ? RecommendationConfidence.high : RecommendationConfidence.low,
        missingData: missingData,
      ));
    }

    // 4. General materials from goals
    items.sort((a, b) => b.priority.compareTo(a.priority));

    return DailyPlan(
      userId: userId,
      date: date,
      items: items,
      currentResin: resin,
      maxResin: snapshot.maxResin,
      confidence: hasInventory ? RecommendationConfidence.high : RecommendationConfidence.low,
      completeness: snapshot.completeness,
      missingData: missingData,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }

  String _goalSummary(GrowthGoal goal) {
    final parts = <String>[];
    if (goal.targetLevel != null) parts.add('Lv.${goal.targetLevel}');
    if (goal.targetTalentNormal != null || goal.targetTalentSkill != null || goal.targetTalentBurst != null) {
      parts.add('Talents');
    }
    if (goal.targetWeaponId != null) parts.add('Weapon');
    return parts.isEmpty ? goal.characterId : parts.join(' + ');
  }
}
