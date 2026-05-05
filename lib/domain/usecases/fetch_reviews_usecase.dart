import '../repositories/review_repository.dart';

class FetchReviewsUseCase {
  final ReviewRepository repository;
  FetchReviewsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String courseId) {
    return repository.fetchReviews(courseId);
  }
}
