import '../../domain/account/account_snapshot.dart';
import '../../domain/planning/growth_goal.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/growth_goal_repository.dart';
import '../../domain/repositories/material_inventory_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/team_repository.dart';

/// Builds an [AccountSnapshot] from multiple repositories.
class BuildAccountSnapshotUseCase {
  BuildAccountSnapshotUseCase({
    required this.characterRepo,
    required this.progressRepo,
    required this.goalRepo,
    required this.inventoryRepo,
    required this.teamRepo,
    required this.userId,
  });

  final CharacterRepository characterRepo;
  final ProgressRepository progressRepo;
  final GrowthGoalRepository goalRepo;
  final MaterialInventoryRepository inventoryRepo;
  final TeamRepository teamRepo;
  final String userId;

  Future<AccountSnapshot> call() async {
    final characters = await characterRepo.getAll();
    final progressList = await progressRepo.getAll(userId);
    final goals = await goalRepo.getAll(userId);
    final inventory = await inventoryRepo.getInventory(userId);
    final teams = await teamRepo.getAll(userId);
    final progressMap = {for (final p in progressList) p.characterId: p};

    final snapshots = characters.map((mc) {
      final progress = progressMap[mc.id];
      return CharacterSnapshot(
        characterId: mc.id,
        name: mc.name,
        element: mc.element,
        weaponType: mc.weaponType,
        rarity: mc.rarity,
        region: mc.region,
        isOwned: progress != null,
        level: progress?.level ?? 1,
        ascension: progress?.ascension ?? 0,
        constellation: progress?.constellation ?? 0,
        talentNormal: progress?.talentNormal ?? 1,
        talentSkill: progress?.talentSkill ?? 1,
        talentBurst: progress?.talentBurst ?? 1,
        equippedWeaponId: progress?.weaponId,
        equippedWeaponName: progress?.weaponName,
        weaponLevel: progress?.weaponLevel ?? 1,
        weaponRefinement: progress?.weaponRefinement ?? 1,
        artifactCompletion: _calcArtifactCompletion(progress),
        artifactCompletionAvailable: progress?.artifactCompleted != null,
        memo: progress?.memo,
      );
    }).toList();

    return AccountSnapshot(
      userId: userId,
      characters: snapshots,
      materialInventory: inventory,
      savedTeams: teams,
      activeGoals: goals.where((g) => g.status == GrowthGoalStatus.active).toList(),
      weekday: DateTime.now().weekday,
      acquiredAt: DateTime.now(),
      sources: ['characterRepository', 'progressRepository', 'growthGoalRepository',
                'materialInventoryRepository', 'teamRepository'],
    );
  }

  double _calcArtifactCompletion(dynamic progress) {
    // Reuse existing artifact completion if available.
    // Returns 0.0 for now — proper calc uses artifact_state module.
    return progress?.artifactCompleted == true ? 1.0 : 0.0;
  }
}
