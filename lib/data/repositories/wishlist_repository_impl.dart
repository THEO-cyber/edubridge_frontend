import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_data_source.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;
  WishlistRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Map<String, dynamic>>> fetchWishlist(String token) async {
    return await remoteDataSource.fetchWishlist(token);
  }

  @override
  Future<void> addToWishlist(String courseId, String token) async {
    await remoteDataSource.addToWishlist(courseId, token);
  }
}
