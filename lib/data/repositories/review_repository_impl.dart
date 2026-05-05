import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;
  ReviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Map<String, dynamic>>> fetchReviews(String courseId) async {
    return await remoteDataSource.fetchReviews(courseId);
  }

  @override
  Future<void> postReview(
    String courseId,
    String review,
    int rating,
    String token,
  ) async {
    await remoteDataSource.postReview(courseId, review, rating, token);
  }
}
