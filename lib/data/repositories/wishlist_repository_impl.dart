import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_data_source.dart';
import 'course_mapper.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;
  WishlistRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CourseEntity>> fetchWishlist(String token) async {
    final data = await remoteDataSource.fetchWishlist(token);
    return data.map(courseFromMap).toList();
  }

  @override
  Future<void> addToWishlist(String courseId, String token) async {
    await remoteDataSource.addToWishlist(courseId, token);
  }

  Future<void> removeFromWishlist(String courseId, String token) async {
    await remoteDataSource.removeFromWishlist(courseId, token);
  }

  Future<bool> isInWishlist(String courseId, String token) async {
    return await remoteDataSource.isInWishlist(courseId, token);
  }

  Future<void> clearWishlist(String token) async {
    await remoteDataSource.clearWishlist(token);
  }
}
