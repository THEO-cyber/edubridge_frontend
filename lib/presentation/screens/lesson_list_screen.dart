import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/lesson_bloc.dart';
import '../../domain/entities/lesson_entity.dart';
import '../widgets/shimmer_widgets.dart';
import 'lesson_detail_screen.dart';

const _kNavy = Color(0xFF1A237E);

class LessonListScreen extends StatefulWidget {
  final String courseId;
  final String enrollmentId;

  const LessonListScreen({
    super.key,
    required this.courseId,
    this.enrollmentId = '',
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await SecureStorage.getToken();
    if (!mounted) return;
    _token = token ?? '';
    // Always refresh on screen entry — cache handles instant display
    context.read<LessonBloc>().add(
          LoadLessonsEvent(widget.courseId, _token!),
        );
  }

  Future<void> _refresh() async {
    if (_token == null) return;
    context.read<LessonBloc>().add(LoadLessonsEvent(widget.courseId, _token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Course Lessons'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<LessonBloc, LessonState>(
        builder: (context, state) {
          if (state is LessonLoading) {
            return const LessonListSkeleton();
          }

          if (state is LessonLoaded) {
            if (state.lessons.isEmpty) {
              return const _EmptyLessons();
            }
            return RefreshIndicator(
              color: _kNavy,
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.lessons.length,
                itemBuilder: (context, index) => _LessonCard(
                  lesson: state.lessons[index],
                  index: index,
                  token: _token ?? '',
                  enrollmentId: widget.enrollmentId,
                ),
              ),
            );
          }

          if (state is LessonError) {
            return _ErrorView(message: state.message, onRetry: _refresh);
          }

          // Initial — _init() will dispatch the event shortly
          return const LessonListSkeleton();
        },
      ),
    );
  }
}

class _EmptyLessons extends StatelessWidget {
  const _EmptyLessons();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined,
              size: 64, color: Colors.blueGrey.shade300),
          const SizedBox(height: 16),
          const Text('No lessons available yet',
              style: TextStyle(fontSize: 16, color: Colors.black45)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Lesson card ───────────────────────────────────────────────────────────────

enum _VideoState { ready, processing, failed, none }

class _LessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final int index;
  final String token;
  final String enrollmentId;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.token,
    required this.enrollmentId,
  });

  _VideoState get _videoState {
    if (lesson.hasProcessedVideo) {
      switch (lesson.videoStatus) {
        case 'READY':
          return _VideoState.ready;
        case 'PROCESSING':
        case 'UPLOADED':
          return _VideoState.processing;
        case 'FAILED':
          return _VideoState.failed;
      }
    }
    if (lesson.videoUrl.isNotEmpty) return _VideoState.ready;
    return _VideoState.none;
  }

  @override
  Widget build(BuildContext context) {
    final state = _videoState;
    final canPlay = state == _VideoState.ready;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canPlay
            ? () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LessonDetailScreen(
                    enrollmentId: enrollmentId,
                    lessonId: lesson.id,
                    lessonTitle: lesson.title,
                    videoUrl: lesson.videoUrl,
                    videoId: lesson.videoId,
                    videoStatus: lesson.videoStatus,
                    thumbnailUrl: lesson.thumbnailUrl,
                    token: token,
                    description: lesson.description,
                  ),
                ))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildLeading(state),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (lesson.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        lesson.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _buildStatusChip(state),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                canPlay ? Icons.play_circle_outline_rounded : Icons.lock_outline,
                color: canPlay ? _kNavy : Colors.grey.shade300,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(_VideoState state) {
    final thumb = lesson.thumbnailUrl ?? '';
    if (thumb.isNotEmpty && state == _VideoState.ready) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumb,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _numberBadge(),
        ),
      );
    }
    return _numberBadge();
  }

  Widget _numberBadge() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _kNavy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _kNavy)),
        ),
      );

  Widget _buildStatusChip(_VideoState state) {
    switch (state) {
      case _VideoState.ready:
        return const _Chip(
            label: 'Ready', color: Colors.green, icon: Icons.check_circle);
      case _VideoState.processing:
        return const _Chip(
            label: 'Processing…',
            color: Colors.orange,
            icon: Icons.hourglass_top);
      case _VideoState.failed:
        return const _Chip(
            label: 'Failed', color: Colors.red, icon: Icons.error_outline);
      case _VideoState.none:
        return const _Chip(
            label: 'No video', color: Colors.grey, icon: Icons.videocam_off);
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Chip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
