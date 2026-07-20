import '../../domain/repositories/team_recommendation_repository.dart';
import '../../domain/team_recommendation/team_recommendation.dart';
import 'backend_team_recommendation_api.dart';

class HttpTeamRecommendationRepository implements TeamRecommendationRepository {
  const HttpTeamRecommendationRepository(this.api);
  final BackendTeamRecommendationApi api;
  @override
  Future<TeamSimulationJob> enqueue(TeamRecommendationRequest request) =>
      api.enqueue(request);
  @override
  Future<TeamSimulationJob> getJob(String jobId) => api.getJob(jobId);
}
