import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/hoyolab/models/game_record.dart';
import '../../data/artifact_score/artifact_score_weight.dart';
import '../../data/models/master_models.dart';
import '../../domain/bookmark_utils.dart';
import '../../domain/hoyolab_slider_sync.dart';
import '../../domain/level_config.dart';
import '../../domain/level_progression.dart';
import '../../domain/material_requirements.dart';
import '../../domain/artifact_score.dart';
import '../../domain/artifact_score_resolver.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/calculation_models.dart';
import '../../domain/hoyolab_relic_sync.dart';
import '../../domain/models/artifact_state.dart';
import '../../providers/app_providers.dart';
import '../../providers/hoyolab_game_providers.dart';
import '../hoyolab/widgets/hoyolab_character_status_card.dart';
import '../shared/mark_slider.dart';
import '../shared/material_list_tile.dart';
import '../shared/max_enhanced_banner.dart';
import 'widgets/character_detail_bookmark_actions.dart';
import 'widgets/character_detail_header.dart';
import 'widgets/character_talent_sections_list.dart';
import 'widgets/character_relics_section.dart';
import 'widgets/weapon_materials_section.dart';

class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({super.key, required this.characterId});

  final String characterId;

  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _saveDebounceMs = 800;
  static const _tabCount = 5;

  late TabController _tabController;

  int _level = 1;
  int _targetLevel = levelMax;
  int _talentNormal = 1;
  int _talentSkill = 1;
  int _talentBurst = 1;
  int _weaponLevel = 1;
  int _targetWeaponLevel = levelMax;
  String _weaponId = '';
  String _weaponName = '';
  int _weaponRarity = 4;
  ArtifactState _artifacts = createEmptyArtifactState();

  MasterCharacter? _character;
  UserProgress? _progress;
  List<MasterWeapon> _weapons = [];
  List<PromoteStage> _promotes = [];
  List<PromoteStage> _weaponPromotes = [];
  Map<String, List<TalentLevelUpgrade>> _talents = {};
  Map<String, MasterMaterial> _materials = {};
  List<MaterialBookmarkEntry> _bookmarks = [];
  bool _loading = true;
  String? _error;
  Timer? _saveTimer;
  bool _hoyolabSynced = false;
  DateTime? _lastHoyolabFetchedAt;
  ArtifactScoreType _artifactScoreType = ArtifactScoreType.atk;
  ArtifactScoreType _resolvedArtifactScoreType = ArtifactScoreType.atk;
  ArtifactStatWeights _artifactScoreWeights = scoreWeightsForType(
    ArtifactScoreType.atk,
  );
  bool _artifactScoreTypeUserSet = false;
  late final CharacterDetailBookmarkActions _bookmarkActions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _bookmarkActions = CharacterDetailBookmarkActions(
      ref: ref,
      getContext: () => context,
      getBookmarks: () => _bookmarks,
      setBookmarks: (bookmarks) => _bookmarks = bookmarks,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      getMaterials: () => _materials,
      getLevel: () => _level,
      getTargetLevel: () => _targetLevel,
      getWeaponLevel: () => _weaponLevel,
      getTargetWeaponLevel: () => _targetWeaponLevel,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final charRepo = await ref.read(characterRepositoryProvider.future);
      final progressRepo = await ref.read(progressRepositoryProvider.future);
      final bookmarkRepo = await ref.read(bookmarkRepositoryProvider.future);
      final userId = await ref.read(localUserIdProvider.future);

      _character = await charRepo.getById(widget.characterId);
      final upgrade = await charRepo.getUpgrade(widget.characterId);
      _promotes = upgrade?.promotes ?? [];
      _talents = upgrade?.talents ?? {};
      _weapons = await charRepo.getAllWeapons();
      _materials = await ref.read(materialsMapProvider.future);

      _progress = await progressRepo.getOrCreate(
        userId: userId,
        characterId: widget.characterId,
        progressId: const Uuid().v4(),
      );

      _weaponId = _progress!.weaponId;
      _weaponName = _progress!.weaponName;
      _weaponLevel = _progress!.weaponLevel;
      await _loadWeaponUpgrade();
      await _loadArtifactScoreSettings();

      final bookmarks = await bookmarkRepo.getAll();
      if (!mounted) return;
      setState(() {
        _level = _progress!.level;
        _talentNormal = _progress!.talentNormal;
        _talentSkill = _progress!.talentSkill;
        _talentBurst = _progress!.talentBurst;
        _artifacts = _progress!.artifacts;
        _bookmarks = bookmarks;
        _loading = false;
      });
      await _syncFromHoyolab();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadWeaponUpgrade() async {
    if (_weaponId.isEmpty) {
      _weaponPromotes = [];
      _weaponRarity = 4;
      return;
    }
    final charRepo = await ref.read(characterRepositoryProvider.future);
    final weapon =
        _weapons.where((w) => w.id == _weaponId).firstOrNull ??
            await charRepo.getWeapon(_weaponId);
    if (weapon != null) {
      _weaponRarity = weapon.rarity;
      _weaponName = weapon.name;
    }
    final weaponUpgrade = await charRepo.getWeaponUpgrade(_weaponId);
    _weaponPromotes = weaponUpgrade?.promotes ?? [];
  }

  Future<void> _syncFromHoyolab() async {
    try {
      final build =
          await ref.read(hoyolabCharacterBuildProvider(widget.characterId).future);
      if (build != null && build.isOwned) {
        await _applyHoyolabBuild(build);
      }
    } catch (_) {
      // HoYoLAB 未連携・取得失敗時はローカル進捗のまま
    }
  }

  Future<void> _applyHoyolabBuildSafe(HoyolabCharacterBuild build) async {
    try {
      await _applyHoyolabBuild(build);
    } catch (_) {
      // HoYoLAB 反映失敗時も詳細画面は表示を継続
    }
  }

  Future<void> _applyHoyolabBuild(HoyolabCharacterBuild build) async {
    if (!build.isOwned || !mounted) return;

    if (_lastHoyolabFetchedAt != null &&
        build.fetchedAt != null &&
        !build.fetchedAt!.isAfter(_lastHoyolabFetchedAt!)) {
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

    if (build.relics.isNotEmpty) {
      _artifacts = mergeRelicsFromHoyolab(
        local: _artifacts,
        relics: build.relics,
      );
    }

    if (!mounted) return;
    setState(() {
      _level = snapshot.level;
      if (build.talents.isNotEmpty) {
        _talentNormal = snapshot.talentNormal;
        _talentSkill = snapshot.talentSkill;
        _talentBurst = snapshot.talentBurst;
      }
      _hoyolabSynced = true;
      _lastHoyolabFetchedAt = build.fetchedAt ?? DateTime.now();
      _progress = _progress?.copyWith(
        level: snapshot.level,
        ascension: snapshot.promoteLevel,
        constellation: snapshot.constellation,
        talentNormal:
            build.talents.isNotEmpty ? snapshot.talentNormal : null,
        talentSkill: build.talents.isNotEmpty ? snapshot.talentSkill : null,
        talentBurst: build.talents.isNotEmpty ? snapshot.talentBurst : null,
        weaponId: _weaponId,
        weaponName: _weaponName,
        weaponLevel: _weaponLevel,
        weaponRefinement:
            snapshot.weaponRefinement ?? _progress?.weaponRefinement ?? 1,
        artifacts: _artifacts,
      );
    });
    _scheduleSave();
  }

  Future<void> _applyWeaponSnapshot(HoyolabSliderSnapshot snapshot) async {
    MasterWeapon? matched;
    if (snapshot.weaponId != null) {
      matched = _weapons.where((w) => w.id == snapshot.weaponId).firstOrNull;
    }
    matched ??= snapshot.weaponName == null
        ? null
        : _weapons.where((w) => w.name == snapshot.weaponName).firstOrNull;

    if (matched != null) {
      _weaponId = matched.id;
      _weaponName = matched.name;
      _weaponRarity = matched.rarity;
    } else if (snapshot.weaponId != null) {
      _weaponId = snapshot.weaponId!;
      _weaponName = snapshot.weaponName ?? '';
    }
    if (snapshot.weaponLevel != null) {
      _weaponLevel = snapshot.weaponLevel!;
    }
    await _loadWeaponUpgrade();
  }

  Future<void> _loadArtifactScoreSettings() async {
    final character = _character;
    if (character == null) return;

    final userScoreType =
        userArtifactScoreTypeFromStorage(_progress!.artifactScoreType);
    _artifactScoreTypeUserSet = userScoreType != null;

    final resolver = ArtifactScoreResolver(
      ref.read(artifactScoreWeightRepositoryProvider),
    );
    final autoSettings = await resolver.resolve(character: character);
    _resolvedArtifactScoreType = autoSettings.scoreType;

    final settings = await resolver.resolve(
      character: character,
      userScoreType: userScoreType,
      userScoreTypeIsSet: _artifactScoreTypeUserSet,
    );

    _artifactScoreType = settings.scoreType;
    _artifactScoreWeights = settings.weights;
  }

  void _scheduleSave() {
    final base = _progress;
    if (base == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: _saveDebounceMs),
      () => _persistProgress(base),
    );
  }

  Future<void> _persistProgress(UserProgress base) async {
    final updated = base.copyWith(
      level: _level,
      talentNormal: _talentNormal,
      talentSkill: _talentSkill,
      talentBurst: _talentBurst,
      weaponLevel: _weaponLevel,
      weaponId: _weaponId,
      weaponName: _weaponName,
      artifacts: _artifacts,
    );
    _progress = updated;
    try {
      final repo = await ref.read(progressRepositoryProvider.future);
      await repo.save(updated);
    } catch (_) {
      // 保存失敗は UI を落とさない
    }
  }

  void _updateLevel(int v) {
    setState(() => _level = v);
    _scheduleSave();
  }

  void _updateTalentNormal(int v) {
    setState(() => _talentNormal = v);
    _scheduleSave();
  }

  void _updateTalentSkill(int v) {
    setState(() => _talentSkill = v);
    _scheduleSave();
  }

  void _updateTalentBurst(int v) {
    setState(() => _talentBurst = v);
    _scheduleSave();
  }

  void _updateWeaponLevel(int v) {
    setState(() => _weaponLevel = v);
    _scheduleSave();
  }

  void _updateArtifacts(ArtifactState artifacts) {
    setState(() => _artifacts = artifacts);
    _scheduleSave();
  }

  void _updateArtifactScoreType(ArtifactScoreType type) {
    setState(() {
      _artifactScoreType = type;
      _artifactScoreWeights = scoreWeightsForType(type);
      _artifactScoreTypeUserSet = true;
    });
    _persistArtifactScoreType();
    _scheduleSave();
  }

  Future<void> _persistArtifactScoreType() async {
    final base = _progress;
    if (base == null) return;

    final updated = base.copyWith(
      artifactScoreType: _artifactScoreTypeUserSet
          ? artifactScoreTypeToUserStorage(_artifactScoreType)
          : '',
    );
    _progress = updated;
    try {
      final repo = await ref.read(progressRepositoryProvider.future);
      await repo.save(updated);
    } catch (_) {
      // 保存失敗は UI を落とさない
    }
  }

  Future<void> _onWeaponSelected(String? weaponId) async {
    if (weaponId == null || weaponId.isEmpty) {
      setState(() {
        _weaponId = '';
        _weaponName = '';
        _weaponPromotes = [];
        _weaponRarity = 4;
      });
    } else {
      final w = _weapons.where((x) => x.id == weaponId).firstOrNull;
      setState(() {
        _weaponId = weaponId;
        _weaponName = w?.name ?? '';
        _weaponRarity = w?.rarity ?? 4;
      });
      await _loadWeaponUpgrade();
      if (mounted) setState(() {});
    }
    _scheduleSave();
  }

  String _resolveName(String id) => _materials[id]?.name ?? '素材 #$id';

  String? _resolveIcon(String id) => _materials[id]?.iconUrl;

  CultivationBookmarkContext _characterBookmarkContext(
    MasterCharacter character,
  ) =>
      CultivationBookmarkContext(
        kind: CultivationKind.characterLevel,
        targetId: character.id,
        targetName: character.name,
        character: BookmarkCharacterSource(
          characterId: character.id,
          characterName: character.name,
          characterIconUrl: character.iconUrl,
        ),
      );

  CultivationBookmarkContext _weaponBookmarkContext(MasterCharacter character) =>
      CultivationBookmarkContext(
        kind: CultivationKind.weaponLevel,
        targetId: _weaponId.isEmpty ? character.id : _weaponId,
        targetName: _weaponName.isEmpty ? character.name : _weaponName,
        character: BookmarkCharacterSource(
          characterId: character.id,
          characterName: character.name,
          characterIconUrl: character.iconUrl,
        ),
      );

  bool _isBookmarked(String sourceKey, String materialId) =>
      _bookmarkActions.isBookmarked(sourceKey, materialId);

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<HoyolabCharacterBuild?>>(
      hoyolabCharacterBuildProvider(widget.characterId),
      (prev, next) {
        next.whenData((build) {
          if (build != null && build.isOwned && !_loading) {
            unawaited(_applyHoyolabBuildSafe(build));
          }
        });
      },
    );

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('エラー: $_error')));
    }

    final character = _character;
    if (character == null) {
      return const Scaffold(body: Center(child: Text('キャラが見つかりません')));
    }

    final rangeLines = getRangeLevelRequirements(
      _level,
      _targetLevel,
      _promotes,
      'character',
      resolveName: _resolveName,
      resolveIcon: _resolveIcon,
    );

    final nextStage =
        getNextStageRequirements(_level, _promotes, 'character', 5);
    final bookmarkCtx = _characterBookmarkContext(character);
    final weaponBookmarkCtx = _weaponBookmarkContext(character);
    final rangeSourceKey =
        makeRangeSourceKey(bookmarkCtx, _level, _targetLevel);

    final artifactScoreType = _artifactScoreType;
    final resolvedArtifactScoreType = _resolvedArtifactScoreType;

    return Scaffold(
      appBar: AppBar(title: const Text('キャラ詳細')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CharacterDetailHeader(character: character),
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'レベル'),
                Tab(text: '武器'),
                Tab(text: '聖遺物'),
                Tab(text: '天賦'),
                Tab(text: 'HoYoLAB'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLevelTab(
                  context: context,
                  character: character,
                  bookmarkCtx: bookmarkCtx,
                  rangeLines: rangeLines,
                  rangeSourceKey: rangeSourceKey,
                  nextStage: nextStage,
                ),
                _buildWeaponTab(
                  character: character,
                  weaponBookmarkCtx: weaponBookmarkCtx,
                ),
                _buildRelicsTab(
                  artifactScoreType: artifactScoreType,
                  resolvedArtifactScoreType: resolvedArtifactScoreType,
                ),
                _buildTalentTab(character: character),
                _buildHoyolabTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTab({
    required BuildContext context,
    required MasterCharacter character,
    required CultivationBookmarkContext bookmarkCtx,
    required List<RequirementLine> rangeLines,
    required String rangeSourceKey,
    required NextStageRequirements? nextStage,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_hoyolabSynced) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                Icons.sync,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: const Text('HoYoLAB のレベルを反映済み'),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_level >= levelMax) ...[
          MaxEnhancedBanner(label: 'キャラクターレベル', level: _level),
        ] else ...[
          LevelMarkSlider(
            label: '現在レベル',
            value: _level,
            onChanged: _updateLevel,
          ),
          const SizedBox(height: 16),
          LevelMarkSlider(
            label: '目標レベル',
            value: _targetLevel,
            onChanged: (v) => setState(() => _targetLevel = v),
            headerTrailing: IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: '範囲をブックマーク',
              onPressed: () => _bookmarkActions.bookmarkRange(
                bookmarkCtx,
                rangeLines,
                rangeSourceKey,
              ),
            ),
          ),
          const Divider(height: 32),
          Text('次の段階', style: Theme.of(context).textTheme.titleMedium),
          if (nextStage == null)
            const Text('最大レベルです')
          else
            ...nextStageToRequirementLines(
              nextStage.materials,
              nextStage.levelUpMaterials,
              nextStage.mora,
              _resolveName,
              resolveIcon: _resolveIcon,
            ).map(
              (line) {
                final sourceKey = makeItemSourceKey(
                  bookmarkCtx,
                  'next',
                  line.materialId,
                );
                return MaterialListTile(
                  line: line,
                  isBookmarked: _isBookmarked(sourceKey, line.materialId),
                  onToggleBookmark: () => _bookmarkActions.toggleLineBookmark(
                    bookmarkCtx,
                    line,
                    'next',
                  ),
                );
              },
            ),
          const Divider(height: 24),
          Text('目標までの合計', style: Theme.of(context).textTheme.titleMedium),
          ...rangeLines.map(
            (line) => MaterialListTile(
              line: line,
              isBookmarked: _isBookmarked(rangeSourceKey, line.materialId),
              onToggleBookmark: () => _bookmarkActions.toggleRangeLineBookmark(
                bookmarkCtx,
                line,
                rangeSourceKey,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeaponTab({
    required MasterCharacter character,
    required CultivationBookmarkContext weaponBookmarkCtx,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WeaponMaterialsSection(
          showTitle: true,
          weapons: _weapons,
          selectedWeaponId: _weaponId,
          weaponLevel: _weaponLevel,
          targetWeaponLevel: _targetWeaponLevel,
          promotes: _weaponPromotes,
          weaponRarity: _weaponRarity,
          bookmarkContext: weaponBookmarkCtx,
          bookmarks: _bookmarks,
          resolveName: _resolveName,
          resolveIcon: _resolveIcon,
          onWeaponSelected: _onWeaponSelected,
          onWeaponLevelChanged: _updateWeaponLevel,
          onTargetWeaponLevelChanged: (v) =>
              setState(() => _targetWeaponLevel = v),
          onToggleBookmark: (line, scope) => _bookmarkActions.toggleLineBookmark(
            weaponBookmarkCtx,
            line,
            scope,
          ),
          onToggleRangeBookmark: (line, rangeSourceKey) =>
              _bookmarkActions.toggleRangeLineBookmark(
            weaponBookmarkCtx,
            line,
            rangeSourceKey,
          ),
          onBookmarkRange: (lines, sourceKey) => _bookmarkActions.bookmarkRange(
            weaponBookmarkCtx,
            lines,
            sourceKey,
          ),
        ),
      ],
    );
  }

  Widget _buildRelicsTab({
    required ArtifactScoreType artifactScoreType,
    required ArtifactScoreType resolvedArtifactScoreType,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CharacterRelicsSection(
          artifacts: _artifacts,
          scoreType: artifactScoreType,
          resolvedScoreType: resolvedArtifactScoreType,
          scoreTypeUserSet: _artifactScoreTypeUserSet,
          weights: _artifactScoreWeights,
          onScoreTypeChanged: _updateArtifactScoreType,
          onChanged: _updateArtifacts,
        ),
      ],
    );
  }

  Widget _buildTalentTab({required MasterCharacter character}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CharacterTalentSectionsList(
          character: character,
          talents: _talents,
          talentNormal: _talentNormal,
          talentSkill: _talentSkill,
          talentBurst: _talentBurst,
          bookmarks: _bookmarks,
          resolveName: _resolveName,
          resolveIcon: _resolveIcon,
          onTalentNormalChanged: _updateTalentNormal,
          onTalentSkillChanged: _updateTalentSkill,
          onTalentBurstChanged: _updateTalentBurst,
          onToggleBookmark: _bookmarkActions.toggleLineBookmark,
          onBookmarkRange: _bookmarkActions.bookmarkRange,
          onToggleRangeLineBookmark: _bookmarkActions.toggleRangeLineBookmark,
        ),
      ],
    );
  }

  Widget _buildHoyolabTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HoyolabCharacterStatusCard(characterId: widget.characterId),
      ],
    );
  }
}
