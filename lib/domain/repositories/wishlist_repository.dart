abstract class WishlistRepository {
  Future<List<Map<String, dynamic>>> fetchWishlist(String token);
  Future<void> addToWishlist(String courseId, String token);
}
