class LessonEntity {
  final String id;
  final String title;
  final String videoUrl;
  final String? description;

  LessonEntity({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.description,
  });
}
