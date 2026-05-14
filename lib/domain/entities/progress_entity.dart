class ProgressEntity {
  final String id;
  final String enrollmentId;
  final String lessonId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int watchedDuration; // in seconds
  final int totalDuration; // in seconds

  ProgressEntity({
    required this.id,
    required this.enrollmentId,
    required this.lessonId,
    this.isCompleted = false,
    this.completedAt,
    this.watchedDuration = 0,
    this.totalDuration = 0,
  });

  double get percentageWatched =>
      totalDuration > 0 ? (watchedDuration / totalDuration) * 100 : 0;
}
