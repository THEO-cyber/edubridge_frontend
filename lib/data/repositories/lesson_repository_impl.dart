import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/lesson_remote_data_source.dart';

class LessonRepositoryImpl implements LessonRepository {
  final LessonRemoteDataSource remoteDataSource;
  LessonRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<LessonEntity>> fetchLessonsForCourse(
    String courseId,
    String token,
  ) async {
    final data = await remoteDataSource.fetchLessonsForCourse(courseId, token);
    return data
        .map(
          (e) => LessonEntity(
            id: e['id'],
            title: e['title'],
            videoUrl: e['videoUrl'],
            description: e['description'],
          ),
        )
        .toList();
  }
}
