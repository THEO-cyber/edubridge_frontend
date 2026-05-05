import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_data_source.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  CourseRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CourseEntity>> fetchCourses() async {
    final data = await remoteDataSource.fetchCourses();
    return data
        .map(
          (e) => CourseEntity(
            id: e['id'],
            title: e['title'],
            description: e['description'],
            instructorId: e['instructorId'],
            imageUrl: e['imageUrl'],
          ),
        )
        .toList();
  }

  @override
  Future<CourseEntity> fetchCourseById(String id) async {
    final e = await remoteDataSource.fetchCourseById(id);
    return CourseEntity(
      id: e['id'],
      title: e['title'],
      description: e['description'],
      instructorId: e['instructorId'],
      imageUrl: e['imageUrl'],
    );
  }
}
