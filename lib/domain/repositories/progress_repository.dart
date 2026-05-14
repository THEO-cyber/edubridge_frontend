import '../entities/progress_entity.dart';
import '../entities/enrollment_entity.dart';

abstract class ProgressRepository {
  Future<ProgressEntity> fetchProgress(String enrollmentId, String token);
  Future<void> updateLessonProgress(
    String enrollmentId,
    String lessonId,
    int watchedDuration,
    String token,
  );
  Future<void> markLessonComplete(
    String enrollmentId,
    String lessonId,
    String token,
  );
  Future<List<EnrollmentEntity>> fetchEnrolledCourses(String token);
}
