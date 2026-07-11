import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import '../../secure/secure_storage_service.dart';
import '../database_path.dart';
import 'daos/bookmark_dao.dart';
import 'daos/character_dao.dart';
import 'daos/progress_dao.dart';
import 'tables/master_tables.dart';
import 'tables/user_tables.dart';

part 'app_database.g.dart';

/// `--dart-define=ENABLE_SQLCIPHER=true` のときのみ SQLCipher + PRAGMA key を使う。
/// 既定は false（既存の平文 DB を壊さない）。
const bool kEnableSqlCipher = bool.fromEnvironment(
  'ENABLE_SQLCIPHER',
  defaultValue: false,
);

/// Drift SQLite（レガシー sqflite と同一パスを [database_path] で解決）
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

  static const _dbName = 'genshin_builder.db';

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes(m);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(appSettings);
          }
          if (from < 4) {
            await _addArtifactsColumnSafely(m.database);
          }
          if (from < 5) {
            await _addArtifactScoreTypeColumnSafely(m.database);
          }
          if (from < 6) {
            await _addUpgradeContentHashColumnsSafely(m.database);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await _addArtifactsColumnSafely(this);
          await _addArtifactScoreTypeColumnSafely(this);
          await _addUpgradeContentHashColumnsSafely(this);
        },
      );

  /// `artifacts` 列が無い DB を修復（重複追加は無視）
  static Future<void> _addArtifactsColumnSafely(GeneratedDatabase db) async {
    try {
      await db.customStatement(
        "ALTER TABLE user_progress ADD COLUMN artifacts TEXT NOT NULL DEFAULT '{}'",
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('duplicate column')) {
        rethrow;
      }
    }
  }

  static Future<void> _addArtifactScoreTypeColumnSafely(
    GeneratedDatabase db,
  ) async {
    try {
      await db.customStatement(
        "ALTER TABLE user_progress ADD COLUMN artifact_score_type TEXT NOT NULL DEFAULT ''",
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('duplicate column')) {
        rethrow;
      }
    }
  }

  static Future<void> _addUpgradeContentHashColumnsSafely(
    GeneratedDatabase db,
  ) async {
    for (final statement in [
      "ALTER TABLE character_upgrades ADD COLUMN content_hash TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE weapon_upgrades ADD COLUMN content_hash TEXT NOT NULL DEFAULT ''",
    ]) {
      try {
        await db.customStatement(statement);
      } catch (e) {
        final message = e.toString().toLowerCase();
        if (!message.contains('duplicate column')) {
          rethrow;
        }
      }
    }
  }

  static Future<void> _createIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bookmarks_material '
      'ON material_bookmarks (material_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_progress_user '
      'ON user_progress (user_id)',
    );
  }

  /// ネイティブ SQLCipher をロード（平文利用時も必須。鍵は別途 PRAGMA）。
  static Future<void> _setupSqlCipherIsolate() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      sqlite3_open.open.overrideFor(
        sqlite3_open.OperatingSystem.android,
        openCipherOnAndroid,
      );
    }
  }

  static Future<DriftAppDatabase> open({
    SecureStorageService? secureStorage,
  }) async {
    // sqlcipher_flutter_libs のみ依存のため、常にネイティブを差し替える。
    await _setupSqlCipherIsolate();

    final file = await resolveDatabaseFile(_dbName);

    String? encryptionKey;
    if (kEnableSqlCipher) {
      final storage = secureStorage ?? SecureStorageService();
      encryptionKey = await storage.getOrCreateDbKey();
    }

    final db = DriftAppDatabase(
      NativeDatabase.createInBackground(
        file,
        isolateSetup: _setupSqlCipherIsolate,
        setup: encryptionKey == null
            ? null
            : (rawDb) {
                final escaped = encryptionKey!.replaceAll("'", "''");
                rawDb.execute("PRAGMA key = '$escaped'");
              },
      ),
    );
    // マイグレーション完了を待ってから列修復（createInBackground 対策）
    await db.customStatement('SELECT 1');
    await _addArtifactsColumnSafely(db);
    await _addArtifactScoreTypeColumnSafely(db);
    await _addUpgradeContentHashColumnsSafely(db);
    return db;
  }

  /// テスト用インメモリ DB
  static Future<DriftAppDatabase> openInMemory() async {
    final db = DriftAppDatabase(NativeDatabase.memory());
    await db.customStatement('SELECT 1');
    return db;
  }
}
