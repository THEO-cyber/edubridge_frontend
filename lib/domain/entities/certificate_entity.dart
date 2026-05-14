class CertificateEntity {
  final String id;
  final String enrollmentId;
  final String studentId;
  final String courseId;
  final String courseName;
  final DateTime issuedAt;
  final String certificateUrl;
  final String certificateNumber;

  CertificateEntity({
    required this.id,
    required this.enrollmentId,
    required this.studentId,
    required this.courseId,
    required this.courseName,
    required this.issuedAt,
    required this.certificateUrl,
    required this.certificateNumber,
  });
}
