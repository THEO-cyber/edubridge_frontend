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
    return data.map((e) => _mapLesson(e)).toList();
  }

  LessonEntity _mapLesson(Map<String, dynamic> e) {
    return LessonEntity(
      id: (e['id'] ?? e['_id'] ?? '').toString(),
      title: (e['title'] ?? '').toString(),
      videoUrl: (e['videoUrl'] ?? '').toString(),
      videoId: e['videoId']?.toString(),
      videoStatus: e['videoStatus']?.toString(),
      thumbnailUrl: e['thumbnailUrl']?.toString(),
      description: e['description']?.toString(),
    );
  }
}
