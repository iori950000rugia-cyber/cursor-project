import '../planning/growth_goal.dart';

abstract class GrowthGoalRepository {
  Future<List<GrowthGoal>> getAll(String userId);
  Future<GrowthGoal?> getById(String id);
  Future<void> save(GrowthGoal goal);
  Future<void> delete(String id);
  Future<void> deleteByCharacterId(String userId, String characterId);
}
