/// Stable request for [OptimizeGrowthRouteUseCase].
/// Used as a Provider family key — must have value equality.
class GrowthRouteRequest {
  const GrowthRouteRequest({
    required this.goalIds,
    required this.startDate,
    required this.startWeekday,
    this.dailyResinBudget,
  });

  final List<String> goalIds;
  final DateTime startDate;
  final int startWeekday;
  final int? dailyResinBudget;

  @override
  bool operator ==(Object other) =>
      other is GrowthRouteRequest &&
      other.startWeekday == startWeekday &&
      other.dailyResinBudget == dailyResinBudget &&
      other.startDate == startDate &&
      _listEquals(other.goalIds, goalIds);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(goalIds..sort()),
        startDate,
        startWeekday,
        dailyResinBudget,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = List<String>.from(a)..sort();
    final sb = List<String>.from(b)..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }
}
