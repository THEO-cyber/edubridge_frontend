import '../entities/review_entity.dart';

abstract class ReviewRepository {
  Future<List<ReviewEntity>> fetchReviews(String courseId);
  Future<ReviewEntity> postReview(
    String courseId,
    String review,
    int rating,
    String token,
  );
}
