import '../../domain/entities/enrollment_entity.dart';
import '../datasources/progress_remote_data_source.dart';

class ProgressRepositoryImpl {
  final ProgressRemoteDataSource remoteDataSource;
  ProgressRepositoryImpl(this.remoteDataSource);

  Future<void> saveLessonProgress(
    String lessonId,
    int watchedSeconds,
    int totalSeconds,
    bool completed,
    String token,
  ) =>
      remoteDataSource.saveLessonProgress(
          lessonId, watchedSeconds, totalSeconds, completed, token);

  Future<Map<String, dynamic>> fetchProgress(
          String courseId, String token) =>
      remoteDataSource.fetchProgress(courseId, token);

  Future<List<EnrollmentEntity>> fetchEnrolledCourses(String token) async {
    final data = await remoteDataSource.fetchEnrolledCourses(token);
    return data.map((e) {
      double pct = 0;
      final raw = e['progressPercentage'];
      if (raw is num) pct = raw.toDouble();
      if (raw is String) pct = double.tryParse(raw) ?? 0;
      return EnrollmentEntity(
        id: e['id'] ?? '',
        studentId: e['studentId'] ?? '',
        courseId: e['courseId'] ?? '',
        enrolledAt:
            DateTime.tryParse(e['enrolledAt']?.toString() ?? '') ??
                DateTime.now(),
        progressPercentage: pct,
        isCompleted: e['isCompleted'] == true,
        completedAt: e['completedAt'] != null
            ? DateTime.tryParse(e['completedAt'].toString())
            : null,
      );
    }).toList();
  }
}
