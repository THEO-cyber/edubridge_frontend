class ReviewEntity {
  final String id;
  final String courseId;
  final String studentId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? studentName;
  final String? studentAvatar;

  ReviewEntity({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.studentName,
    this.studentAvatar,
  });
}
