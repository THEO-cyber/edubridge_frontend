import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../constants/api_constants.dart';
import '../blocs/progress_bloc.dart';
import 'quiz_screen.dart';
import 'notes_screen.dart';

const _kNavy = Color(0xFF1A237E);

class LessonDetailScreen extends StatefulWidget {
  final String enrollmentId;
  final String lessonId;
  final String lessonTitle;
  final String videoUrl;
  final String? videoId;
  final String? videoStatus;
  final String? thumbnailUrl;
  final String token;
  final String? description;
  final int? durationMinutes;

  const LessonDetailScreen({
    super.key,
    required this.enrollmentId,
    required this.lessonId,
    required this.videoUrl,
    required this.lessonTitle,
    this.videoId,
    this.videoStatus,
    this.thumbnailUrl,
    required this.token,
    this.description,
    this.durationMinutes,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  Timer? _progressTimer;

  bool _playerStarted = false;
  bool _initializing = false;
  bool _videoError = false;
  String? _videoErrorMsg;
  bool _isCompleted = false;
  String _quality = '720p';
  final List<String> _qualities = ['720p', '480p', '360p'];

  int get _totalSeconds => (widget.durationMinutes ?? 0) * 60;
  bool get _hasProcessedVideo =>
      widget.videoId != null && widget.videoId!.isNotEmpty;
  String get _effectiveStatus => widget.videoStatus ?? '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _autoSaveProgress(force: true);
    _disposePlayer();
    super.dispose();
  }

  // ── Video URL resolution ──────────────────────────────────────────────────

  /// Resolves the stream endpoint's 302 redirect to get the actual presigned URL.
  /// MinIO presigned URLs have auth embedded — no extra header needed.
  Future<String> _resolveStreamUrl(String streamUrl) async {
    debugPrint('▶️ [Player] resolving redirect for: $streamUrl');
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(streamUrl));
      req.followRedirects = false;
      req.headers.add('Authorization', 'Bearer ${widget.token}');
      final resp = await req.close();
      client.close();

      if (resp.statusCode == 302 || resp.statusCode == 301) {
        final location = resp.headers.value('location');
        if (location != null && location.isNotEmpty) {
          debugPrint('✅ [Player] presigned URL resolved');
          return location;
        }
      }
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final url =
              json['url'] ?? json['streamUrl'] ?? json['playbackUrl'];
          if (url != null) return url.toString();
        } catch (_) {}
      }
      debugPrint('⚠️ [Player] no redirect — using original URL');
      return streamUrl;
    } catch (e) {
      debugPrint('❌ [Player] redirect resolve failed: $e — using original URL');
      return streamUrl;
    }
  }

  // ── Player lifecycle ──────────────────────────────────────────────────────

  Future<void> _initPlayer({String? quality}) async {
    debugPrint('▶️ [Player] init lessonId=${widget.lessonId}');
    debugPrint('   videoId=${widget.videoId} videoStatus=${widget.videoStatus}');
    debugPrint('   videoUrl=${widget.videoUrl}  enrollmentId=${widget.enrollmentId}');
    _progressTimer?.cancel();
    _disposePlayer();
    setState(() {
      _initializing = true;
      _videoError = false;
      _videoErrorMsg = null;
    });

    try {
      final String url;
      final Map<String, String> headers;

      if (_hasProcessedVideo &&
          (_effectiveStatus == 'READY' || _effectiveStatus == 'APPROVED')) {
        final streamUrl =
            '${ApiConstants.baseUrl}${ApiConstants.videoStream(widget.videoId!)}?quality=${quality ?? _quality}';
        // Resolve the 302 → presigned MinIO URL first
        final resolved = await _resolveStreamUrl(streamUrl);
        url = resolved;
        // Presigned URL embeds auth — no Authorization header needed
        headers = {};
        debugPrint('▶️ [Player] using presigned URL (resolved)');
      } else if (!_hasProcessedVideo && widget.videoUrl.trim().isNotEmpty) {
        url = widget.videoUrl.trim();
        headers = {
          'Authorization': 'Bearer ${widget.token}',
          'Range': 'bytes=0-',
        };
        debugPrint('▶️ [Player] using legacy videoUrl: $url');
      } else {
        debugPrint(
            '❌ [Player] no playable video — hasProcessed=$_hasProcessedVideo status=$_effectiveStatus url=${widget.videoUrl}');
        setState(() => _initializing = false);
        return;
      }

      debugPrint('▶️ [Player] initializing VideoPlayerController...');
      _vpc = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers,
      );
      await _vpc!.initialize();
      debugPrint('✅ [Player] initialized — duration=${_vpc!.value.duration}');

      _chewie = ChewieController(
        videoPlayerController: _vpc!,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
            ? Image.network(widget.thumbnailUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black))
            : Container(color: Colors.black),
        errorBuilder: (_, msg) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
          ]),
        ),
      );

      // Auto-mark complete when video reaches the end
      _vpc!.addListener(_onVideoTick);

      // Periodic progress save every 30 seconds while playing
      _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_vpc?.value.isPlaying == true) _autoSaveProgress();
      });

      if (mounted) setState(() => _initializing = false);
    } catch (e, st) {
      debugPrint('❌ [Player] error: $e\n$st');
      if (mounted) {
        setState(() {
          _initializing = false;
          _videoError = true;
          _videoErrorMsg = 'Could not load video: $e';
        });
      }
    }
  }

  void _onVideoTick() {
    final pos = _vpc!.value.position;
    final dur = _vpc!.value.duration;
    if (dur.inSeconds > 0 && pos >= dur && !_isCompleted) _markComplete();
  }

  void _disposePlayer() {
    _vpc?.removeListener(_onVideoTick);
    _chewie?.dispose();
    _chewie = null;
    _vpc?.dispose();
    _vpc = null;
  }

  Future<void> _switchQuality(String quality) async {
    if (quality == _quality && _chewie != null) return;
    setState(() {
      _quality = quality;
      _playerStarted = true;
    });
    if (_hasProcessedVideo && _effectiveStatus == 'READY') {
      await _initPlayer(quality: quality);
    }
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  void _autoSaveProgress({bool force = false}) {
    if (_vpc == null) return;
    final pos = _vpc!.value.position.inSeconds;
    final dur = _vpc!.value.duration.inSeconds;
    if (dur <= 0 && !force) return;
    final totalSec = dur > 0 ? dur : _totalSeconds;
    context.read<ProgressBloc>().add(SaveLessonProgressEvent(
          lessonId: widget.lessonId,
          watchedSeconds: pos,
          totalSeconds: totalSec > 0 ? totalSec : 1,
          completed: _isCompleted,
          token: widget.token,
        ));
  }

  void _saveProgress() {
    final pos = _vpc?.value.position.inSeconds ?? 0;
    final dur = _vpc?.value.duration.inSeconds ?? 0;
    final totalSec = dur > 0 ? dur : _totalSeconds;
    context.read<ProgressBloc>().add(SaveLessonProgressEvent(
          lessonId: widget.lessonId,
          watchedSeconds: pos > 0 ? pos : (_totalSeconds > 0 ? _totalSeconds : 1),
          totalSeconds: totalSec > 0 ? totalSec : 1,
          completed: _isCompleted,
          token: widget.token,
        ));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress saved'), backgroundColor: Colors.green));
  }

  void _markComplete() {
    if (_isCompleted) return;
    setState(() => _isCompleted = true);
    final dur = _vpc?.value.duration.inSeconds ?? _totalSeconds;
    context.read<ProgressBloc>().add(SaveLessonProgressEvent(
          lessonId: widget.lessonId,
          watchedSeconds: dur > 0 ? dur : (_totalSeconds > 0 ? _totalSeconds : 1),
          totalSeconds: dur > 0 ? dur : (_totalSeconds > 0 ? _totalSeconds : 1),
          completed: true,
          token: widget.token,
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lesson complete! 🎉'), backgroundColor: Colors.green));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.lessonTitle,
            style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle, color: Colors.greenAccent),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoSection(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.lessonTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  if (_totalSeconds > 0) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.timer, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(_fmtDuration(widget.durationMinutes ?? 0),
                          style: TextStyle(
                              color: Colors.blueGrey.shade600, fontSize: 13)),
                    ]),
                  ],
                  const SizedBox(height: 20),
                  _buildActionRow(),
                  if (widget.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    const Text('About this lesson',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(widget.description!,
                        style: TextStyle(
                            color: Colors.blueGrey.shade700, height: 1.5)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Video section ─────────────────────────────────────────────────────────

  Widget _buildVideoSection() {
    if (_hasProcessedVideo) {
      switch (_effectiveStatus) {
        case 'UPLOADED':
          return _placeholder(
              Icons.cloud_upload_outlined, 'Video uploaded, waiting to process…');
        case 'PROCESSING':
          return _placeholder(null, 'Processing video…', loading: true);
        case 'PENDING_REVIEW':
          return _placeholder(Icons.pending_outlined, 'Awaiting admin approval');
        case 'FAILED':
          return _placeholder(Icons.error_outline,
              'Processing failed. Please re-upload.',
              color: Colors.red);
      }
    }

    if (!_hasProcessedVideo && widget.videoUrl.trim().isEmpty) {
      return _placeholder(Icons.videocam_off, 'No video for this lesson');
    }

    if (_videoError) {
      return _placeholder(Icons.error_outline,
          _videoErrorMsg ?? 'Could not load video',
          retry: true);
    }

    if (!_playerStarted) return _buildThumbnailPlay();
    if (_initializing) return _buildLoadingOverlay();

    if (_chewie != null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Chewie(controller: _chewie!),
            ),
          ),
          if (_hasProcessedVideo) _buildQualityBar(),
        ],
      );
    }

    return _buildLoadingOverlay();
  }

  Widget _buildThumbnailPlay() {
    final hasThumbnail =
        widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () {
        setState(() => _playerStarted = true);
        _initPlayer();
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumbnail)
              Image.network(widget.thumbnailUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumbnailFallback())
            else
              _thumbnailFallback(),
            Container(color: Colors.black.withValues(alpha: 0.35)),
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
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.play_arrow_rounded, color: _kNavy, size: 50),
              ),
            ),
            if (widget.durationMinutes != null && widget.durationMinutes! > 0)
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _fmtDuration(widget.durationMinutes!),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    final hasThumbnail =
        widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasThumbnail)
            Image.network(widget.thumbnailUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbnailFallback())
          else
            _thumbnailFallback(),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
        ],
      ),
    );
  }

  Widget _thumbnailFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.play_lesson_outlined, color: Colors.white24, size: 72),
        ),
      );

  Widget _buildQualityBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.hd_outlined, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          const Text('Quality:', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 8),
          ..._qualities.map((q) => GestureDetector(
                onTap: () => _switchQuality(q),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _quality == q ? _kNavy : Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _quality == q ? _kNavy : Colors.white24),
                  ),
                  child: Text(q,
                      style: TextStyle(
                          color: _quality == q ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: _quality == q
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _placeholder(IconData? icon, String? label,
      {bool loading = false, bool retry = false, Color color = Colors.white54}) {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              CircularProgressIndicator(
                  color: color == Colors.white54 ? Colors.white54 : color)
            else
              Icon(icon ?? Icons.videocam, color: color, size: 56),
            if (label != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center),
              ),
            ],
            if (retry) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _videoError = false;
                    _playerStarted = false;
                  });
                },
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Action row ────────────────────────────────────────────────────────────

  Widget _buildActionRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveProgress,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Progress'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kNavy,
                  side: const BorderSide(color: _kNavy),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCompleted ? null : _markComplete,
                icon: Icon(
                    _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                    size: 18),
                label: Text(_isCompleted ? 'Completed' : 'Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCompleted ? Colors.grey.shade400 : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotesScreen(
                      lessonId: widget.lessonId,
                      lessonTitle: widget.lessonTitle,
                      currentVideoSeconds:
                          _vpc?.value.position.inSeconds,
                    ),
                  ),
                ),
                icon: const Icon(Icons.note_alt_outlined, size: 18),
                label: const Text('Notes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueGrey,
                  side: const BorderSide(color: Colors.blueGrey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      lessonId: widget.lessonId,
                      lessonTitle: widget.lessonTitle,
                    ),
                  ),
                ),
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: const Text('Quiz'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kNavy,
                  side: const BorderSide(color: _kNavy),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
