import '../../domain/repositories/enrollment_repository.dart';
import '../datasources/enrollment_remote_data_source.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final EnrollmentRemoteDataSource remoteDataSource;
  EnrollmentRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> enrollInCourse(String courseId, String token) async {
    await remoteDataSource.enrollInCourse(courseId, token);
  }

  @override
  Future<void> unenrollFromCourse(String enrollmentId, String token) async {
    await remoteDataSource.unenrollFromCourse(enrollmentId, token);
  }
}
