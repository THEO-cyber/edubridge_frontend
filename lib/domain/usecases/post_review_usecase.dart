import '../repositories/review_repository.dart';

class PostReviewUseCase {
  final ReviewRepository repository;
  PostReviewUseCase(this.repository);

  Future<void> call(String courseId, String review, int rating, String token) {
    return repository.postReview(courseId, review, rating, token);
  }
}
