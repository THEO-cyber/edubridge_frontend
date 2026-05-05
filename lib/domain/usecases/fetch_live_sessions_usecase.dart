import '../entities/live_session_entity.dart';
import '../repositories/live_session_repository.dart';

class FetchLiveSessionsUseCase {
  final LiveSessionRepository repository;
  FetchLiveSessionsUseCase(this.repository);

  Future<List<LiveSessionEntity>> call(String token) {
    return repository.fetchLiveSessions(token);
  }
}
