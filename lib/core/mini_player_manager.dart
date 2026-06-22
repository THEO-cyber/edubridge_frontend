import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class MiniPlayerManager extends ChangeNotifier {
  static final MiniPlayerManager instance = MiniPlayerManager._();
  MiniPlayerManager._();

  VideoPlayerController? _vpc;
  Map<String, dynamic>? lesson;
  List<Map<String, dynamic>>? lessons;
  int currentIndex = 0;
  String courseTitle = '';
  String courseId = '';
  String? courseImageUrl;
  String token = '';
  String? enrollmentId;
  Set<String> completed = {};

  bool _active = false;

  bool get isActive => _active;
  VideoPlayerController? get vpc => _vpc;

  void show({
    required VideoPlayerController vpc,
    required Map<String, dynamic> lesson,
    required List<Map<String, dynamic>> lessons,
    required int currentIndex,
    required String courseTitle,
    required String courseId,
    required String token,
    String? courseImageUrl,
    String? enrollmentId,
    Set<String>? completed,
  }) {
    _vpc = vpc;
    this.lesson = lesson;
    this.lessons = lessons;
    this.currentIndex = currentIndex;
    this.courseTitle = courseTitle;
    this.courseId = courseId;
    this.token = token;
    this.courseImageUrl = courseImageUrl;
    this.enrollmentId = enrollmentId;
    this.completed = Set.from(completed ?? {});
    _active = true;
    notifyListeners();
  }

  /// Transfers controller ownership back to the caller (CoursePlayerScreen resuming).
  VideoPlayerController? takeController() {
    final c = _vpc;
    _vpc = null;
    _active = false;
    notifyListeners();
    return c;
  }

  void dismiss() {
    _vpc?.pause();
    _vpc?.dispose();
    _vpc = null;
    _active = false;
    notifyListeners();
  }
}
