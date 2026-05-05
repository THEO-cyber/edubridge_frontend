import '../repositories/enrollment_repository.dart';

class EnrollInCourseUseCase {
  final EnrollmentRepository repository;
  EnrollInCourseUseCase(this.repository);

  Future<void> call(String courseId, String token) {
    return repository.enrollInCourse(courseId, token);
  }
}
