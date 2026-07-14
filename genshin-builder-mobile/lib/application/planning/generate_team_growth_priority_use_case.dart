import '../../domain/planning/upgrade_option.dart';
import '../../domain/planning/team_growth_priority.dart';
import '../../domain/team/team_models.dart';
import '../../domain/account/account_snapshot.dart';
import '../../domain/recommendation/recommendation.dart';

/// Generates team growth priority for a saved team.
///
/// Evaluates each member based on:
/// - Current level / talent / weapon state
/// - Existence of UpgradeOptions
/// - Impact scores
class GenerateTeamGrowthPriorityUseCase {
  const GenerateTeamGrowthPriorityUseCase();

  static const ruleVersion = '1';

  TeamGrowthPriorityReport call({
    required Team team,
    required AccountSnapshot snapshot,
    required Map<String, List<UpgradeOption>> upgradeOptionsByCharacter,
    DateTime? generatedAt,
  }) {
    final priorities = <TeamMemberGrowthPriority>[];

    for (final member in team.members) {
      final char = snapshot.characters
          .where((c) => c.characterId == member.characterId)
          .firstOrNull;

      if (char == null || !char.isOwned) {
        priorities.add(TeamMemberGrowthPriority(
          characterId: member.characterId,
          priority: -1,
          reasons: ['Character not owned or not found'],
          confidence: RecommendationConfidence.unknown,
        ));
        continue;
      }

      final options = upgradeOptionsByCharacter[member.characterId] ?? [];
      final reasons = <String>[];
      double totalScore = 0;

      // Evaluate based on options
      if (options.isNotEmpty) {
        for (final opt in options) {
          totalScore += opt.impact?.impactScore ?? 0;
        }
        reasons.add('${options.length} upgrade options available');
      }

      // General evaluation
      if (char.level < 80) {
        reasons.add('Character level (${char.level}) below 80');
        totalScore += 0.1;
      }
      if (char.weaponLevel < 80) {
        reasons.add('Weapon level (${char.weaponLevel}) below 80');
        totalScore += 0.08;
      }
      final maxTalent = [char.talentNormal, char.talentSkill, char.talentBurst]
          .reduce((a, b) => a > b ? a : b);
      if (maxTalent < 6) {
        reasons.add('Highest talent (Lv.$maxTalent) below 6');
        totalScore += 0.05;
      }

      final priority = totalScore > 0.3 ? 3
          : totalScore > 0.15 ? 2
          : totalScore > 0 ? 1
          : 0;

      priorities.add(TeamMemberGrowthPriority(
        characterId: member.characterId,
        priority: priority,
        score: totalScore,
        upgradeOptions: options.take(3).toList(),
        reasons: reasons,
        confidence: options.isNotEmpty
            ? RecommendationConfidence.medium
            : RecommendationConfidence.low,
      ));
    }

    // Sort by priority desc, then score desc
    priorities.sort((a, b) {
      final cmp = b.priority.compareTo(a.priority);
      if (cmp != 0) return cmp;
      return b.score.compareTo(a.score);
    });

    // Shared material opportunities
    final allMaterials = <String, Set<String>>{};
    for (final p in priorities) {
      for (final opt in p.upgradeOptions) {
        for (final matId in opt.materialsCost.keys) {
          allMaterials.putIfAbsent(matId, () => {});
          allMaterials[matId]!.add(p.characterId);
        }
      }
    }
    final shared = allMaterials.entries
        .where((e) => e.value.length > 1)
        .map((e) => 'Material ${e.key} shared by ${e.value.join(", ")}')
        .toList();

    return TeamGrowthPriorityReport(
      teamId: team.id,
      teamName: team.name,
      memberPriorities: priorities,
      sharedMaterialOpportunities: shared,
      confidence: priorities.any((p) => p.score > 0)
          ? RecommendationConfidence.medium
          : RecommendationConfidence.low,
      completeness: DataCompleteness.partial,
      missingData: snapshot.missingData,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }
}
