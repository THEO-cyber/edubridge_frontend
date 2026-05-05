class CourseEntity {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final String? imageUrl;

  CourseEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    this.imageUrl,
  });
}
