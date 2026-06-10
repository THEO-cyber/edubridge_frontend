import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_data_source.dart';
import 'course_mapper.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  CourseRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CourseEntity>> fetchCourses() async {
    final data = await remoteDataSource.fetchCourses();
    return data.map(courseFromMap).toList();
  }

  @override
  Future<CourseEntity> fetchCourseById(String id) async {
    final e = await remoteDataSource.fetchCourseById(id);
    return courseFromMap(e);
  }

  Future<List<CourseEntity>> searchCourses(String query) async {
    final data = await remoteDataSource.searchCourses(query);
    return data.map(courseFromMap).toList();
  }

  Future<List<CourseEntity>> fetchCoursesByCategory(String category) async {
    final data = await remoteDataSource.fetchCoursesByCategory(category);
    return data.map(courseFromMap).toList();
  }

  Future<List<CourseEntity>> fetchTopRatedCourses() async {
    final data = await remoteDataSource.fetchTopRatedCourses();
    return data.map(courseFromMap).toList();
  }
}
