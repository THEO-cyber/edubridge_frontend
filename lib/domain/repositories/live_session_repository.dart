import '../entities/live_session_entity.dart';

abstract class LiveSessionRepository {
  // Student methods
  Future<List<LiveSessionEntity>> fetchLiveSessions(String token);
  Future<LiveSessionEntity?> fetchLiveSessionDetail(String sessionId, String token);
  Future<void> requestLiveSession(String token, String sessionId, String courseId);
  Future<void> joinLiveSession(String sessionId, String token);
  Future<List<LiveSessionRequestEntity>> fetchMySessionRequests(String token);
  Future<void> leaveLiveSession(String sessionId, String token);
  
  // Lecturer methods
  Future<List<LiveSessionEntity>> fetchMyLiveSessions(String token);
  Future<void> createLiveSession(String token, Map<String, dynamic> body);
  Future<void> scheduleLiveSession(String token, String sessionId, Map<String, dynamic> body);
  Future<List<LiveSessionRequestEntity>> fetchSessionRequests(String sessionId, String token);
  Future<void> acceptSessionRequest(String requestId, String token, {String? feedback});
  Future<void> rejectSessionRequest(String requestId, String token, String rejectionReason);
  Future<void> endLiveSession(String sessionId, String token);
  Future<void> recordAttendance(String sessionId, String token, List<String> attendeeIds);
  
  // Analytics methods
  Future<SessionAnalyticsEntity> fetchSessionAnalytics(String sessionId, String token);
  Future<List<SessionAnalyticsEntity>> fetchCourseSessionsAnalytics(String courseId, String token);
  Future<Map<String, dynamic>> fetchOverallAnalytics(String token);
  
  // Attendance tracking
  Future<List<AttendanceRecordEntity>> fetchSessionAttendance(String sessionId, String token);
  Future<void> markAttendance(String sessionId, String studentId, String token);
}

