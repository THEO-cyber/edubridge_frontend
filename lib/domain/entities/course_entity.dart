class CourseEntity {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final String? imageUrl;
  final String? instructorName;
  final double price;
  final double rating;
  final int reviewCount;
  final int studentCount;
  final String category;
  final String level;
  final String? duration; // in hours
  final List<String> tags;
  final bool isFree;
  final DateTime createdAt;

  CourseEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    this.imageUrl,
    this.instructorName,
    this.price = 0.0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.studentCount = 0,
    this.category = 'General',
    this.level = 'Beginner',
    this.duration,
    this.tags = const [],
    this.isFree = true,
    required this.createdAt,
  });
}
