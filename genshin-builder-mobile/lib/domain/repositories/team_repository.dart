import '../team/team_models.dart';

abstract class TeamRepository {
  Future<List<Team>> getAll(String userId);
  Future<Team?> getById(String id);
  Future<void> save(Team team);
  Future<void> delete(String id);
}
