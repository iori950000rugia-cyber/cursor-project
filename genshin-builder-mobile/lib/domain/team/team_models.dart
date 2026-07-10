/// 編成（将来のチームシミュレーター用ドメインモデル）。
/// UI 未接続。既存の1キャラ進捗とは独立。
library;

class TeamMemberSlot {
  const TeamMemberSlot({
    required this.characterId,
    this.buildId,
    this.position = 0,
  });

  final String characterId;
  final String? buildId;
  final int position;
}

class Team {
  const Team({
    required this.id,
    required this.name,
    this.members = const [],
    this.notes = '',
  });

  final String id;
  final String name;
  final List<TeamMemberSlot> members;
  final String notes;

  int get size => members.length;

  bool get isFull => members.length >= 4;

  Team copyWith({
    String? id,
    String? name,
    List<TeamMemberSlot>? members,
    String? notes,
  }) =>
      Team(
        id: id ?? this.id,
        name: name ?? this.name,
        members: members ?? this.members,
        notes: notes ?? this.notes,
      );
}
