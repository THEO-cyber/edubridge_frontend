import '../entities/live_session_entity.dart';
import '../repositories/live_session_repository.dart';

// Student Use Cases
class FetchAvailableLiveSessionsUseCase {
  final LiveSessionRepository repository;
  FetchAvailableLiveSessionsUseCase(this.repository);

  Future<List<LiveSessionEntity>> call(String token) {
    return repository.fetchLiveSessions(token);
  }
}

class GetLiveSessionDetailUseCase {
  final LiveSessionRepository repository;
  GetLiveSessionDetailUseCase(this.repository);

  Future<LiveSessionEntity?> call(String sessionId, String token) {
    return repository.fetchLiveSessionDetail(sessionId, token);
  }
}

class RequestLiveSessionUseCase {
  final LiveSessionRepository repository;
  RequestLiveSessionUseCase(this.repository);

  Future<void> call(String token, String sessionId, String courseId) {
    return repository.requestLiveSession(token, sessionId, courseId);
  }
}

class FetchMySessionRequestsUseCase {
  final LiveSessionRepository repository;
  FetchMySessionRequestsUseCase(this.repository);

  Future<List<LiveSessionRequestEntity>> call(String token) {
    return repository.fetchMySessionRequests(token);
  }
}

class JoinLiveSessionUseCase {
  final LiveSessionRepository repository;
  JoinLiveSessionUseCase(this.repository);

  Future<void> call(String sessionId, String token) {
    return repository.joinLiveSession(sessionId, token);
  }
}

class LeaveLiveSessionUseCase {
  final LiveSessionRepository repository;
  LeaveLiveSessionUseCase(this.repository);

  Future<void> call(String sessionId, String token) {
    return repository.leaveLiveSession(sessionId, token);
  }
}

// Lecturer Use Cases
class FetchMyLiveSessionsUseCase {
  final LiveSessionRepository repository;
  FetchMyLiveSessionsUseCase(this.repository);

  Future<List<LiveSessionEntity>> call(String token) {
    return repository.fetchMyLiveSessions(token);
  }
}

class CreateLiveSessionUseCase {
  final LiveSessionRepository repository;
  CreateLiveSessionUseCase(this.repository);

  Future<void> call(String token, Map<String, dynamic> body) {
    return repository.createLiveSession(token, body);
  }
}

class ScheduleLiveSessionUseCase {
  final LiveSessionRepository repository;
  ScheduleLiveSessionUseCase(this.repository);

  Future<void> call(String token, String sessionId, Map<String, dynamic> body) {
    return repository.scheduleLiveSession(token, sessionId, body);
  }
}

class FetchSessionRequestsUseCase {
  final LiveSessionRepository repository;
  FetchSessionRequestsUseCase(this.repository);

  Future<List<LiveSessionRequestEntity>> call(String sessionId, String token) {
    return repository.fetchSessionRequests(sessionId, token);
  }
}

class AcceptSessionRequestUseCase {
  final LiveSessionRepository repository;
  AcceptSessionRequestUseCase(this.repository);

  Future<void> call(String requestId, String token, {String? feedback}) {
    return repository.acceptSessionRequest(requestId, token, feedback: feedback);
  }
}

class RejectSessionRequestUseCase {
  final LiveSessionRepository repository;
  RejectSessionRequestUseCase(this.repository);

  Future<void> call(String requestId, String token, String rejectionReason) {
    return repository.rejectSessionRequest(requestId, token, rejectionReason);
  }
}

class EndLiveSessionUseCase {
  final LiveSessionRepository repository;
  EndLiveSessionUseCase(this.repository);

  Future<void> call(String sessionId, String token) {
    return repository.endLiveSession(sessionId, token);
  }
}

class RecordAttendanceUseCase {
  final LiveSessionRepository repository;
  RecordAttendanceUseCase(this.repository);

  Future<void> call(String sessionId, String token, List<String> attendeeIds) {
    return repository.recordAttendance(sessionId, token, attendeeIds);
  }
}

// Analytics Use Cases
class FetchSessionAnalyticsUseCase {
  final LiveSessionRepository repository;
  FetchSessionAnalyticsUseCase(this.repository);

  Future<SessionAnalyticsEntity> call(String sessionId, String token) {
    return repository.fetchSessionAnalytics(sessionId, token);
  }
}

class FetchCourseSessionsAnalyticsUseCase {
  final LiveSessionRepository repository;
  FetchCourseSessionsAnalyticsUseCase(this.repository);

  Future<List<SessionAnalyticsEntity>> call(String courseId, String token) {
    return repository.fetchCourseSessionsAnalytics(courseId, token);
  }
}

class FetchOverallAnalyticsUseCase {
  final LiveSessionRepository repository;
  FetchOverallAnalyticsUseCase(this.repository);

  Future<Map<String, dynamic>> call(String token) {
    return repository.fetchOverallAnalytics(token);
  }
}

// Attendance Use Cases
class FetchSessionAttendanceUseCase {
  final LiveSessionRepository repository;
  FetchSessionAttendanceUseCase(this.repository);

  Future<List<AttendanceRecordEntity>> call(String sessionId, String token) {
    return repository.fetchSessionAttendance(sessionId, token);
  }
}

class MarkAttendanceUseCase {
  final LiveSessionRepository repository;
  MarkAttendanceUseCase(this.repository);

  Future<void> call(String sessionId, String studentId, String token) {
    return repository.markAttendance(sessionId, studentId, token);
  }
}
