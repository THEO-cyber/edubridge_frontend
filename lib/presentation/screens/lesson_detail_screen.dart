import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../blocs/progress_bloc.dart';
import 'quiz_screen.dart';
import 'notes_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final String enrollmentId;
  final String lessonId;
  final String lessonTitle;
  final String videoUrl;
  final String token;
  final String? description;
  final int? durationMinutes;

  const LessonDetailScreen({
    Key? key,
    required this.enrollmentId,
    required this.lessonId,
    required this.lessonTitle,
    required this.videoUrl,
    required this.token,
    this.description,
    this.durationMinutes,
  }) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitializing = false;
  bool _videoError = false;
  bool _isCompleted = false;
  bool _progressSaved = false;

  int get _totalMinutes => widget.durationMinutes ?? 0;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.trim().isNotEmpty) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    setState(() {
      _videoInitializing = true;
      _videoError = false;
    });
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white54, size: 48),
              const SizedBox(height: 8),
              Text(errorMessage,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

      // Auto-mark complete when video finishes
      _videoController!.addListener(() {
        final pos = _videoController!.value.position;
        final dur = _videoController!.value.duration;
        if (dur.inSeconds > 0 && pos >= dur && !_isCompleted) {
          _markComplete();
        }
      });

      setState(() => _videoInitializing = false);
    } catch (e) {
      setState(() {
        _videoError = true;
        _videoInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _saveProgress() {
    final watchedSecs = _videoController?.value.position.inMinutes ?? 0;
    final minutes = watchedSecs > 0
        ? watchedSecs
        : (_totalMinutes > 0 ? _totalMinutes : 1);
    context.read<ProgressBloc>().add(
          UpdateLessonProgressEvent(
            widget.enrollmentId,
            widget.lessonId,
            minutes,
            widget.token,
          ),
        );
    setState(() => _progressSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Progress saved'),
          backgroundColor: Colors.green),
    );
  }

  void _markComplete() {
    if (_isCompleted) return;
    context.read<ProgressBloc>().add(
          MarkLessonCompleteEvent(
            widget.enrollmentId,
            widget.lessonId,
            widget.token,
          ),
        );
    setState(() => _isCompleted = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lesson complete! 🎉'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.lessonTitle,
            style: const TextStyle(fontSize: 15),
            overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1A237E),
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
                  if (_totalMinutes > 0) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.timer,
                          size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text('$_totalMinutes minutes',
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

  Widget _buildVideoSection() {
    if (widget.videoUrl.trim().isEmpty) {
      return _placeholder(
          Icons.videocam_off, 'No video available for this lesson');
    }
    if (_videoInitializing) {
      return _placeholder(null, null, loading: true);
    }
    if (_videoError) {
      return _placeholder(Icons.error_outline, 'Could not load video',
          retry: true);
    }
    if (_chewieController != null) {
      return AspectRatio(
          aspectRatio: 16 / 9,
          child: Chewie(controller: _chewieController!));
    }
    return _placeholder(Icons.play_circle_outline, 'Preparing video...',
        loading: true);
  }

  Widget _placeholder(IconData? icon, String? label,
      {bool loading = false, bool retry = false}) {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const CircularProgressIndicator(color: Colors.white54)
            else
              Icon(icon ?? Icons.videocam,
                  color: Colors.white54, size: 56),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13)),
            ],
            if (retry) ...[
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _initVideo,
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white70))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    final videoSecs = _videoController?.value.position.inSeconds;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _progressSaved ? null : _saveProgress,
                icon: Icon(
                    _progressSaved ? Icons.check : Icons.save_outlined,
                    size: 18),
                label: Text(_progressSaved ? 'Saved' : 'Save Progress'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
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
                    _isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
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
                      currentVideoSeconds: videoSecs,
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
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
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
}
