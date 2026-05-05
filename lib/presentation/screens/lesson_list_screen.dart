import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/lesson_bloc.dart';

class LessonListScreen extends StatelessWidget {
  final String courseId;
  const LessonListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data!;
          return BlocBuilder<LessonBloc, LessonState>(
            builder: (context, state) {
              if (state is LessonInitial) {
                context.read<LessonBloc>().add(
                  LoadLessonsEvent(courseId, token),
                );
                return const Center(child: CircularProgressIndicator());
              } else if (state is LessonLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is LessonLoaded) {
                return ListView.builder(
                  itemCount: state.lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = state.lessons[index];
                    return ListTile(
                      title: Text(lesson.title),
                      subtitle: lesson.description != null
                          ? Text(lesson.description!)
                          : null,
                      trailing: const Icon(Icons.play_circle_fill),
                      onTap: () {
                        // TODO: Navigate to lesson video player
                      },
                    );
                  },
                );
              } else if (state is LessonError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
