import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/bookmark_dao.dart';
import 'daos/character_dao.dart';
import 'daos/progress_dao.dart';
import 'tables/master_tables.dart';
import 'tables/user_tables.dart';

part 'app_database.g.dart';

/// Drift SQLite（`build_runner` codegen 後に [../app_database.dart] から切り替え）
@DriftDatabase(
  tables: [
    Characters,
    Weapons,
    Materials,
    CharacterUpgrades,
    WeaponUpgrades,
    LevelExpSegments,
    UserProgressTable,
    MaterialBookmarks,
    SyncLogs,
    AppSettings,
  ],
  daos: [CharacterDao, BookmarkDao, ProgressDao],
)
class DriftAppDatabase extends _$DriftAppDatabase {
  DriftAppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  static Future<DriftAppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'genshin_builder.db'));
    return DriftAppDatabase(NativeDatabase.createInBackground(file));
  }
}
