import '../../domain/models/calculation_models.dart';
import '../db/app_database.dart';
import '../models/master_models.dart';

class CharacterRepository {
  CharacterRepository(this._db);

  final AppDatabase _db;

  Future<List<MasterCharacter>> getAll() => _db.getAllCharacters();

  Future<MasterCharacter?> getById(String id) => _db.getCharacter(id);

  Future<Map<String, MasterMaterial>> getMaterialsMap() =>
      _db.getMaterialsMap();

  Future<
      ({
        List<PromoteStage> promotes,
        Map<String, List<TalentLevelUpgrade>> talents,
      })?> getUpgrade(String characterId) =>
      _db.getCharacterUpgrade(characterId);
}

class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;

  Future<UserProgress> getOrCreate({
    required String userId,
    required String characterId,
    required String progressId,
  }) =>
      _db.getOrCreateProgress(userId, characterId, progressId);

  Future<void> save(UserProgress progress) => _db.upsertProgress(progress);
}
