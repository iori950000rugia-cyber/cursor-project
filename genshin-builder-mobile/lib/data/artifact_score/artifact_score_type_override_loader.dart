import 'artifact_score_type_override_registry.dart';
import 'local_json_artifact_score_type_override_source.dart';

void configureArtifactScoreTypeOverrideLoader() {
  ArtifactScoreTypeOverrideRegistry.configureLoader(() async {
    final source = LocalJsonArtifactScoreTypeOverrideSource();
    return source.loadByName();
  });
}
