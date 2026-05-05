import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/course_bloc.dart';

class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          if (state is CourseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CourseLoaded) {
            return ListView.builder(
              itemCount: state.courses.length,
              itemBuilder: (context, index) {
                final course = state.courses[index];
                return ListTile(
                  title: Text(course.title),
                  subtitle: Text(course.description),
                  leading: course.imageUrl != null
                      ? Image.network(
                          course.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.book),
                  onTap: () {
                    // TODO: Navigate to course detail
                  },
                );
              },
            );
          } else if (state is CourseError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CourseBloc>().add(LoadCoursesEvent()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
