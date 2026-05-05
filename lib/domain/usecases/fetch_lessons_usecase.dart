import '../entities/lesson_entity.dart';
import '../repositories/lesson_repository.dart';

class FetchLessonsUseCase {
  final LessonRepository repository;
  FetchLessonsUseCase(this.repository);

  Future<List<LessonEntity>> call(String courseId, String token) {
    return repository.fetchLessonsForCourse(courseId, token);
  }
}
