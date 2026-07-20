import '../team_recommendation/team_recommendation.dart';

abstract class TeamRecommendationRepository {
  Future<TeamSimulationJob> enqueue(TeamRecommendationRequest request);
  Future<TeamSimulationJob> getJob(String jobId);
}
