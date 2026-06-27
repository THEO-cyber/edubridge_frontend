import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../../constants/api_constants.dart';
import '../../core/mini_player_manager.dart';
import '../blocs/certificate_bloc_provider.dart';
import 'certificate_screen_enhanced.dart';

const _kNavy = Color(0xFF1A237E);
const _kAccent = Color(0xFF3F51B5);
const _kDark = Color(0xFF0D0D1A);
const _kGreen = Color(0xFF2E7D32);

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — wraps with ProgressBloc
// ─────────────────────────────────────────────────────────────────────────────

class CoursePlayerScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;
  final String? courseImageUrl;
  final List<Map<String, dynamic>> lessons;
  final int startLessonIndex;
  final String? enrollmentId;
  final String token;
  final Set<String> completedLessonIds;
  final VideoPlayerController? existingController;

  const CoursePlayerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.courseImageUrl,
    required this.lessons,
    required this.startLessonIndex,
    required this.enrollmentId,
    required this.token,
    required this.completedLessonIds,
    this.existingController,
  });

  @override
  Widget build(BuildContext context) => _CoursePlayerBody(
        courseId: courseId,
        courseTitle: courseTitle,
        courseImageUrl: courseImageUrl,
        lessons: lessons,
        startLessonIndex: startLessonIndex,
        enrollmentId: enrollmentId,
        token: token,
        completedLessonIds: completedLessonIds,
        existingController: existingController,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _CoursePlayerBody extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String? courseImageUrl;
  final List<Map<String, dynamic>> lessons;
  final int startLessonIndex;
  final String? enrollmentId;
  final String token;
  final Set<String> completedLessonIds;
  final VideoPlayerController? existingController;

  const _CoursePlayerBody({
    required this.courseId,
    required this.courseTitle,
    this.courseImageUrl,
    required this.lessons,
    required this.startLessonIndex,
    required this.enrollmentId,
    required this.token,
    required this.completedLessonIds,
    this.existingController,
  });

  @override
  State<_CoursePlayerBody> createState() => _CoursePlayerBodyState();
}

class _CoursePlayerBodyState extends State<_CoursePlayerBody>
    with SingleTickerProviderStateMixin {
  static final _pipChannel = MethodChannel('com.edubridge/pip');

  // ── video
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  Timer? _progressTimer;
  bool _initializing = false;
  bool _videoError = false;
  String? _videoErrorMsg;
  String _quality = '720p';
  static const _qualities = ['720p', '480p', '360p'];

  // ── lesson navigation
  late int _currentIndex;
  late Set<String> _completed;
  bool _courseCompleteShown = false;

  // ── tab + section
  late TabController _tabCtrl;
  final Set<String> _expanded = {};

  // ── notes
  String? _notesLessonId;
  List<Map<String, dynamic>> _notes = [];
  bool _notesLoading = false;
  bool _notesSaving = false;
  final _noteCtrl = TextEditingController();

  Map<String, dynamic> get _lesson => widget.lessons[_currentIndex];
  bool get _hasVideo => (_lesson['videoId']?.toString() ?? '').isNotEmpty;
  String get _videoStatus => _lesson['videoStatus']?.toString() ?? '';
  bool get _isReady =>
      _hasVideo && (_videoStatus == 'READY' || _videoStatus == 'APPROVED');
  bool get _isCurrentDone =>
      _completed.contains(_lesson['id']?.toString() ?? '');
  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.lessons.length - 1;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.startLessonIndex.clamp(0, widget.lessons.length - 1);
    _completed = Set<String>.from(widget.completedLessonIds);
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _autoExpandCurrentSection();

    if (widget.existingController != null) {
      _vpc = widget.existingController;
      _vpc!.addListener(_onTick);
      _rebuildChewie();
      _startProgressTimer();
    } else if (_isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    if (_vpc != null) _flushProgress(fromDispose: true);
    _disposePlayer();
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging && _tabCtrl.index == 2) _fetchNotes();
  }

  // ── Player ────────────────────────────────────────────────────────────────

  Future<String> _resolveStreamUrl(String streamUrl) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(streamUrl));
      req.followRedirects = false;
      req.headers.add('Authorization', 'Bearer ${widget.token}');
      final resp = await req.close();
      client.close();
      if (resp.statusCode == 302 || resp.statusCode == 301) {
        final loc = resp.headers.value('location');
        if (loc != null && loc.isNotEmpty) return loc;
      }
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final u = json['url'] ?? json['streamUrl'] ?? json['playbackUrl'];
          if (u != null) return u.toString();
        } catch (_) {}
      }
    } catch (_) {}
    return streamUrl;
  }

  Future<void> _initPlayer({String? quality}) async {
    _progressTimer?.cancel();
    _disposePlayer();
    if (!mounted) return;
    setState(() {
      _initializing = true;
      _videoError = false;
      _videoErrorMsg = null;
    });

    try {
      final String url;
      final Map<String, String> headers;

      if (_isReady) {
        final streamUrl =
            '${ApiConstants.baseUrl}${ApiConstants.videoStream(_lesson['videoId'].toString())}?quality=${quality ?? _quality}';
        url = await _resolveStreamUrl(streamUrl);
        headers = {};
      } else if (!_hasVideo &&
          (_lesson['videoUrl']?.toString() ?? '').trim().isNotEmpty) {
        url = _lesson['videoUrl'].toString().trim();
        headers = {
          'Authorization': 'Bearer ${widget.token}',
          'Range': 'bytes=0-'
        };
      } else {
        if (mounted) setState(() => _initializing = false);
        return;
      }

      _vpc = VideoPlayerController.networkUrl(Uri.parse(url),
          httpHeaders: headers);
      await _vpc!.initialize();
      _vpc!.addListener(_onTick);
      _rebuildChewie();
      _startProgressTimer();

      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _videoError = true;
          _videoErrorMsg = e.toString();
        });
      }
    }
  }

  void _rebuildChewie() {
    _chewie?.dispose();
    final thumb = (_lesson['thumbnailUrl']?.toString() ?? '').isNotEmpty
        ? _lesson['thumbnailUrl'].toString()
        : (widget.courseImageUrl ?? '');
    _chewie = ChewieController(
      videoPlayerController: _vpc!,
      aspectRatio: 16 / 9,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      placeholder: thumb.isNotEmpty
          ? Image.network(thumb,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _videoBg())
          : _videoBg(),
    );
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_vpc?.value.isPlaying == true) _autoSave();
    });
  }

  void _onTick() {
    if (_vpc == null) return;
    final pos = _vpc!.value.position;
    final dur = _vpc!.value.duration;
    if (dur.inSeconds > 0 && pos >= dur && !_isCurrentDone) {
      _markComplete();
    }
  }

  void _disposePlayer() {
    _vpc?.removeListener(_onTick);
    _chewie?.dispose();
    _chewie = null;
    _vpc?.dispose();
    _vpc = null;
  }

  Future<void> _postProgress(String lessonId,
      {required int watchTime, required bool isCompleted}) async {
    try {
      await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.lessonProgress(lessonId)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'watchTime': watchTime,
          'isCompleted': isCompleted,
        }),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {}
  }

  void _autoSave() {
    if (_vpc == null) return;
    final pos = _vpc!.value.position.inSeconds;
    final dur = _vpc!.value.duration.inSeconds;
    if (dur <= 0) return;
    _postProgress(_lesson['id'].toString(),
        watchTime: pos, isCompleted: _isCurrentDone);
  }

  void _flushProgress({bool fromDispose = false}) {
    if (_vpc == null) return;
    final pos = _vpc!.value.position.inSeconds;
    if (pos <= 0) return;
    final lid = _lesson['id']?.toString() ?? '';
    if (lid.isEmpty) return;
    _postProgress(lid, watchTime: pos, isCompleted: _isCurrentDone);
  }

  Future<void> _markComplete() async {
    final lid = _lesson['id']?.toString() ?? '';
    if (lid.isEmpty || _completed.contains(lid)) return;
    setState(() => _completed.add(lid));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Lesson complete!',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    }

    // Post to backend and read courseProgress response
    final dur = _vpc?.value.duration.inSeconds ?? 1;
    try {
      final res = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.lessonProgress(lid)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'watchTime': dur, 'isCompleted': true}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final cp = (body['courseProgress'] ?? body) as Map<String, dynamic>;
        final status = cp['status']?.toString() ?? '';
        final certId = cp['certificate']?['id']?.toString() ?? '';
        final pct = _toDouble(
            cp['progressPercentage'] ?? cp['progress'] ?? 0);

        // Update local completion set from server response if available
        if (!mounted) return;
        if (status == 'COMPLETED' || pct >= 100) {
          if (!_courseCompleteShown) {
            _courseCompleteShown = true;
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) _showCourseCompleteDialog(certId: certId);
            });
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback local count check
    _checkCourseCompletion();

    if (_hasNext) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _jumpTo(_currentIndex + 1);
      });
    }
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  void _checkCourseCompletion() {
    if (_courseCompleteShown) return;
    if (_completed.length < widget.lessons.length) return;
    _courseCompleteShown = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showCourseCompleteDialog();
    });
  }

  void _showCourseCompleteDialog({String certId = ''}) {
    if (certId.isEmpty) _generateCertificate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Course Complete!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                widget.courseTitle,
                style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Your certificate has been generated.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CertificateBlocProvider(
                        child:
                            CertificateScreenEnhanced(token: widget.token),
                      ),
                    ));
                  },
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('View Certificate',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep Learning',
                    style: TextStyle(color: Colors.blueGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateCertificate() async {
    try {
      await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.certificateForCourse(widget.courseId)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'courseId': widget.courseId}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Certificate may already exist or endpoint is GET — silently ignore
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _jumpTo(int index) {
    if (index < 0 || index >= widget.lessons.length) return;
    _progressTimer?.cancel();
    _flushProgress();
    _disposePlayer();
    setState(() {
      _currentIndex = index;
      _videoError = false;
      _notesLessonId = null; // reset notes for new lesson
    });
    _autoExpandCurrentSection();
    if (_isReady) _initPlayer();
    if (_tabCtrl.index == 2) _fetchNotes();
  }

  void _autoExpandCurrentSection() {
    final sid = _lesson['_sectionId']?.toString() ?? '';
    if (sid.isNotEmpty) _expanded.add(sid);
  }

  // ── Minimize / PiP ────────────────────────────────────────────────────────

  void _minimize() {
    _progressTimer?.cancel();
    _flushProgress();

    if (_vpc != null) {
      final vpcToTransfer = _vpc!;
      vpcToTransfer.pause();
      _chewie?.dispose();
      _chewie = null;
      _vpc = null;

      MiniPlayerManager.instance.show(
        vpc: vpcToTransfer,
        lesson: _lesson,
        lessons: widget.lessons,
        currentIndex: _currentIndex,
        courseTitle: widget.courseTitle,
        courseId: widget.courseId,
        token: widget.token,
        courseImageUrl: widget.courseImageUrl,
        enrollmentId: widget.enrollmentId,
        completed: _completed,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _enterPip() async {
    try {
      await _pipChannel.invokeMethod('enterPipMode');
    } catch (_) {}
  }

  void _switchQuality(String q) {
    if (q == _quality) return;
    setState(() => _quality = q);
    _initPlayer(quality: q);
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<void> _fetchNotes() async {
    final lid = _lesson['id']?.toString() ?? '';
    if (lid.isEmpty || _notesLessonId == lid) return;
    if (mounted) setState(() => _notesLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.notesForLesson(lid)}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final list = body is List
            ? body
            : (body['notes'] ?? body['data'] ?? []);
        final parsed = (list as List)
            .map((n) => Map<String, dynamic>.from(n is Map ? n : {}))
            .toList()
          ..sort((a, b) {
            final at = (a['timestamp'] ?? 0) is num
                ? (a['timestamp'] as num).toInt()
                : 0;
            final bt = (b['timestamp'] ?? 0) is num
                ? (b['timestamp'] as num).toInt()
                : 0;
            return at.compareTo(bt);
          });
        setState(() {
          _notes = parsed;
          _notesLessonId = lid;
          _notesLoading = false;
        });
      } else if (mounted) {
        setState(() => _notesLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _notesLoading = false);
    }
  }

  Future<void> _addNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty || _notesSaving) return;
    final lid = _lesson['id']?.toString() ?? '';
    final timestamp = _vpc?.value.position.inSeconds ?? 0;
    if (mounted) setState(() => _notesSaving = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notes}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'lessonId': lid,
          'courseId': widget.courseId,
          'content': text,
          'timestamp': timestamp,
        }),
      ).timeout(const Duration(seconds: 12));
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        _noteCtrl.clear();
        FocusScope.of(context).unfocus();
        _notesLessonId = null;
        await _fetchNotes();
      }
    } catch (_) {}
    if (mounted) setState(() => _notesSaving = false);
  }

  Future<void> _deleteNote(String noteId) async {
    setState(() =>
        _notes.removeWhere((n) => n['id']?.toString() == noteId));
    try {
      await http.delete(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.noteById(noteId)}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 12));
    } catch (_) {}
  }

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimize();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildVideoArea(),
            _buildNavBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildCourseContentTab(),
                  _buildOverviewTab(),
                  _buildNotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kDark,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.picture_in_picture_alt, size: 22),
        tooltip: 'Minimize',
        onPressed: _minimize,
      ),
      titleSpacing: 4,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.courseTitle,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.normal),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            _lesson['title']?.toString() ?? '',
            style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_in_picture_alt, size: 20),
          tooltip: 'System PiP',
          onPressed: _enterPip,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.hd_rounded, size: 20, color: Colors.white70),
          tooltip: 'Quality',
          color: const Color(0xFF1A1A2E),
          onSelected: _switchQuality,
          itemBuilder: (_) => _qualities
              .map((q) => PopupMenuItem<String>(
                    value: q,
                    child: Row(children: [
                      Icon(
                        _quality == q
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 16,
                        color:
                            _quality == q ? _kAccent : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(q,
                          style: TextStyle(
                              color: _quality == q
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 14)),
                    ]),
                  ))
              .toList(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Video area ────────────────────────────────────────────────────────────

  Widget _buildVideoArea() {
    Widget videoWidget;
    final st = _videoStatus;

    if (_hasVideo && (st == 'PROCESSING' || st == 'UPLOADED')) {
      videoWidget = _videoPlaceholder(
          Icons.hourglass_top_rounded, 'Video is being processed…',
          sub: 'Check back shortly');
    } else if (!_isReady &&
        (_lesson['videoUrl']?.toString() ?? '').trim().isEmpty) {
      videoWidget =
          _videoPlaceholder(Icons.videocam_off_outlined, 'No video available');
    } else if (_videoError) {
      videoWidget = _videoPlaceholder(
          Icons.error_outline_rounded, 'Could not load video',
          sub: _videoErrorMsg, retry: true);
    } else if (_initializing) {
      videoWidget = _loadingOverlay();
    } else if (_chewie != null) {
      videoWidget = Chewie(controller: _chewie!);
    } else {
      videoWidget = _thumbnailPlay();
    }

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(aspectRatio: 16 / 9, child: videoWidget),
    );
  }

  Widget _thumbnailPlay() {
    final thumb = (_lesson['thumbnailUrl']?.toString() ?? '').isNotEmpty
        ? _lesson['thumbnailUrl'].toString()
        : (widget.courseImageUrl ?? '');
    return GestureDetector(
      onTap: _initPlayer,
      child: Stack(fit: StackFit.expand, children: [
        thumb.isNotEmpty
            ? Image.network(thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _videoBg())
            : _videoBg(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.5)
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2)
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: _kNavy, size: 48),
          ),
        ),
      ]),
    );
  }

  Widget _loadingOverlay() {
    final thumb = (_lesson['thumbnailUrl']?.toString() ?? '').isNotEmpty
        ? _lesson['thumbnailUrl'].toString()
        : (widget.courseImageUrl ?? '');
    return Stack(fit: StackFit.expand, children: [
      thumb.isNotEmpty
          ? Image.network(thumb,
              fit: BoxFit.cover, errorBuilder: (_, __, ___) => _videoBg())
          : _videoBg(),
      Container(color: Colors.black.withValues(alpha: 0.6)),
      const Center(
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5)),
    ]);
  }

  Widget _videoPlaceholder(IconData icon, String msg,
      {String? sub, bool retry = false}) {
    return Container(
      color: _kDark,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          if (sub != null && sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center),
          ],
          if (retry) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() => _videoError = false);
                _initPlayer();
              },
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white70, size: 18),
              label:
                  const Text('Retry', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _videoBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF0D0D1A), Color(0xFF1A237E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: const Center(
            child: Icon(Icons.play_lesson_rounded,
                color: Colors.white10, size: 72)),
      );

  // ── Nav bar ───────────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    final doneCount = _completed.length;
    final total = widget.lessons.length;
    final pct = total > 0 ? doneCount / total : 0.0;

    return Container(
      color: const Color(0xFF12122A),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(children: [
        _navBtn(
            icon: Icons.skip_previous_rounded,
            label: 'Prev',
            enabled: _hasPrev,
            onTap: () => _jumpTo(_currentIndex - 1)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Lesson ${_currentIndex + 1} of $total',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$doneCount/$total complete · ${(pct * 100).round()}%',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (!_isCurrentDone) ...[
          _navBtn(
              icon: Icons.check_circle_outline_rounded,
              label: 'Done',
              enabled: true,
              onTap: _markComplete,
              color: const Color(0xFF69F0AE)),
          const SizedBox(width: 8),
        ],
        _navBtn(
            icon: Icons.skip_next_rounded,
            label: 'Next',
            enabled: _hasNext,
            onTap: () => _jumpTo(_currentIndex + 1)),
      ]),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: enabled ? color : Colors.white24, size: 26),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: enabled ? color : Colors.white24,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  // ── TabBar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelColor: _kNavy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kAccent,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          tabs: const [
            Tab(text: 'Content'),
            Tab(text: 'Overview'),
            Tab(text: 'Notes'),
          ],
        ),
      );

  // ── Course Content tab ────────────────────────────────────────────────────

  Widget _buildCourseContentTab() {
    final sectionOrder = <String>[];
    final sectionTitles = <String, String>{};
    final bySection = <String, List<int>>{};

    for (int i = 0; i < widget.lessons.length; i++) {
      final l = widget.lessons[i];
      final sid = l['_sectionId']?.toString() ?? '';
      final stitle = l['_sectionTitle']?.toString() ?? '';
      if (!sectionOrder.contains(sid)) {
        sectionOrder.add(sid);
        sectionTitles[sid] = stitle;
      }
      bySection.putIfAbsent(sid, () => []).add(i);
    }

    final doneCount = _completed.length;
    final total = widget.lessons.length;
    final pct = total > 0 ? doneCount / total : 0.0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Completion banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.school_rounded, color: Colors.white70, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${(pct * 100).round()}% complete',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF69F0AE)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$doneCount of $total lessons completed',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ]),
        ),

        ...sectionOrder.asMap().entries.map((entry) {
          final idx = entry.key;
          final sid = entry.value;
          final title = sectionTitles[sid] ?? 'Section ${idx + 1}';
          final indices = bySection[sid] ?? [];
          final isOpen = _expanded.contains(sid);
          final doneCnt = indices
              .where((i) => _completed
                  .contains(widget.lessons[i]['id']?.toString() ?? ''))
              .length;
          final sectionPct =
              indices.isEmpty ? 0.0 : doneCnt / indices.length;

          return Column(
            children: [
              InkWell(
                onTap: () => setState(() =>
                    isOpen ? _expanded.remove(sid) : _expanded.add(sid)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  color: const Color(0xFFF5F6FC),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: sectionPct == 1.0
                                ? const Color(0xFF2E7D32)
                                : _kNavy.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: sectionPct == 1.0
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : Text('${idx + 1}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _kNavy)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _kNavy)),
                        ),
                        Text('$doneCnt/${indices.length}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.blueGrey)),
                        const SizedBox(width: 6),
                        Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: _kNavy,
                            size: 22),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: sectionPct,
                          minHeight: 3,
                          backgroundColor: Colors.blueGrey.shade100,
                          valueColor: AlwaysStoppedAnimation(
                              sectionPct == 1.0 ? _kGreen : _kAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOpen) ...indices.map((li) => _buildLessonTile(li)),
              const Divider(height: 1, color: Color(0xFFE8EAF6)),
            ],
          );
        }),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildLessonTile(int lessonIdx) {
    final l = widget.lessons[lessonIdx];
    final lid = l['id']?.toString() ?? '';
    final done = _completed.contains(lid);
    final isCurrent = lessonIdx == _currentIndex;
    final hasVid = (l['videoId']?.toString() ?? '').isNotEmpty;
    final status = l['videoStatus']?.toString() ?? '';
    final isProcessing =
        hasVid && (status == 'PROCESSING' || status == 'UPLOADED');
    final playable =
        (hasVid && (status == 'READY' || status == 'APPROVED')) ||
            (l['videoUrl']?.toString() ?? '').trim().isNotEmpty;

    int? durMin;
    final dur = l['durationMinutes'];
    if (dur is int) durMin = dur;
    if (dur is num) durMin = dur.toInt();
    if (dur is String) durMin = int.tryParse(dur);

    return InkWell(
      onTap: playable ? () => _jumpTo(lessonIdx) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFFEEF2FF)
              : done
                  ? const Color(0xFFF8FFF8)
                  : Colors.white,
          border: Border(
            left: BorderSide(
              color: isCurrent
                  ? _kAccent
                  : done
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
              width: 3,
            ),
            bottom: const BorderSide(color: Color(0xFFF0F0F0)),
          ),
        ),
        child: Row(children: [
          SizedBox(
            width: 36,
            height: 36,
            child: done
                ? CircleAvatar(
                    backgroundColor:
                        const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    child: const Icon(Icons.check_rounded,
                        color: Color(0xFF2E7D32), size: 18))
                : isCurrent
                    ? const CircleAvatar(
                        backgroundColor: _kAccent,
                        child: Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 20))
                    : isProcessing
                        ? CircleAvatar(
                            backgroundColor:
                                Colors.orange.withValues(alpha: 0.12),
                            child: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.orange)))
                        : CircleAvatar(
                            backgroundColor: const Color(0xFFEEF0FB),
                            child: Text('${lessonIdx + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: playable
                                        ? _kNavy
                                        : Colors.grey))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l['title']?.toString() ?? 'Lesson ${lessonIdx + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent
                        ? _kNavy
                        : done
                            ? Colors.black54
                            : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(
                    isProcessing
                        ? Icons.hourglass_empty_rounded
                        : playable
                            ? Icons.play_circle_outline_rounded
                            : Icons.lock_outline_rounded,
                    size: 12,
                    color: isProcessing
                        ? Colors.orange
                        : playable
                            ? Colors.blueGrey
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isProcessing
                        ? 'Processing…'
                        : durMin != null && durMin > 0
                            ? '$durMin min'
                            : playable
                                ? 'Video'
                                : 'Not available',
                    style: TextStyle(
                        fontSize: 11,
                        color: isProcessing
                            ? Colors.orange
                            : Colors.blueGrey),
                  ),
                ]),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Now Playing',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          else if (done)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF4CAF50), size: 18)
          else
            Icon(
              playable
                  ? Icons.chevron_right_rounded
                  : Icons.lock_outline_rounded,
              color: playable ? Colors.blueGrey : Colors.grey.shade300,
              size: 18,
            ),
        ]),
      ),
    );
  }

  // ── Overview tab ──────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final desc = _lesson['description']?.toString() ?? '';
    final sectionTitle = _lesson['_sectionTitle']?.toString() ?? '';

    int? durMin;
    final dur = _lesson['durationMinutes'];
    if (dur is int) durMin = dur;
    if (dur is num) durMin = dur.toInt();
    if (dur is String) durMin = int.tryParse(dur);

    final nextLesson =
        _hasNext ? widget.lessons[_currentIndex + 1] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.fiber_manual_record_rounded,
                  color: _kAccent, size: 10),
              const SizedBox(width: 5),
              Text('Now Playing',
                  style: TextStyle(
                      fontSize: 11,
                      color: _kAccent,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),
          Text(
            _lesson['title']?.toString() ?? '',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (sectionTitle.isNotEmpty)
                _chip(Icons.folder_outlined, sectionTitle),
              if (durMin != null && durMin > 0)
                _chip(Icons.timer_outlined, '$durMin min'),
              _chip(
                _isCurrentDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                _isCurrentDone ? 'Completed' : 'In progress',
                color: _isCurrentDone ? _kGreen : Colors.blueGrey,
              ),
              _chip(Icons.format_list_numbered_rounded,
                  'Lesson ${_currentIndex + 1} of ${widget.lessons.length}'),
            ],
          ),
          const SizedBox(height: 24),
          if (desc.isNotEmpty) ...[
            const _SectionHeader(title: 'About this lesson'),
            const SizedBox(height: 10),
            Text(desc,
                style: const TextStyle(
                    fontSize: 14, height: 1.7, color: Colors.black87)),
            const SizedBox(height: 28),
          ],
          if (nextLesson != null) ...[
            const _SectionHeader(title: 'Up Next'),
            const SizedBox(height: 10),
            _buildUpNextCard(nextLesson),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? Colors.blueGrey).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (color ?? Colors.blueGrey).withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color ?? Colors.blueGrey),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color ?? Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildUpNextCard(Map<String, dynamic> next) {
    final hasVid = (next['videoId']?.toString() ?? '').isNotEmpty;
    final status = next['videoStatus']?.toString() ?? '';
    final playable =
        (hasVid && (status == 'READY' || status == 'APPROVED')) ||
            (next['videoUrl']?.toString() ?? '').trim().isNotEmpty;
    final nextIdx = _currentIndex + 1;

    int? durMin;
    final dur = next['durationMinutes'];
    if (dur is int) durMin = dur;
    if (dur is num) durMin = dur.toInt();
    if (dur is String) durMin = int.tryParse(dur);

    return GestureDetector(
      onTap: playable ? () => _jumpTo(nextIdx) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E3F0)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFAFBFF),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              playable
                  ? Icons.play_arrow_rounded
                  : Icons.lock_outline_rounded,
              color: playable ? _kNavy : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next['title']?.toString() ?? 'Lesson ${nextIdx + 1}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (durMin != null && durMin > 0) ...[
                  const SizedBox(height: 3),
                  Text('$durMin min',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.blueGrey)),
                ],
              ],
            ),
          ),
          if (playable)
            const Icon(Icons.chevron_right_rounded,
                color: Colors.blueGrey, size: 20),
        ]),
      ),
    );
  }

  // ── Notes tab ─────────────────────────────────────────────────────────────

  Widget _buildNotesTab() {
    return Column(children: [
      // Input area
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          boxShadow: [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp indicator
            _NoteTimestampChip(vpc: _vpc),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'Write a note about this point in the lesson…',
                      hintStyle: const TextStyle(
                          color: Colors.grey, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kAccent),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addNote,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _notesSaving ? Colors.grey : _kNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _notesSaving
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Notes list
      Expanded(
        child: _notesLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kNavy))
            : _notes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note_rounded,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No notes yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          const Text(
                            'Add notes while watching to capture key\npoints and ideas.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildNoteCard(_notes[i]),
                  ),
      ),
    ]);
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final noteId = note['id']?.toString() ?? '';
    final ts = note['timestamp'];
    final tsInt =
        ts is int ? ts : (ts is num ? ts.toInt() : 0);
    final content = note['content']?.toString() ?? '';
    final createdAt = note['createdAt']?.toString() ?? '';
    String? dateStr;
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Timestamp pill — tap to seek
            GestureDetector(
              onTap: () =>
                  _vpc?.seekTo(Duration(seconds: tsInt)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      size: 13, color: _kNavy),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(tsInt),
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kNavy,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            if (dateStr != null)
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDeleteNote(noteId),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.redAccent),
            ),
          ]),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.55)),
        ],
      ),
    );
  }

  void _confirmDeleteNote(String noteId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(noteId);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _NoteTimestampChip extends StatefulWidget {
  final VideoPlayerController? vpc;
  const _NoteTimestampChip({this.vpc});

  @override
  State<_NoteTimestampChip> createState() => _NoteTimestampChipState();
}

class _NoteTimestampChipState extends State<_NoteTimestampChip> {
  @override
  void initState() {
    super.initState();
    widget.vpc?.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(_NoteTimestampChip old) {
    super.didUpdateWidget(old);
    if (old.vpc != widget.vpc) {
      old.vpc?.removeListener(_rebuild);
      widget.vpc?.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.vpc?.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.vpc != null
        ? _fmt(widget.vpc!.value.position.inSeconds)
        : '0:00';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.videocam_outlined, size: 13, color: _kNavy),
        const SizedBox(width: 5),
        Text('Note at $ts',
            style: const TextStyle(
                fontSize: 12, color: _kNavy, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87));
}
