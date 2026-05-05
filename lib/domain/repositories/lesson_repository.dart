import '../entities/lesson_entity.dart';

abstract class LessonRepository {
  Future<List<LessonEntity>> fetchLessonsForCourse(
    String courseId,
    String token,
  );
}
