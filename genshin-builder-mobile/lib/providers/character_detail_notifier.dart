import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/artifact_score/artifact_score_resolver.dart';
import '../data/hoyolab/hoyolab_relic_sync.dart';
import '../data/hoyolab/models/game_record.dart';
import '../domain/artifact_score.dart';
import '../domain/hoyolab_slider_sync.dart';
import '../domain/models/artifact_state.dart';
import '../domain/models/character_build_snapshot.dart';
import '../domain/models/master_models.dart';
import '../features/characters/character_detail_state.dart';
import 'app_providers.dart';
import 'hoyolab_game_providers.dart';

final characterDetailProvider = AutoDisposeNotifierProvider.family<
    CharacterDetailNotifier, CharacterDetailState, String>(
  CharacterDetailNotifier.new,
);

class CharacterDetailNotifier
    extends AutoDisposeFamilyNotifier<CharacterDetailState, String> {
  static const _saveDebounceMs = 800;

  Timer? _saveTimer;
  bool _disposed = false;

  String get characterId => arg;

  @override
  CharacterDetailState build(String characterId) {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _saveTimer?.cancel();
    });
    Future.microtask(_load);
    return CharacterDetailState.initial();
  }

  Future<void> _load() async {
    try {
      final charRepo = await ref.read(characterRepositoryProvider.future);
      final progressRepo = await ref.read(progressRepositoryProvider.future);
      final userId = await ref.read(localUserIdProvider.future);

      final character = await charRepo.getById(characterId);
      final upgrade = await charRepo.getUpgrade(characterId);
      final promotes = upgrade?.promotes ?? [];
      final talents = upgrade?.talents ?? {};
      final weapons = await charRepo.getAllWeapons();
      final materials = await ref.read(materialsMapProvider.future);

      final progress = await progressRepo.getOrCreate(
        userId: userId,
        characterId: characterId,
        progressId: const Uuid().v4(),
      );

      if (_disposed) return;
      state = state.copyWith(
        character: character,
        promotes: promotes,
        talents: talents,
        weapons: weapons,
        materials: materials,
        progress: progress,
        weaponId: progress.weaponId,
        weaponName: progress.weaponName,
        weaponLevel: progress.weaponLevel,
        clearError: true,
      );

      await _loadWeaponUpgrade();
      await _loadArtifactScoreSettings();

      if (_disposed) return;
      state = state.copyWith(
        level: progress.level,
        constellation: progress.constellation.clamp(0, 6),
        talentNormal: progress.talentNormal,
        talentSkill: progress.talentSkill,
        talentBurst: progress.talentBurst,
        artifacts: progress.artifacts,
        loading: false,
        clearError: true,
      );
      // HoYoLAB 未連携時のベースライン（連携時は apply 後に上書きされる）
      state = state.copyWith(fetchedSnapshot: state.snapshotFromCurrent());
      await _syncFromHoyolab();
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        error: '$e',
        loading: false,
      );
    }
  }

  Future<void> _loadWeaponUpgrade() async {
    if (state.weaponId.isEmpty) {
      state = state.copyWith(
        weaponPromotes: const [],
        weaponRarity: 4,
      );
      return;
    }
    final charRepo = await ref.read(characterRepositoryProvider.future);
    if (_disposed) return;
    final weapon = state.weapons.where((w) => w.id == state.weaponId).firstOrNull ??
        await charRepo.getWeapon(state.weaponId);
    if (_disposed) return;
    var weaponRarity = state.weaponRarity;
    var weaponName = state.weaponName;
    if (weapon != null) {
      weaponRarity = weapon.rarity;
      weaponName = weapon.name;
    }
    final weaponUpgrade = await charRepo.getWeaponUpgrade(state.weaponId);
    if (_disposed) return;
    state = state.copyWith(
      weaponRarity: weaponRarity,
      weaponName: weaponName,
      weaponPromotes: weaponUpgrade?.promotes ?? [],
    );
  }

  Future<void> _syncFromHoyolab() async {
    try {
      final build =
          await ref.read(hoyolabCharacterBuildProvider(characterId).future);
      if (build != null && build.isOwned) {
        await applyHoyolabBuild(build);
      }
    } catch (_) {
      // HoYoLAB 未連携・取得失敗時はローカル進捗のまま
    }
  }

  Future<void> applyHoyolabBuildSafe(HoyolabCharacterBuild build) async {
    try {
      await applyHoyolabBuild(build);
    } catch (_) {
      // HoYoLAB 反映失敗時も詳細画面は表示を継続
    }
  }

  Future<void> applyHoyolabBuild(HoyolabCharacterBuild build) async {
    if (!build.isOwned || _disposed) return;

    final lastFetched = state.lastHoyolabFetchedAt;
    if (lastFetched != null &&
        build.fetchedAt != null &&
        !build.fetchedAt!.isAfter(lastFetched)) {
      return;
    }

    final snapshot = buildHoyolabSliderSnapshot(
      level: build.level,
      promoteLevel: build.promoteLevel,
      constellation: build.constellation,
      talents: build.talents
          .map((t) => HoyolabTalentInput(name: t.name, level: t.level))
          .toList(),
      weaponId: build.weapon?.id,
      weaponName: build.weapon?.name,
      weaponLevel: build.weapon?.level,
      weaponRefinement: build.weapon?.refinement,
    );

    if (snapshot.weaponId != null || snapshot.weaponName != null) {
      await _applyWeaponSnapshot(snapshot);
    }
    if (_disposed) return;

    var artifacts = state.artifacts;
    if (build.relics.isNotEmpty) {
      artifacts = mergeRelicsFromHoyolab(
        local: artifacts,
        relics: build.relics,
      );
    }

    final weaponId = state.weaponId;
    final weaponName = state.weaponName;
    final weaponLevel = state.weaponLevel;

    state = state.copyWith(
      level: snapshot.level,
      constellation: snapshot.constellation.clamp(0, 6),
      talentNormal:
          build.talents.isNotEmpty ? snapshot.talentNormal : null,
      talentSkill: build.talents.isNotEmpty ? snapshot.talentSkill : null,
      talentBurst: build.talents.isNotEmpty ? snapshot.talentBurst : null,
      artifacts: artifacts,
      hoyolabSynced: true,
      lastHoyolabFetchedAt: build.fetchedAt ?? DateTime.now(),
      progress: state.progress?.copyWith(
        level: snapshot.level,
        ascension: snapshot.promoteLevel,
        constellation: snapshot.constellation,
        talentNormal:
            build.talents.isNotEmpty ? snapshot.talentNormal : null,
        talentSkill: build.talents.isNotEmpty ? snapshot.talentSkill : null,
        talentBurst: build.talents.isNotEmpty ? snapshot.talentBurst : null,
        weaponId: weaponId,
        weaponName: weaponName,
        weaponLevel: weaponLevel,
        weaponRefinement:
            snapshot.weaponRefinement ?? state.progress?.weaponRefinement ?? 1,
        artifacts: artifacts,
      ),
    );
    // HoYoLAB 取得値を「取得情報」ベースラインとして記録
    state = state.copyWith(fetchedSnapshot: state.snapshotFromCurrent());
    _scheduleSave();
  }

  /// 手動変更をすべて取得情報（スナップショット）へ戻す。確認ダイアログは Screen 側。
  Future<void> resetToFetched() async {
    final snap = state.fetchedSnapshot;
    if (snap == null) return;

    state = state.copyWith(
      level: snap.level,
      constellation: snap.constellation.clamp(0, 6),
      talentNormal: snap.talentNormal,
      talentSkill: snap.talentSkill,
      talentBurst: snap.talentBurst,
      weaponId: snap.weaponId,
      weaponName: snap.weaponName,
      weaponRarity: snap.weaponRarity,
      weaponLevel: snap.weaponLevel,
      artifacts: copyArtifactState(snap.artifacts),
    );
    await _loadWeaponUpgrade();
    if (_disposed) return;
    _scheduleSave();
  }

  Future<void> _applyWeaponSnapshot(HoyolabSliderSnapshot snapshot) async {
    MasterWeapon? matched;
    if (snapshot.weaponId != null) {
      matched =
          state.weapons.where((w) => w.id == snapshot.weaponId).firstOrNull;
    }
    matched ??= snapshot.weaponName == null
        ? null
        : state.weapons.where((w) => w.name == snapshot.weaponName).firstOrNull;

    if (matched != null) {
      state = state.copyWith(
        weaponId: matched.id,
        weaponName: matched.name,
        weaponRarity: matched.rarity,
      );
    } else if (snapshot.weaponId != null) {
      state = state.copyWith(
        weaponId: snapshot.weaponId!,
        weaponName: snapshot.weaponName ?? '',
      );
    }
    if (snapshot.weaponLevel != null) {
      state = state.copyWith(weaponLevel: snapshot.weaponLevel!);
    }
    await _loadWeaponUpgrade();
  }

  Future<void> _loadArtifactScoreSettings() async {
    final character = state.character;
    final progress = state.progress;
    if (character == null || progress == null) return;

    final userScoreType =
        userArtifactScoreTypeFromStorage(progress.artifactScoreType);
    final artifactScoreTypeUserSet = userScoreType != null;

    final resolver = ArtifactScoreResolver(
      ref.read(artifactScoreWeightRepositoryProvider),
    );
    final autoSettings = await resolver.resolve(character: character);
    final resolvedArtifactScoreType = autoSettings.scoreType;

    final settings = await resolver.resolve(
      character: character,
      userScoreType: userScoreType,
      userScoreTypeIsSet: artifactScoreTypeUserSet,
    );

    if (_disposed) return;
    state = state.copyWith(
      artifactScoreTypeUserSet: artifactScoreTypeUserSet,
      resolvedArtifactScoreType: resolvedArtifactScoreType,
      artifactScoreType: settings.scoreType,
      artifactScoreWeights: settings.weights,
    );
  }

  void _scheduleSave() {
    final base = state.progress;
    if (base == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: _saveDebounceMs),
      () => _persistProgress(base),
    );
  }

  Future<void> _persistProgress(UserProgress base) async {
    if (_disposed) return;
    final s = state;
    final updated = base.copyWith(
      level: s.level,
      constellation: s.constellation,
      talentNormal: s.talentNormal,
      talentSkill: s.talentSkill,
      talentBurst: s.talentBurst,
      weaponLevel: s.weaponLevel,
      weaponId: s.weaponId,
      weaponName: s.weaponName,
      artifacts: s.artifacts,
    );
    state = state.copyWith(progress: updated);
    try {
      final repo = await ref.read(progressRepositoryProvider.future);
      await repo.save(updated);
    } catch (_) {
      // 保存失敗は UI を落とさない
    }
  }

  void updateLevel(int v) {
    state = state.copyWith(level: v);
    _scheduleSave();
  }

  void updateTargetLevel(int v) {
    state = state.copyWith(targetLevel: v);
  }

  void updateTalentNormal(int v) {
    state = state.copyWith(talentNormal: v);
    _scheduleSave();
  }

  void updateTalentSkill(int v) {
    state = state.copyWith(talentSkill: v);
    _scheduleSave();
  }

  void updateTalentBurst(int v) {
    state = state.copyWith(talentBurst: v);
    _scheduleSave();
  }

  void updateWeaponLevel(int v) {
    state = state.copyWith(weaponLevel: v);
    _scheduleSave();
  }

  void updateTargetWeaponLevel(int v) {
    state = state.copyWith(targetWeaponLevel: v);
  }

  void updateArtifacts(ArtifactState artifacts) {
    state = state.copyWith(artifacts: artifacts);
    _scheduleSave();
  }

  void updateArtifactScoreType(ArtifactScoreType type) {
    state = state.copyWith(
      artifactScoreType: type,
      artifactScoreWeights: scoreWeightsForType(type),
      artifactScoreTypeUserSet: true,
    );
    unawaited(_persistArtifactScoreType());
    _scheduleSave();
  }

  Future<void> _persistArtifactScoreType() async {
    final base = state.progress;
    if (base == null) return;

    final updated = base.copyWith(
      artifactScoreType: state.artifactScoreTypeUserSet
          ? artifactScoreTypeToUserStorage(state.artifactScoreType)
          : '',
    );
    state = state.copyWith(progress: updated);
    try {
      final repo = await ref.read(progressRepositoryProvider.future);
      await repo.save(updated);
    } catch (_) {
      // 保存失敗は UI を落とさない
    }
  }

  /// 武器を外す（確認不要）。
  void clearWeapon() {
    state = state.copyWith(
      weaponId: '',
      weaponName: '',
      weaponPromotes: const [],
      weaponRarity: 4,
    );
    _scheduleSave();
  }

  /// 武器変更を適用（確認ダイアログは Screen 側）。
  Future<void> applyWeaponSelection(String weaponId) async {
    final newWeapon = state.weapons.where((x) => x.id == weaponId).firstOrNull;
    state = state.copyWith(
      weaponId: weaponId,
      weaponName: newWeapon?.name ?? '',
      weaponRarity: newWeapon?.rarity ?? 4,
    );
    await _loadWeaponUpgrade();
    if (_disposed) return;
    _scheduleSave();
  }

  CharacterBuildSnapshot snapshotFromCurrent() => state.snapshotFromCurrent();
}
