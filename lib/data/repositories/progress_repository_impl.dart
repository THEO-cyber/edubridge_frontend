import '../../domain/entities/progress_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_data_source.dart';
import '../../domain/entities/enrollment_entity.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDataSource remoteDataSource;

  ProgressRepositoryImpl(this.remoteDataSource);

  @override
  Future<ProgressEntity> fetchProgress(
    String enrollmentId,
    String token,
  ) async {
    final data = await remoteDataSource.fetchProgress(enrollmentId, token);
    return ProgressEntity(
      id: data['id'] ?? '',
      enrollmentId: data['enrollmentId'] ?? '',
      lessonId: data['lessonId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'])
          : null,
      watchedDuration: data['watchedDuration'] ?? 0,
      totalDuration: data['totalDuration'] ?? 0,
    );
  }

  @override
  Future<void> updateLessonProgress(
    String enrollmentId,
    String lessonId,
    int watchedDuration,
    String token,
  ) async {
    await remoteDataSource.updateLessonProgress(
      enrollmentId,
      lessonId,
      watchedDuration,
      token,
    );
  }

  @override
  Future<void> markLessonComplete(
    String enrollmentId,
    String lessonId,
    String token,
  ) async {
    await remoteDataSource.markLessonComplete(enrollmentId, lessonId, token);
  }

  @override
  Future<List<EnrollmentEntity>> fetchEnrolledCourses(String token) async {
    final data = await remoteDataSource.fetchEnrolledCourses(token);
    return data
        .map(
          (e) => EnrollmentEntity(
            id: e['id'] ?? '',
            studentId: e['studentId'] ?? '',
            courseId: e['courseId'] ?? '',
            enrolledAt: DateTime.parse(
              e['enrolledAt'] ?? DateTime.now().toString(),
            ),
            progressPercentage: (e['progressPercentage'] ?? 0).toDouble(),
            isCompleted: e['isCompleted'] ?? false,
            completedAt: e['completedAt'] != null
                ? DateTime.parse(e['completedAt'])
                : null,
          ),
        )
        .toList();
  }
}
