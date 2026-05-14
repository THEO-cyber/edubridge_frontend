import '../entities/course_entity.dart';
import '../repositories/wishlist_repository.dart';

class FetchWishlistUseCase {
  final WishlistRepository repository;
  FetchWishlistUseCase(this.repository);

  Future<List<CourseEntity>> call(String token) {
    return repository.fetchWishlist(token);
  }
}
