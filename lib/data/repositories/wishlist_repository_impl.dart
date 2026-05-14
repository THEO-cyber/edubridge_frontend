import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_data_source.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;
  WishlistRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CourseEntity>> fetchWishlist(String token) async {
    final data = await remoteDataSource.fetchWishlist(token);
    return data
        .map(
          (e) => CourseEntity(
            id: e['id'] ?? '',
            title: e['title'] ?? 'Untitled',
            description: e['description'] ?? '',
            instructorId: e['instructorId'] ?? '',
            imageUrl: e['imageUrl'],
            instructorName: e['instructorName'],
            price: (e['price'] ?? 0).toDouble(),
            rating: (e['rating'] ?? 0).toDouble(),
            reviewCount: e['reviewCount'] ?? 0,
            studentCount: e['studentCount'] ?? 0,
            category: e['category'] ?? 'General',
            level: e['level'] ?? 'Beginner',
            duration: e['duration'],
            tags: List<String>.from(e['tags'] ?? []),
            isFree: e['price'] == null || e['price'] == 0,
            createdAt: DateTime.parse(
              e['createdAt'] ?? DateTime.now().toString(),
            ),
          ),
        )
        .toList();
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
