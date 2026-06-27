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
            courseId: e['courseId'] ?? '',
            instructorId: e['instructorId'],
            instructorName: e['instructorName'] ?? 'Instructor',
            scheduledAt: DateTime.parse(e['scheduledAt']),
            endAt: e['endAt'] != null ? DateTime.parse(e['endAt']) : null,
            description: e['description'],
            status: e['status'] ?? 'scheduled',
            meetingUrl: e['meetingUrl'],
            maxStudents: e['maxStudents'] ?? 50,
            currentParticipants: e['currentParticipants'] ?? 0,
            isRecorded: e['isRecorded'] ?? false,
          ),
        )
        .toList();
  }

  @override
  Future<LiveSessionEntity?> fetchLiveSessionDetail(String sessionId, String token) async {
    try {
      final data = await remoteDataSource.fetchLiveSessionDetail(sessionId, token);
      return LiveSessionEntity(
        id: data['id'],
        title: data['title'],
        courseId: data['courseId'] ?? '',
        instructorId: data['instructorId'],
        instructorName: data['instructorName'] ?? 'Instructor',
        scheduledAt: DateTime.parse(data['scheduledAt']),
        endAt: data['endAt'] != null ? DateTime.parse(data['endAt']) : null,
        description: data['description'],
        status: data['status'] ?? 'scheduled',
        meetingUrl: data['meetingUrl'],
        maxStudents: data['maxStudents'] ?? 50,
        currentParticipants: data['currentParticipants'] ?? 0,
        isRecorded: data['isRecorded'] ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> requestLiveSession(String token, String sessionId, String courseId) async {
    await remoteDataSource.requestLiveSession(token, sessionId, courseId);
  }

  @override
  Future<void> joinLiveSession(String sessionId, String token) async {
    await remoteDataSource.joinLiveSession(sessionId, token);
  }

  @override
  Future<List<LiveSessionRequestEntity>> fetchMySessionRequests(String token) async {
    final data = await remoteDataSource.fetchMySessionRequests(token);
    return data
        .map(
          (e) => LiveSessionRequestEntity(
            id: e['id'],
            studentId: e['studentId'],
            studentName: e['studentName'] ?? '',
            studentEmail: e['studentEmail'] ?? '',
            sessionId: e['sessionId'],
            requestedAt: DateTime.parse(e['requestedAt']),
            status: e['status'] ?? 'pending',
            feedback: e['feedback'],
            rejectionReason: e['rejectionReason'],
          ),
        )
        .toList();
  }

  @override
  Future<void> leaveLiveSession(String sessionId, String token) async {
    await remoteDataSource.leaveLiveSession(sessionId, token);
  }

  @override
  Future<List<LiveSessionEntity>> fetchMyLiveSessions(String token) async {
    final data = await remoteDataSource.fetchMyLiveSessions(token);
    return data
        .map(
          (e) => LiveSessionEntity(
            id: e['id'],
            title: e['title'],
            courseId: e['courseId'] ?? '',
            instructorId: e['instructorId'],
            instructorName: e['instructorName'] ?? 'Instructor',
            scheduledAt: DateTime.parse(e['scheduledAt']),
            endAt: e['endAt'] != null ? DateTime.parse(e['endAt']) : null,
            description: e['description'],
            status: e['status'] ?? 'scheduled',
            meetingUrl: e['meetingUrl'],
            maxStudents: e['maxStudents'] ?? 50,
            currentParticipants: e['currentParticipants'] ?? 0,
            isRecorded: e['isRecorded'] ?? false,
            durationMinutes: (e['duration'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<void> createLiveSession(String token, Map<String, dynamic> body) async {
    await remoteDataSource.createLiveSession(token, body);
  }

  @override
  Future<void> scheduleLiveSession(String token, String sessionId, Map<String, dynamic> body) async {
    await remoteDataSource.scheduleLiveSession(token, sessionId, body);
  }

  @override
  Future<List<LiveSessionRequestEntity>> fetchSessionRequests(String sessionId, String token) async {
    final data = await remoteDataSource.fetchSessionRequests(sessionId, token);
    return data
        .map(
          (e) => LiveSessionRequestEntity(
            id: e['id'],
            studentId: e['studentId'],
            studentName: e['studentName'] ?? '',
            studentEmail: e['studentEmail'] ?? '',
            sessionId: e['sessionId'],
            requestedAt: DateTime.parse(e['requestedAt']),
            status: e['status'] ?? 'pending',
            feedback: e['feedback'],
            rejectionReason: e['rejectionReason'],
          ),
        )
        .toList();
  }

  @override
  Future<void> acceptSessionRequest(String requestId, String token, {String? feedback}) async {
    await remoteDataSource.acceptSessionRequest(requestId, token, feedback: feedback);
  }

  @override
  Future<void> rejectSessionRequest(String requestId, String token, String rejectionReason) async {
    await remoteDataSource.rejectSessionRequest(requestId, token, rejectionReason);
  }

  @override
  Future<void> endLiveSession(String sessionId, String token) async {
    await remoteDataSource.endLiveSession(sessionId, token);
  }

  @override
  Future<void> recordAttendance(String sessionId, String token, List<String> attendeeIds) async {
    await remoteDataSource.recordAttendance(sessionId, token, attendeeIds);
  }

  @override
  Future<SessionAnalyticsEntity> fetchSessionAnalytics(String sessionId, String token) async {
    final data = await remoteDataSource.fetchSessionAnalytics(sessionId, token);
    return SessionAnalyticsEntity(
      sessionId: data['sessionId'] ?? sessionId,
      sessionTitle: data['sessionTitle'] ?? '',
      totalStudentsEnrolled: data['totalStudentsEnrolled'] ?? 0,
      totalRequestsReceived: data['totalRequestsReceived'] ?? 0,
      totalAccepted: data['totalAccepted'] ?? 0,
      totalRejected: data['totalRejected'] ?? 0,
      totalAttended: data['totalAttended'] ?? 0,
      averageAttendancePercentage: (data['averageAttendancePercentage'] ?? 0).toDouble(),
      totalDuration: data['totalDuration'] ?? 0,
      feedbackNotes: List<String>.from(data['feedbackNotes'] ?? []),
      sessionDate: data['sessionDate'] != null ? DateTime.parse(data['sessionDate']) : null,
    );
  }

  @override
  Future<List<SessionAnalyticsEntity>> fetchCourseSessionsAnalytics(String courseId, String token) async {
    final data = await remoteDataSource.fetchCourseSessionsAnalytics(courseId, token);
    return data
        .map(
          (e) => SessionAnalyticsEntity(
            sessionId: e['sessionId'],
            sessionTitle: e['sessionTitle'] ?? '',
            totalStudentsEnrolled: e['totalStudentsEnrolled'] ?? 0,
            totalRequestsReceived: e['totalRequestsReceived'] ?? 0,
            totalAccepted: e['totalAccepted'] ?? 0,
            totalRejected: e['totalRejected'] ?? 0,
            totalAttended: e['totalAttended'] ?? 0,
            averageAttendancePercentage: (e['averageAttendancePercentage'] ?? 0).toDouble(),
            totalDuration: e['totalDuration'] ?? 0,
            feedbackNotes: List<String>.from(e['feedbackNotes'] ?? []),
            sessionDate: e['sessionDate'] != null ? DateTime.parse(e['sessionDate']) : null,
          ),
        )
        .toList();
  }

  @override
  Future<Map<String, dynamic>> fetchOverallAnalytics(String token) async {
    return await remoteDataSource.fetchOverallAnalytics(token);
  }

  @override
  Future<List<AttendanceRecordEntity>> fetchSessionAttendance(String sessionId, String token) async {
    final data = await remoteDataSource.fetchSessionAttendance(sessionId, token);
    return data
        .map(
          (e) => AttendanceRecordEntity(
            id: e['id'],
            sessionId: e['sessionId'],
            studentId: e['studentId'],
            studentName: e['studentName'] ?? '',
            joinedAt: DateTime.parse(e['joinedAt']),
            leftAt: e['leftAt'] != null ? DateTime.parse(e['leftAt']) : null,
            durationMinutes: e['durationMinutes'] ?? 0,
            isPresent: e['isPresent'] ?? true,
          ),
        )
        .toList();
  }

  @override
  Future<void> markAttendance(String sessionId, String studentId, String token) async {
    await remoteDataSource.markAttendance(sessionId, studentId, token);
  }
}
