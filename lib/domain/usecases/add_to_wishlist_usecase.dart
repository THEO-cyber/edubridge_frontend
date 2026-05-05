import '../repositories/wishlist_repository.dart';

class AddToWishlistUseCase {
  final WishlistRepository repository;
  AddToWishlistUseCase(this.repository);

  Future<void> call(String courseId, String token) {
    return repository.addToWishlist(courseId, token);
  }
}
