class CertificateEntity {
  final String id;
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String instructorName;
  final String issuedBy;
  final DateTime issuedAt;
  final String certificateUrl;
  final String certificateNumber;

  CertificateEntity({
    required this.id,
    required this.enrollmentId,
    required this.studentId,
    this.studentName = '',
    required this.courseId,
    required this.courseName,
    this.instructorName = '',
    this.issuedBy = 'EduBridge Academy',
    required this.issuedAt,
    required this.certificateUrl,
    required this.certificateNumber,
  });
}
