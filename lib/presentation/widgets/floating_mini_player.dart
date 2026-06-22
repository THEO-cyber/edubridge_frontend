import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_router.dart';
import '../../core/mini_player_manager.dart';
import '../screens/course_player_screen.dart';

class FloatingMiniPlayerOverlay extends StatefulWidget {
  const FloatingMiniPlayerOverlay({super.key});

  @override
  State<FloatingMiniPlayerOverlay> createState() =>
      _FloatingMiniPlayerOverlayState();
}

class _FloatingMiniPlayerOverlayState
    extends State<FloatingMiniPlayerOverlay> {
  Offset _pos = const Offset(-1, -1);
  final _mgr = MiniPlayerManager.instance;

  @override
  void initState() {
    super.initState();
    _mgr.addListener(_rebuild);
  }

  @override
  void dispose() {
    _mgr.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _expand() {
    final mgr = MiniPlayerManager.instance;
    if (!mgr.isActive || mgr.vpc == null) return;

    final courseId = mgr.courseId;
    final courseTitle = mgr.courseTitle;
    final courseImageUrl = mgr.courseImageUrl;
    final lessons = List<Map<String, dynamic>>.from(mgr.lessons ?? []);
    final currentIndex = mgr.currentIndex;
    final token = mgr.token;
    final enrollmentId = mgr.enrollmentId;
    final completed = Set<String>.from(mgr.completed);

    final vpc = mgr.takeController();
    if (vpc == null) return;

    AppRouter.navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => CoursePlayerScreen(
        courseId: courseId,
        courseTitle: courseTitle,
        courseImageUrl: courseImageUrl,
        lessons: lessons,
        startLessonIndex: currentIndex,
        enrollmentId: enrollmentId,
        token: token,
        completedLessonIds: completed,
        existingController: vpc,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_mgr.isActive || _mgr.vpc == null) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    const w = 188.0;
    const videoH = w * 9 / 16; // 105.75
    const totalH = videoH + 44.0;

    if (_pos.dx < 0) {
      _pos = Offset(size.width - w - 12, size.height - totalH - 88);
    }

    return Positioned(
      left: _pos.dx.clamp(0.0, size.width - w),
      top: _pos.dy.clamp(0.0, size.height - totalH),
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          _pos = Offset(
            (_pos.dx + d.delta.dx).clamp(0.0, size.width - w),
            (_pos.dy + d.delta.dy).clamp(0.0, size.height - totalH),
          );
        }),
        child: Material(
          elevation: 14,
          borderRadius: BorderRadius.circular(14),
          shadowColor: Colors.black45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Video preview
                  GestureDetector(
                    onTap: _expand,
                    child: SizedBox(
                      width: w,
                      height: videoH,
                      child: _VideoPreview(vpc: _mgr.vpc!),
                    ),
                  ),
                  // Controls strip
                  _ControlsStrip(
                    vpc: _mgr.vpc!,
                    mgr: _mgr,
                    onExpand: _expand,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Video preview ────────────────────────────────────────────────────────────

class _VideoPreview extends StatefulWidget {
  final VideoPlayerController vpc;
  const _VideoPreview({required this.vpc});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  @override
  void initState() {
    super.initState();
    widget.vpc.addListener(_rebuild);
    // Resume playback once the new VideoPlayer surface is fully attached.
    // The one-frame delay lets the platform surface bind before play() is called,
    // which prevents the ImageReader buffer flood from a decoder with no surface.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.vpc.value.isInitialized && !widget.vpc.value.isPlaying) {
        widget.vpc.play();
      }
    });
  }

  @override
  void dispose() {
    widget.vpc.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(aspectRatio: 16 / 9, child: VideoPlayer(widget.vpc)),
        if (!widget.vpc.value.isPlaying)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 32),
            ),
          ),
      ],
    );
  }
}

// ─── Controls strip ───────────────────────────────────────────────────────────

class _ControlsStrip extends StatefulWidget {
  final VideoPlayerController vpc;
  final MiniPlayerManager mgr;
  final VoidCallback onExpand;
  const _ControlsStrip(
      {required this.vpc, required this.mgr, required this.onExpand});

  @override
  State<_ControlsStrip> createState() => _ControlsStripState();
}

class _ControlsStripState extends State<_ControlsStrip> {
  @override
  void initState() {
    super.initState();
    widget.vpc.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.vpc.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.vpc.value.isPlaying;
    final title =
        widget.mgr.lesson?['title']?.toString() ?? '';

    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          _iconBtn(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 20,
            onTap: () => setState(
                () => playing ? widget.vpc.pause() : widget.vpc.play()),
          ),
          const SizedBox(width: 6),
          _iconBtn(Icons.open_in_full_rounded,
              size: 15,
              color: Colors.white60,
              onTap: widget.onExpand),
          const SizedBox(width: 6),
          _iconBtn(Icons.close_rounded,
              size: 15,
              color: Colors.white38,
              onTap: widget.mgr.dismiss),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon,
          {required VoidCallback onTap,
          double size = 18,
          Color color = Colors.white}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, color: color, size: size),
        ),
      );
}
