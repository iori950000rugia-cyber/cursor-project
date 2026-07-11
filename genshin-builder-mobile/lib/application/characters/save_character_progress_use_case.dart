import '../../domain/models/master_models.dart';
import '../../domain/repositories/progress_repository.dart';
import 'character_detail_state.dart';

/// キャラ進捗の永続化。
class SaveCharacterProgressUseCase {
  const SaveCharacterProgressUseCase({
    required ProgressRepository progress,
  }) : _progress = progress;

  final ProgressRepository _progress;

  Future<UserProgress> call({
    required UserProgress base,
    required CharacterDetailState state,
  }) async {
    final updated = base.copyWith(
      level: state.level,
      constellation: state.constellation,
      talentNormal: state.talentNormal,
      talentSkill: state.talentSkill,
      talentBurst: state.talentBurst,
      weaponLevel: state.weaponLevel,
      weaponId: state.weaponId,
      weaponName: state.weaponName,
      artifacts: state.artifacts,
      artifactCompleted: state.artifactCompleted,
    );
    await _progress.save(updated);
    return updated;
  }
}
