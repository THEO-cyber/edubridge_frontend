import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_data_source.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  CourseRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CourseEntity>> fetchCourses() async {
    final data = await remoteDataSource.fetchCourses();
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
  Future<CourseEntity> fetchCourseById(String id) async {
    final e = await remoteDataSource.fetchCourseById(id);
    return CourseEntity(
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
      createdAt: DateTime.parse(e['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Future<List<CourseEntity>> searchCourses(String query) async {
    final data = await remoteDataSource.searchCourses(query);
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

  Future<List<CourseEntity>> fetchCoursesByCategory(String category) async {
    final data = await remoteDataSource.fetchCoursesByCategory(category);
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

  Future<List<CourseEntity>> fetchTopRatedCourses() async {
    final data = await remoteDataSource.fetchTopRatedCourses();
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
}
