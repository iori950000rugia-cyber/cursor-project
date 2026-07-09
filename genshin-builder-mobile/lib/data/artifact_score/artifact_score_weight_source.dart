import 'artifact_score_weight.dart';

/// 聖遺物スコア重みの取得元を抽象化する。
/// 将来的に Remote 実装へ差し替えても repository 利用側を変えない。
abstract class ArtifactScoreWeightSource {
  Future<List<ArtifactScoreWeightProfile>> loadProfiles();
}

/// リモート等から最新データを明示的に再取得できる Source。
abstract class RefreshableArtifactScoreWeightSource
    implements ArtifactScoreWeightSource {
  Future<List<ArtifactScoreWeightProfile>> refreshProfiles();
}
