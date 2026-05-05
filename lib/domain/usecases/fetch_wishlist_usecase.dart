import '../repositories/wishlist_repository.dart';

class FetchWishlistUseCase {
  final WishlistRepository repository;
  FetchWishlistUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String token) {
    return repository.fetchWishlist(token);
  }
}
