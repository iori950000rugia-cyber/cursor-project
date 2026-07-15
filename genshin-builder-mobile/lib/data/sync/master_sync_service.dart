import 'dart:async';
import 'dart:math';

import '../amber/amber_api.dart';
import '../amber/amber_upgrade.dart';
import '../config/level_exp_table_source.dart';
import '../config/remote_json_fetch.dart';
import '../db/app_database.dart';
import '../models/sync_status.dart';

class SyncResult {
  SyncResult({
    required this.provider,
    this.characters = 0,
    this.weapons = 0,
    this.materials = 0,
    this.characterUpgrades = 0,
    this.weaponUpgrades = 0,
    this.levelExpSegments = 0,
    this.expMaterials = 0,
    this.skippedCharacterUpgrades = 0,
    this.skippedWeaponUpgrades = 0,
    List<String>? errors,
  }) : errors = errors ?? <String>[];

  final String provider;
  int characters;
  int weapons;
  int materials;
  int characterUpgrades;
  int weaponUpgrades;
  int levelExpSegments;
  int expMaterials;
  int skippedCharacterUpgrades;
  int skippedWeaponUpgrades;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'Sync($provider): chars=$characters weapons=$weapons materials=$materials '
      'charUp=$characterUpgrades wpnUp=$weaponUpgrades '
      'expSeg=$levelExpSegments expMat=$expMaterials '
      'skipChar=$skippedCharacterUpgrades skipWpn=$skippedWeaponUpgrades '
      'errors=${errors.length}';
}

typedef SyncProgressCallback = void Function(SyncProgress progress);

enum MasterSyncWritePoint {
  characters,
  weapons,
  materials,
  expMaterials,
  levelExpSegments,
  characterUpgrades,
  weaponUpgrades,
  syncLog,
}

typedef MasterSyncWriteFaultHook =
    FutureOr<void> Function(MasterSyncWritePoint point);

/// マスターデータ同期（Web `sync.ts` + `sync-upgrade.ts` 相当）
class MasterSyncService {
  MasterSyncService({
    required AmberApi amberApi,
    required AppDatabase db,
    AmberUpgradeApi? upgradeApi,
    LevelExpTableSource? levelExpTableSource,
    this.syncUpgradeDetails = true,
    this.fullUpgrade = false,
    this.refreshStaleUpgrades = true,
    this.staleUpgradeSampleSize = 15,
    this.overallTimeout = const Duration(minutes: 5),
    MasterSyncWriteFaultHook? writeFaultHook,
  }) : _amber = amberApi,
       _upgrade = upgradeApi ?? AmberUpgradeApi(),
       _db = db,
       _writeFaultHook = writeFaultHook,
       _levelExpTableSource = levelExpTableSource ?? LevelExpTableSource();

  final AmberApi _amber;
  final AmberUpgradeApi _upgrade;
  final AppDatabase _db;
  final MasterSyncWriteFaultHook? _writeFaultHook;
  final LevelExpTableSource _levelExpTableSource;
  final bool syncUpgradeDetails;
  final bool fullUpgrade;

  /// 通常同期で既存突破を最大 N 件ランダム再取得して Amber 変更を取り込む。
  final bool refreshStaleUpgrades;
  final int staleUpgradeSampleSize;
  final Duration overallTimeout;
  bool _cancelled = false;

  static const _expMaterialCount = 6;
  static const _levelExpSegmentCount = 32;

  void _report(SyncProgressCallback? onProgress, SyncProgress progress) {
    onProgress?.call(progress);
  }

  Future<SyncResult> syncMasterData({SyncProgressCallback? onProgress}) async {
    _cancelled = false;
    final pending = _syncMasterData(onProgress: onProgress);
    try {
      return await pending.timeout(overallTimeout);
    } on TimeoutException {
      _cancelled = true;
      _upgrade.dispose();
      unawaited(
        pending.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
      );
      rethrow;
    }
  }

  Future<SyncResult> _syncMasterData({SyncProgressCallback? onProgress}) async {
    final result = SyncResult(provider: AmberApi.name);

    _report(
      onProgress,
      const SyncProgress(phase: SyncPhase.master, current: 0, total: 3),
    );

    try {
      final characters = await _amber.fetchCharacters();
      await _writeAtomically(
        MasterSyncWritePoint.characters,
        () => _db.upsertCharactersBatch(characters),
      );
      result.characters = characters.length;
      _report(
        onProgress,
        const SyncProgress(phase: SyncPhase.master, current: 1, total: 3),
      );
    } catch (e) {
      _recordPhaseError(result, 'characters', e);
    }

    try {
      final weapons = await _amber.fetchWeapons();
      await _writeAtomically(
        MasterSyncWritePoint.weapons,
        () => _db.upsertWeaponsBatch(weapons),
      );
      result.weapons = weapons.length;
      _report(
        onProgress,
        const SyncProgress(phase: SyncPhase.master, current: 2, total: 3),
      );
    } catch (e) {
      _recordPhaseError(result, 'weapons', e);
    }

    try {
      final materials = await _amber.fetchMaterials();
      await _writeAtomically(
        MasterSyncWritePoint.materials,
        () => _db.upsertMaterialsBatch(materials),
      );
      result.materials = materials.length;
      _report(
        onProgress,
        const SyncProgress(phase: SyncPhase.master, current: 3, total: 3),
      );
    } catch (e) {
      _recordPhaseError(result, 'materials', e);
    }

    if (syncUpgradeDetails) {
      await _syncExpMaterials(result, onProgress);
      await _syncLevelExpSegments(result, onProgress);
      await _syncCharacterUpgrades(result, onProgress);
      await _syncWeaponUpgrades(result, onProgress);
    }

    _report(
      onProgress,
      const SyncProgress(phase: SyncPhase.finishing, current: 1, total: 1),
    );

    final status = result.hasErrors ? 'partial' : 'success';
    await _writeAtomically(
      MasterSyncWritePoint.syncLog,
      () => _db.insertSyncLog(status, result.toString()),
    );

    return result;
  }

  void _ensureActive() {
    if (_cancelled) {
      throw TimeoutException('Master sync timed out');
    }
  }

  Future<void> _writeAtomically(
    MasterSyncWritePoint point,
    Future<void> Function() action,
  ) {
    return _db.transaction(() async {
      _ensureActive();
      await action();
      await _writeFaultHook?.call(point);
      _ensureActive();
    });
  }

  void _recordPhaseError(SyncResult result, String phase, Object error) {
    if (_cancelled || error is TimeoutException) {
      throw TimeoutException('Master sync timed out');
    }
    final code = switch (error) {
      RemoteJsonFetchException failure => failure.reasonCode,
      FormatException _ => 'invalidData',
      _ => 'unavailable',
    };
    result.errors.add('$phase:$code');
  }

  Future<void> _syncExpMaterials(
    SyncResult result,
    SyncProgressCallback? onProgress,
  ) async {
    _report(
      onProgress,
      const SyncProgress(phase: SyncPhase.expMaterials, current: 0, total: 1),
    );
    try {
      final existing = await _db.countExpMaterials();
      if (!fullUpgrade && existing >= _expMaterialCount) {
        result.expMaterials = existing;
        _report(
          onProgress,
          const SyncProgress(
            phase: SyncPhase.expMaterials,
            current: 1,
            total: 1,
            detail: 'スキップ（取得済み）',
          ),
        );
        return;
      }

      final mats = await _upgrade.fetchLevelUpMaterials();
      await _writeAtomically(MasterSyncWritePoint.expMaterials, () async {
        for (final mat in mats) {
          await _db.updateMaterialExp(
            materialId: mat.materialId,
            expValue: mat.exp,
            expTarget: mat.targetType,
          );
        }
      });
      result.expMaterials = mats.length;
      _report(
        onProgress,
        SyncProgress(
          phase: SyncPhase.expMaterials,
          current: 1,
          total: 1,
          detail: '${mats.length} 件',
        ),
      );
    } catch (e) {
      _recordPhaseError(result, 'expMaterials', e);
    }
  }

  Future<void> _syncLevelExpSegments(
    SyncResult result,
    SyncProgressCallback? onProgress,
  ) async {
    _report(
      onProgress,
      const SyncProgress(phase: SyncPhase.levelExp, current: 0, total: 1),
    );
    try {
      final existing = await _db.countLevelExpSegments();
      if (!fullUpgrade && existing >= _levelExpSegmentCount) {
        result.levelExpSegments = existing;
        _report(
          onProgress,
          const SyncProgress(
            phase: SyncPhase.levelExp,
            current: 1,
            total: 1,
            detail: 'スキップ（取得済み）',
          ),
        );
        return;
      }

      final segments = await _levelExpTableSource.loadSegments();
      await _writeAtomically(
        MasterSyncWritePoint.levelExpSegments,
        () => _db.upsertLevelExpSegments(segments),
      );
      result.levelExpSegments = segments.length;
      _report(
        onProgress,
        SyncProgress(
          phase: SyncPhase.levelExp,
          current: 1,
          total: 1,
          detail: '${segments.length} 件',
        ),
      );
    } catch (e) {
      _recordPhaseError(result, 'levelExpSegments', e);
    }
  }

  /// 未取得・空ハッシュ UNION ランダム再取得サンプル
  List<String> _selectUpgradeTargetIds({
    required List<String> allIds,
    required Map<String, String> hashes,
  }) {
    if (fullUpgrade) return List<String>.from(allIds);

    final target = <String>{};
    for (final id in allIds) {
      final hash = hashes[id];
      if (hash == null || hash.isEmpty) {
        target.add(id);
      }
    }

    if (refreshStaleUpgrades) {
      final hashed = allIds
        .where((id) => (hashes[id] ?? '').isNotEmpty)
        .toList(growable: true)..shuffle(Random());
      final sample = hashed.take(staleUpgradeSampleSize);
      target.addAll(sample);
    }

    return target.toList(growable: false);
  }

  Future<void> _syncCharacterUpgrades(
    SyncResult result,
    SyncProgressCallback? onProgress,
  ) async {
    try {
      final allCharacters = await _db.getAllCharacters();
      final hashes =
          fullUpgrade
              ? <String, String>{}
              : await _db.getCharacterUpgradeHashes();
      final allIds = allCharacters.map((c) => c.id).toList(growable: false);
      final targetIds = _selectUpgradeTargetIds(allIds: allIds, hashes: hashes);

      result.skippedCharacterUpgrades = allIds.length - targetIds.length;

      _report(
        onProgress,
        SyncProgress(
          phase: SyncPhase.characterUpgrades,
          current: 0,
          total: targetIds.length,
          detail: targetIds.isEmpty ? 'スキップ（取得済み）' : null,
        ),
      );

      final upgrades = await _upgrade.mapWithConcurrency(
        targetIds,
        (id) async {
          final data = await _upgrade.fetchCharacterUpgrade(id);
          if (data == null) return null;
          return (
            characterId: id,
            promotes: data.promotes,
            talents: data.talents,
          );
        },
        onProgress: (completed, total) {
          _report(
            onProgress,
            SyncProgress(
              phase: SyncPhase.characterUpgrades,
              current: completed,
              total: total,
            ),
          );
        },
      );

      await _writeAtomically(MasterSyncWritePoint.characterUpgrades, () async {
        for (final upgrade in upgrades) {
          await _db.upsertCharacterUpgrade(
            characterId: upgrade.characterId,
            promotes: upgrade.promotes,
            talents: upgrade.talents,
          );
        }
      });

      result.characterUpgrades =
          (await _db.getSyncedCharacterUpgradeIds()).length;
    } catch (e) {
      _recordPhaseError(result, 'characterUpgrades', e);
    }
  }

  Future<void> _syncWeaponUpgrades(
    SyncResult result,
    SyncProgressCallback? onProgress,
  ) async {
    try {
      final allWeapons = await _db.getAllWeapons();
      final hashes =
          fullUpgrade ? <String, String>{} : await _db.getWeaponUpgradeHashes();
      final allIds = allWeapons.map((w) => w.id).toList(growable: false);
      final targetIds = _selectUpgradeTargetIds(allIds: allIds, hashes: hashes);

      result.skippedWeaponUpgrades = allIds.length - targetIds.length;

      _report(
        onProgress,
        SyncProgress(
          phase: SyncPhase.weaponUpgrades,
          current: 0,
          total: targetIds.length,
          detail: targetIds.isEmpty ? 'スキップ（取得済み）' : null,
        ),
      );

      final upgrades = await _upgrade.mapWithConcurrency(
        targetIds,
        (id) async {
          final data = await _upgrade.fetchWeaponUpgrade(id);
          if (data == null) return null;
          return (
            weaponId: id,
            promotes: data.promotes,
            levelUpItemIds: data.levelUpItemIds,
          );
        },
        onProgress: (completed, total) {
          _report(
            onProgress,
            SyncProgress(
              phase: SyncPhase.weaponUpgrades,
              current: completed,
              total: total,
            ),
          );
        },
      );

      await _writeAtomically(MasterSyncWritePoint.weaponUpgrades, () async {
        for (final upgrade in upgrades) {
          await _db.upsertWeaponUpgrade(
            weaponId: upgrade.weaponId,
            promotes: upgrade.promotes,
            levelUpItemIds: upgrade.levelUpItemIds,
          );
        }
      });

      result.weaponUpgrades = (await _db.getSyncedWeaponUpgradeIds()).length;
    } catch (e) {
      _recordPhaseError(result, 'weaponUpgrades', e);
    }
  }
}
