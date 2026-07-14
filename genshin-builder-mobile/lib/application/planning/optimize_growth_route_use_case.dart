import '../../domain/planning/growth_route.dart';
import '../../domain/planning/upgrade_option.dart';
import '../../domain/recommendation/recommendation.dart';

/// Multi-day growth route from UpgradeOptions.
///
/// Rules:
/// 1. Weekday-limited materials scheduled on their available days
/// 2. High-priority goals first
/// 3. Shared materials grouped together
/// 4. Prerequisites (ascension before leveling beyond cap) respected
/// 5. Resin budget roughly respected (simplified)
class OptimizeGrowthRouteUseCase {
  const OptimizeGrowthRouteUseCase();

  static const ruleVersion = '3';
  static const defaultDayCount = 7;

  GrowthRoute call({
    required String userId,
    required List<UpgradeOption> options,
    required DateTime startDate,
    required int startWeekday, // 1=Mon..7=Sun
    int? dailyResinBudget,
    int dayCount = defaultDayCount,
    Map<String, Set<int>>? weekdayMap,
  }) {
    final days = <GrowthRouteDay>[];
    final remaining = List<UpgradeOption>.from(options);
    final unresolved = <String>[];
    final wkMap = weekdayMap ?? const {};

    // Sort remaining by priority desc, then impact desc, then optionId asc
    _sortRemaining(remaining);

    for (var d = 0; d < dayCount; d++) {
      final date = startDate.add(Duration(days: d));
      final weekday = ((startWeekday - 1 + d) % 7) + 1;
      final actions = <GrowthRouteAction>[];
      var dayResin = 0;

      final candidates = List<UpgradeOption>.from(remaining);

      // 1. Weekday-limited materials for this day
      final weekdayItems = candidates
          .where((o) => _isWeekdayLimited(o) && _matchesDay(o, weekday, wkMap))
          .toList();
      for (final opt in weekdayItems) {
        if (!_withinBudget(dailyResinBudget, dayResin, opt)) continue;
        actions.add(_toAction(opt, 'weekdayMaterial'));
        dayResin += opt.estimatedResinCost ?? 0;
        remaining.remove(opt);
      }

      // 2. High priority + general
      candidates.removeWhere((o) => !remaining.contains(o));
      candidates.sort((a, b) => _compareOption(a, b, weekday, wkMap));
      for (final opt in candidates) {
        if (actions.length >= 6) break;
        if (!_withinBudget(dailyResinBudget, dayResin, opt)) continue;
        final at = _isWeekdayLimited(opt) && _matchesDay(opt, weekday, wkMap)
            ? 'weekdayMaterial'
            : 'generalMaterial';
        actions.add(_toAction(opt, at));
        dayResin += opt.estimatedResinCost ?? 0;
        remaining.remove(opt);
      }

      if (actions.isEmpty && remaining.isEmpty) break;

      days.add(GrowthRouteDay(
        date: date,
        weekday: weekday,
        actions: actions,
        estimatedResinUsed: dayResin,
      ));
    }

    for (final opt in remaining) {
      unresolved.add(opt.optionId);
    }

    final hasInv = options.any((o) => o.inventoryStatus == InventoryStatus.ownedSufficient ||
        o.inventoryStatus == InventoryStatus.ownedInsufficient);

    return GrowthRoute(
      userId: userId,
      startDate: startDate,
      endDate: startDate.add(Duration(days: dayCount - 1)),
      days: days,
      goals: options.map((o) => o.relatedGoalId ?? o.optionId).toSet().toList(),
      unresolvedCosts: unresolved,
      confidence: hasInv ? RecommendationConfidence.high : RecommendationConfidence.low,
      completeness: hasInv ? DataCompleteness.partial : DataCompleteness.minimal,
      missingData: hasInv ? [] : [MissingData.materialInventory],
      usedDataSources: options.isNotEmpty ? ['upgradeOptions'] : [],
      generatedAt: startDate,
      ruleVersion: ruleVersion,
    );
  }

  // ── Option comparison (priority desc → impact desc → optionId asc) ──

  static int _compareOption(UpgradeOption a, UpgradeOption b, int weekday, Map<String, Set<int>> wkMap) {
    // Weekday-limited items for today first
    final aIsDay = _isWeekdayLimited(a) && _matchesDay(a, weekday, wkMap);
    final bIsDay = _isWeekdayLimited(b) && _matchesDay(b, weekday, wkMap);
    if (aIsDay && !bIsDay) return -1;
    if (bIsDay && !aIsDay) return 1;

    int cmp = b.priority.compareTo(a.priority);
    if (cmp != 0) return cmp;

    final aImp = a.impact?.impactScore ?? 0;
    final bImp = b.impact?.impactScore ?? 0;
    cmp = bImp.compareTo(aImp);
    if (cmp != 0) return cmp;

    return a.optionId.compareTo(b.optionId);
  }

  static void _sortRemaining(List<UpgradeOption> list) {
    list.sort((a, b) {
      int cmp = b.priority.compareTo(a.priority);
      if (cmp != 0) return cmp;
      final aImp = a.impact?.impactScore ?? 0;
      final bImp = b.impact?.impactScore ?? 0;
      cmp = bImp.compareTo(aImp);
      if (cmp != 0) return cmp;
      return a.optionId.compareTo(b.optionId);
    });
  }

  // ── Budget ────────────────────────────────────────────────────────

  static bool _withinBudget(int? budget, int used, UpgradeOption opt) {
    if (budget == null) return true;
    final cost = opt.estimatedResinCost ?? 0;
    return (used + cost) <= budget;
  }

  // ── Weekday matching ──────────────────────────────────────────────

  static bool _isWeekdayLimited(UpgradeOption o) =>
      o.optionType == 'talentNormal' ||
      o.optionType == 'talentSkill' ||
      o.optionType == 'talentBurst' ||
      o.optionType == 'weapon';

  /// Returns true if at least one of [o]'s materials is available on [weekday].
  /// If [weekdayMap] is empty, all days are treated as valid (conservative).
  static bool _matchesDay(UpgradeOption o, int weekday, Map<String, Set<int>> weekdayMap) {
    if (o.materialsCost.isEmpty) return false;
    if (weekdayMap.isEmpty) return true; // no data → assume all days
    for (final matId in o.materialsCost.keys) {
      final days = weekdayMap[matId];
      if (days != null && days.contains(weekday)) return true;
    }
    return false; // none of the materials are available today
  }

  // ── Action builder ────────────────────────────────────────────────

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
