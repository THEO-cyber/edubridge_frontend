import '../entities/live_session_entity.dart';

abstract class LiveSessionRepository {
  Future<List<LiveSessionEntity>> fetchLiveSessions(String token);
  Future<void> requestLiveSession(String token, Map<String, dynamic> body);
  Future<void> joinLiveSession(String sessionId, String token);
}
