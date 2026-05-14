import '../entities/review_entity.dart';
import '../repositories/review_repository.dart';

class FetchReviewsUseCase {
  final ReviewRepository repository;
  FetchReviewsUseCase(this.repository);

  Future<List<ReviewEntity>> call(String courseId) {
    return repository.fetchReviews(courseId);
  }
}
