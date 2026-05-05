abstract class ReviewRepository {
  Future<List<Map<String, dynamic>>> fetchReviews(String courseId);
  Future<void> postReview(
    String courseId,
    String review,
    int rating,
    String token,
  );
}
