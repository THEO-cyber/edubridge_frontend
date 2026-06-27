class LessonEntity {
  final String id;
  final String title;
  final String videoUrl;      // legacy direct URL (fallback)
  final String? videoId;      // processed video ID from video-processing service
  final String? videoStatus;  // UPLOADED | PROCESSING | READY | FAILED
  final String? thumbnailUrl;
  final String? description;

  LessonEntity({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.videoId,
    this.videoStatus,
    this.thumbnailUrl,
    this.description,
  });

  bool get hasProcessedVideo =>
      videoId != null && videoId!.isNotEmpty;

  bool get isVideoReady =>
      hasProcessedVideo && videoStatus == 'READY';
}
