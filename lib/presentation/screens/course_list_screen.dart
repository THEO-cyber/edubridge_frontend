import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/course_bloc.dart';
import '../blocs/enrollment_bloc_provider.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  @override
  void initState() {
    super.initState();
    // Load courses when screen opens
    context.read<CourseBloc>().add(LoadCoursesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          print('[DEBUG COURSE UI] CourseState: ${state.runtimeType}');
          if (state is CourseLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading courses...'),
                ],
              ),
            );
          } else if (state is CourseLoaded) {
            print(
              '[DEBUG COURSE UI] CourseLoaded with ${state.courses.length} courses',
            );
            if (state.courses.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No courses available yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EnrollmentBlocProvider(
                          child: CourseDetailScreen(
                            courseId: course.id,
                            title: course.title,
                            description: course.description,
                            imageUrl: course.imageUrl,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is CourseError) {
            print('[DEBUG COURSE UI] CourseError: ${state.message}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading courses: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CourseBloc>().add(LoadCoursesEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          print('[DEBUG COURSE UI] Unknown state: ${state.runtimeType}');
          return const Center(child: Text('Unknown state'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'course_list_refresh_button',
        onPressed: () => context.read<CourseBloc>().add(LoadCoursesEvent()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
