import '../../domain/account/account_snapshot.dart';
import '../../domain/account/account_health_report.dart';
import '../../domain/recommendation/recommendation.dart';

/// Generates an [AccountHealthReport] from an [AccountSnapshot].
///
/// No character roles, synergies, or external stats are used.
/// This is a pure data-driven health assessment of the user's account.
///
/// Note: Data Completeness is NOT included in the total score.
/// It is stored separately as [AccountHealthReport.dataCoverage].
class GenerateAccountHealthReportUseCase {
  const GenerateAccountHealthReportUseCase();

  static const ruleVersion = '2';

  AccountHealthReport call({
    required AccountSnapshot snapshot,
    DateTime? generatedAt,
  }) {
    final chars = snapshot.characters;
    final owned = chars.where((c) => c.isOwned).toList();
    final totalOwned = owned.length;
    final categories = <AccountHealthCategory>[];
    final hasInventory = snapshot.materialInventory.isNotEmpty;

    // 1. Character level investment
    double levelScore = 0;
    bool levelEval = false;
    int leveled = 0;
    if (totalOwned > 0) {
      leveled = owned.where((c) => c.level >= 80).length;
      levelScore = (leveled / totalOwned * 100).clamp(0.0, 100.0);
      levelEval = true;
    }
    categories.add(AccountHealthCategory(
      name: 'Character Levels',
      score: levelScore,
      weight: 1.5,
      evaluated: levelEval,
      evidenceCount: totalOwned,
      reasons: levelEval ? ['$leveled of $totalOwned owned characters are Lv.80+'] : ['No owned characters'],
      improvementHints: levelScore < 50 && levelEval ? ['Focus on leveling key characters to 80+'] : [],
      missingData: totalOwned == 0 ? [MissingData.materialInventory] : [],
    ));

    // 2. Talent level investment
    double talentScore = 0;
    bool talentEval = false;
    int talentChars = 0;
    if (totalOwned > 0) {
      talentChars = owned.where((c) {
        var high = 0;
        for (final t in [c.talentNormal, c.talentSkill, c.talentBurst]) {
          if (t >= 6) high++;
        }
        return high >= 2;
      }).length;
      talentScore = (talentChars / totalOwned * 100).clamp(0.0, 100.0);
      talentEval = true;
    }
    categories.add(AccountHealthCategory(
      name: 'Talent Levels',
      score: talentScore,
      weight: 1.2,
      evaluated: talentEval,
      evidenceCount: talentChars,
      reasons: talentEval ? ['$talentChars characters have 2+ talents at Lv.6+'] : ['No owned characters'],
      improvementHints: talentScore < 40 && talentEval ? ['Raise key talents on main characters'] : [],
    ));

    // 3. Weapon level investment
    double weaponScore = 0;
    bool weaponEval = false;
    int weaponChars = 0;
    if (totalOwned > 0) {
      weaponChars = owned.where((c) => c.weaponLevel >= 80).length;
      weaponScore = (weaponChars / totalOwned * 100).clamp(0.0, 100.0);
      weaponEval = true;
    }
    categories.add(AccountHealthCategory(
      name: 'Weapon Levels',
      score: weaponScore,
      weight: 1.0,
      evaluated: weaponEval,
      evidenceCount: weaponChars,
      reasons: weaponEval ? ['$weaponChars characters have weapons at Lv.80+'] : ['No owned characters'],
    ));

    // 4. Artifact completion — only evaluate if artifact data is available
    final artifactAvailable = owned.any((c) => c.artifactCompletionAvailable);
    double artifactScore = 0;
    int artifactChars = 0;
    if (artifactAvailable && totalOwned > 0) {
      artifactChars = owned.where((c) => c.artifactCompletionAvailable && c.artifactCompletion >= 0.8).length;
      artifactScore = (artifactChars / totalOwned * 100).clamp(0.0, 100.0);
    }
    categories.add(AccountHealthCategory(
      name: 'Artifact Completion',
      score: artifactScore,
      weight: 0.8,
      evaluated: artifactAvailable,
      evidenceCount: artifactChars,
      reasons: artifactAvailable ? ['$artifactChars characters have artifacts completed'] : ['Artifact data not available'],
      missingData: !artifactAvailable ? [MissingData.materialInventory] : [],
      improvementHints: !artifactAvailable ? ['Set artifact completion in character details to track progress'] : [],
    ));

    // 5. Growth goal completion — evaluated only when goals exist
    final totalGoals = snapshot.activeGoals.length;
    final goalEval = totalGoals > 0;
    final goalScore = goalEval ? 50.0 : 0.0;
    categories.add(AccountHealthCategory(
      name: 'Growth Goals',
      score: goalScore,
      weight: 0.5,
      evaluated: goalEval,
      evidenceCount: totalGoals,
      reasons: goalEval ? ['$totalGoals active growth goals to track'] : ['No growth goals set — cannot evaluate'],
      improvementHints: !goalEval ? ['Set growth goals to prioritize farming'] : [],
    ));

    // Calculate weighted total from evaluated categories only
    double totalWeight = 0;
    double weightedSum = 0;
    for (final cat in categories) {
      if (cat.evaluated) {
        weightedSum += cat.normalizedScore * cat.weight;
        totalWeight += cat.weight;
      }
    }
    final totalScore = totalWeight > 0 ? (weightedSum / totalWeight).clamp(0.0, 100.0) : -1.0;

    // Strengths & improvements from evaluated categories only
    final strengths = categories.where((c) => c.evaluated && c.normalizedScore >= 70).map((c) => c.name).toList();
    final improvements = categories.where((c) => c.evaluated && c.normalizedScore < 40).map((c) => c.name).toList();

    // Data coverage (separate from health score)
    final dataCoverage = snapshot.completeness == DataCompleteness.complete ? 'High'
        : snapshot.completeness == DataCompleteness.partial ? 'Medium'
        : snapshot.completeness == DataCompleteness.minimal ? 'Low'
        : 'Unavailable';

    return AccountHealthReport(
      totalScore: totalScore,
      rating: totalScore >= 0 ? AccountHealthReport.scoreToRating(totalScore) : HealthRating.unknown,
      categories: categories,
      strengths: strengths,
      improvementCandidates: improvements,
      dataCoverage: dataCoverage,
      confidence: hasInventory ? RecommendationConfidence.medium : RecommendationConfidence.low,
      completeness: snapshot.completeness,
      missingData: snapshot.missingData,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }
}
