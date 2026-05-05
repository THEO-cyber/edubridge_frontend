class LiveSessionEntity {
  final String id;
  final String title;
  final String instructorId;
  final DateTime scheduledAt;
  final String? description;

  LiveSessionEntity({
    required this.id,
    required this.title,
    required this.instructorId,
    required this.scheduledAt,
    this.description,
  });
}
