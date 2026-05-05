import '../../domain/entities/live_session_entity.dart';
import '../../domain/repositories/live_session_repository.dart';
import '../datasources/live_session_remote_data_source.dart';

class LiveSessionRepositoryImpl implements LiveSessionRepository {
  final LiveSessionRemoteDataSource remoteDataSource;
  LiveSessionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<LiveSessionEntity>> fetchLiveSessions(String token) async {
    final data = await remoteDataSource.fetchLiveSessions(token);
    return data
        .map(
          (e) => LiveSessionEntity(
            id: e['id'],
            title: e['title'],
            instructorId: e['instructorId'],
            scheduledAt: DateTime.parse(e['scheduledAt']),
            description: e['description'],
          ),
        )
        .toList();
  }

  @override
  Future<void> requestLiveSession(
    String token,
    Map<String, dynamic> body,
  ) async {
    await remoteDataSource.requestLiveSession(token, body);
  }

  @override
  Future<void> joinLiveSession(String sessionId, String token) async {
    await remoteDataSource.joinLiveSession(sessionId, token);
  }
}
