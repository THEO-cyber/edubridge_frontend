import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<List<CourseEntity>> fetchCourses();
  Future<CourseEntity> fetchCourseById(String id);
}
