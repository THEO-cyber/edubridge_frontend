class EnrollmentEntity {
  final String id;
  final String studentId;
  final String courseId;
  final DateTime enrolledAt;
  final double progressPercentage;
  final bool isCompleted;
  final DateTime? completedAt;

  EnrollmentEntity({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.enrolledAt,
    this.progressPercentage = 0.0,
    this.isCompleted = false,
    this.completedAt,
  });
}
