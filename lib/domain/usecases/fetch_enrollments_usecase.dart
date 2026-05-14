import '../repositories/enrollment_repository.dart';

class FetchEnrollmentsUseCase {
  final EnrollmentRepository repository;
  FetchEnrollmentsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String token) async {
    return await repository.fetchEnrollments(token);
  }
}
