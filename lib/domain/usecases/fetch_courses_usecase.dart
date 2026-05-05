import '../entities/course_entity.dart';
import '../repositories/course_repository.dart';

class FetchCoursesUseCase {
  final CourseRepository repository;
  FetchCoursesUseCase(this.repository);

  Future<List<CourseEntity>> call() {
    return repository.fetchCourses();
  }
}
