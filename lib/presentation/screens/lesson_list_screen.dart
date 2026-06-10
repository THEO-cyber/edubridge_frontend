import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/lesson_bloc.dart';
import 'lesson_detail_screen.dart';

class LessonListScreen extends StatelessWidget {
  final String courseId;
  final String enrollmentId;

  const LessonListScreen({
    super.key,
    required this.courseId,
    this.enrollmentId = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Course Lessons'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1A237E)));
          }
          final token = snapshot.data!;
          return BlocBuilder<LessonBloc, LessonState>(
            builder: (context, state) {
              if (state is LessonInitial) {
                context
                    .read<LessonBloc>()
                    .add(LoadLessonsEvent(courseId, token));
                return const Center(child: CircularProgressIndicator());
              }
              if (state is LessonLoading) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1A237E)));
              }
              if (state is LessonLoaded) {
                if (state.lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_outlined,
                            size: 64,
                            color: Colors.blueGrey.shade300),
                        const SizedBox(height: 16),
                        const Text('No lessons available yet',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = state.lessons[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E)),
                            ),
                          ),
                        ),
                        title: Text(lesson.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: lesson.description != null
                            ? Text(lesson.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.blueGrey.shade500,
                                    fontSize: 12))
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: lesson.videoUrl.isNotEmpty
                                ? const Color(0xFF1A237E)
                                    .withValues(alpha: 0.08)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            lesson.videoUrl.isNotEmpty
                                ? Icons.play_circle_filled
                                : Icons.lock_outline,
                            color: lesson.videoUrl.isNotEmpty
                                ? const Color(0xFF1A237E)
                                : Colors.grey,
                            size: 22,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => LessonDetailScreen(
                              enrollmentId: enrollmentId,
                              lessonId: lesson.id,
                              lessonTitle: lesson.title,
                              videoUrl: lesson.videoUrl,
                              token: token,
                              description: lesson.description,
                            ),
                          ));
                        },
                      ),
                    );
                  },
                );
              }
              if (state is LessonError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 56, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context
                            .read<LessonBloc>()
                            .add(LoadLessonsEvent(courseId, token)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
