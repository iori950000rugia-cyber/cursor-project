import '../models/master_models.dart';

/// ユーザー進捗の読み書き契約。
abstract class ProgressRepository {
  Future<UserProgress> getOrCreate({
    required String userId,
    required String characterId,
    required String progressId,
  });

  Future<List<UserProgress>> getAll(String userId);

  Future<void> save(UserProgress progress);
}
