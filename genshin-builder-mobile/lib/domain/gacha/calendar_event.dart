/// イベントカレンダー1件（ennead / HoYoverse act calendar）
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.typeName,
    required this.start,
    required this.end,
    this.imageUrl,
    this.rewards = const [],
    this.specialReward,
  });

  final String id;
  final String name;
  final String description;
  final String typeName;
  final DateTime start;
  final DateTime end;
  final String? imageUrl;
  final List<CalendarEventReward> rewards;
  final CalendarEventReward? specialReward;

  bool get hasSchedule =>
      start.millisecondsSinceEpoch > 0 && end.millisecondsSinceEpoch > 0;

  bool isActiveAt(DateTime now) {
    if (!hasSchedule) return false;
    return !now.isBefore(start) && !now.isAfter(end);
  }

  bool isUpcomingAt(DateTime now) {
    if (!hasSchedule) return false;
    return now.isBefore(start);
  }
}

class CalendarEventReward {
  const CalendarEventReward({
    required this.id,
    required this.name,
    this.icon,
    this.rarity,
    this.amount,
  });

  final String id;
  final String name;
  final String? icon;
  final String? rarity;
  final int? amount;
}

/// 開催中を先に、終了が近い順。予告は開始が近い順。
List<CalendarEvent> sortCalendarEventsForHome(
  Iterable<CalendarEvent> events, {
  DateTime? now,
}) {
  final t = now ?? DateTime.now().toUtc();
  final active = <CalendarEvent>[];
  final upcoming = <CalendarEvent>[];
  for (final e in events) {
    if (!e.hasSchedule) continue;
    if (e.isActiveAt(t)) {
      active.add(e);
    } else if (e.isUpcomingAt(t)) {
      upcoming.add(e);
    }
  }
  active.sort((a, b) => a.end.compareTo(b.end));
  upcoming.sort((a, b) => a.start.compareTo(b.start));
  return [...active, ...upcoming];
}
