class LiveSessionEntity {
  final String id;
  final String title;
  final String courseId;
  final String instructorId;
  final String instructorName;
  final DateTime scheduledAt;
  final DateTime? endAt;
  final String? description;
  final String status; // scheduled, ongoing, completed, cancelled
  final String? meetingUrl;
  final int maxStudents;
  final int currentParticipants;
  final bool isRecorded;
  final int durationMinutes;

  LiveSessionEntity({
    required this.id,
    required this.title,
    required this.courseId,
    required this.instructorId,
    required this.instructorName,
    required this.scheduledAt,
    this.endAt,
    this.description,
    this.status = 'scheduled',
    this.meetingUrl,
    this.maxStudents = 50,
    this.currentParticipants = 0,
    this.isRecorded = false,
    this.durationMinutes = 0,
  });
}

class LiveSessionRequestEntity {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String sessionId;
  final DateTime requestedAt;
  final String status; // pending, accepted, rejected
  final String? feedback;
  final String? rejectionReason;

  LiveSessionRequestEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.sessionId,
    required this.requestedAt,
    this.status = 'pending',
    this.feedback,
    this.rejectionReason,
  });
}

class AttendanceRecordEntity {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final int durationMinutes;
  final bool isPresent;

  AttendanceRecordEntity({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.joinedAt,
    this.leftAt,
    required this.durationMinutes,
    this.isPresent = true,
  });
}

class SessionAnalyticsEntity {
  final String sessionId;
  final String sessionTitle;
  final int totalStudentsEnrolled;
  final int totalRequestsReceived;
  final int totalAccepted;
  final int totalRejected;
  final int totalAttended;
  final double averageAttendancePercentage;
  final int totalDuration; // in minutes
  final List<String> feedbackNotes;
  final DateTime? sessionDate;

  SessionAnalyticsEntity({
    required this.sessionId,
    required this.sessionTitle,
    required this.totalStudentsEnrolled,
    required this.totalRequestsReceived,
    required this.totalAccepted,
    required this.totalRejected,
    required this.totalAttended,
    required this.averageAttendancePercentage,
    required this.totalDuration,
    this.feedbackNotes = const [],
    this.sessionDate,
  });
}
