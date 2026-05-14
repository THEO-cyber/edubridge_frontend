abstract class EnrollmentRepository {
  Future<void> enrollInCourse(String courseId, String token);
  Future<void> unenrollFromCourse(String enrollmentId, String token);
  Future<List<Map<String, dynamic>>> fetchEnrollments(String token);
}
