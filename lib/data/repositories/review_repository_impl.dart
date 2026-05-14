import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;
  ReviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ReviewEntity>> fetchReviews(String courseId) async {
    final data = await remoteDataSource.fetchReviews(courseId);
    return data
        .map(
          (e) => ReviewEntity(
            id: e['id'] ?? '',
            courseId: e['courseId'] ?? '',
            studentId: e['studentId'] ?? '',
            rating: (e['rating'] ?? 0).toDouble(),
            comment: e['comment'] ?? e['review'] ?? '',
            createdAt: DateTime.parse(
              e['createdAt'] ?? DateTime.now().toString(),
            ),
            studentName: e['studentName'],
            studentAvatar: e['studentAvatar'],
          ),
        )
        .toList();
  }

  @override
  Future<ReviewEntity> postReview(
    String courseId,
    String review,
    int rating,
    String token,
  ) async {
    final data = await remoteDataSource.postReview(
      courseId,
      review,
      rating,
      token,
    );
    return ReviewEntity(
      id: data['id'] ?? '',
      courseId: data['courseId'] ?? courseId,
      studentId: data['studentId'] ?? '',
      rating: (data['rating'] ?? rating).toDouble(),
      comment: data['comment'] ?? data['review'] ?? review,
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toString()),
      studentName: data['studentName'],
      studentAvatar: data['studentAvatar'],
    );
  }

  Future<void> deleteReview(String reviewId, String token) async {
    await remoteDataSource.deleteReview(reviewId, token);
  }

  Future<List<ReviewEntity>> fetchMyReviews(String token) async {
    final data = await remoteDataSource.fetchMyReviews(token);
    return data
        .map(
          (e) => ReviewEntity(
            id: e['id'] ?? '',
            courseId: e['courseId'] ?? '',
            studentId: e['studentId'] ?? '',
            rating: (e['rating'] ?? 0).toDouble(),
            comment: e['comment'] ?? e['review'] ?? '',
            createdAt: DateTime.parse(
              e['createdAt'] ?? DateTime.now().toString(),
            ),
            studentName: e['studentName'],
            studentAvatar: e['studentAvatar'],
          ),
        )
        .toList();
  }
}
