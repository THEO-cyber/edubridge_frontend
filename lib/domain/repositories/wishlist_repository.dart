import '../entities/course_entity.dart';

abstract class WishlistRepository {
  Future<List<CourseEntity>> fetchWishlist(String token);
  Future<void> addToWishlist(String courseId, String token);
}
