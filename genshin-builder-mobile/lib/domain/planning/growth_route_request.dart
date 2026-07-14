/// Stable request for [OptimizeGrowthRouteUseCase].
/// Used as a Provider family key — fully immutable.
class GrowthRouteRequest {
  GrowthRouteRequest({
    required List<String> goalIds,
    required this.startDate,
    required this.startWeekday,
    this.dailyResinBudget,
    this.weekdayMap,
  }) : goalIds = List.unmodifiable(
          List<String>.from(goalIds.toSet())..sort(), // dedupe + sort
        );

  /// Sorted, deduplicated list of goal IDs (immutable).
  final List<String> goalIds;

  final DateTime startDate;
  final int startWeekday; // 1=Mon..7=Sun
  final int? dailyResinBudget;

  /// materialId → available weekdays (1=Mon..7=Sun).
  final Map<String, Set<int>>? weekdayMap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrowthRouteRequest &&
          other.startDate == startDate &&
          other.startWeekday == startWeekday &&
          other.dailyResinBudget == dailyResinBudget &&
          _listEquals(other.goalIds, goalIds);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(goalIds),
        startDate,
        startWeekday,
        dailyResinBudget,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
