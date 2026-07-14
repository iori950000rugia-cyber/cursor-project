import 'package:drift/drift.dart';

/// Growth goals table.
class GrowthGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get characterId => text().nullable()();
  IntColumn get targetLevel => integer().nullable()();
  IntColumn get targetAscension => integer().nullable()();
  IntColumn get targetTalentNormal => integer().nullable()();
  IntColumn get targetTalentSkill => integer().nullable()();
  IntColumn get targetTalentBurst => integer().nullable()();
  TextColumn get targetWeaponId => text().nullable()();
  IntColumn get targetWeaponLevel => integer().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get memo => text().nullable()();
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User material inventory table.
class UserMaterialInventory extends Table {
  TextColumn get userId => text()();
  TextColumn get materialId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  BoolColumn get isEstimated => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {userId, materialId};
}

/// Saved team persistence (userId not in domain Team model).
class SavedTeams extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get membersJson => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Growth events log.
class GrowthEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get userId => text()();
  TextColumn get characterId => text().nullable()();
  TextColumn get eventType => text()();
  TextColumn get beforeValue => text().nullable()();
  TextColumn get afterValue => text().nullable()();
  TextColumn get source => text().nullable()();
  IntColumn get observedAt => integer()();
  IntColumn get createdAt => integer().nullable()();
  TextColumn get dedupKey => text()();

  @override
  Set<Column> get primaryKey => {eventId};
}
