import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/enrollment_bloc.dart';
import '../blocs/lesson_bloc_provider.dart';
import 'lesson_list_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data;
          if (token == null || token.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 60, color: Colors.blueGrey[400]),
                  const SizedBox(height: 16),
                  const Text('Please login to view your courses'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/user-login');
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            );
          }
          return BlocBuilder<EnrollmentBloc, EnrollmentState>(
            builder: (context, state) {
              if (state is EnrollmentInitial) {
                context.read<EnrollmentBloc>().add(
                  FetchEnrollmentsEvent(token),
                );
                return const Center(child: CircularProgressIndicator());
              }
              if (state is EnrollmentLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is EnrollmentsLoaded) {
                final enrollments = state.enrollments;
                if (enrollments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 60,
                          color: Colors.blueGrey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text('No courses enrolled yet'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/courses');
                          },
                          child: const Text('Browse Courses'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<EnrollmentBloc>().add(
                      FetchEnrollmentsEvent(token),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: enrollments.length,
                    itemBuilder: (context, index) {
                      final enrollment = enrollments[index];
                      final courseId = (enrollment['courseId'] ?? '').toString();
                      final enrollmentId =
                          (enrollment['id'] ?? enrollment['_id'] ?? '').toString();
                      final courseTitle =
                          enrollment['courseTitle'] ?? 'Unknown Course';
                      final instructorName =
                          enrollment['instructorName'] ?? 'Unknown Instructor';
                      final progress = (enrollment['progress'] ?? 0).toInt();
                      final image = enrollment['courseImage'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonBlocProvider(
                                  child: LessonListScreen(
                                    courseId: courseId,
                                    enrollmentId: enrollmentId,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (image != null)
                                Image.network(
                                  image,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.blueGrey[200],
                                      child: Icon(
                                        Icons.school,
                                        size: 60,
                                        color: Colors.blueGrey[400],
                                      ),
                                    );
                                  },
                                ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      courseTitle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmall ? 14 : 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'by $instructorName',
                                      style: TextStyle(
                                        color: Colors.blueGrey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Progress',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueGrey[700],
                                              ),
                                            ),
                                            Text(
                                              '$progress%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: progress / 100,
                                            minHeight: 6,
                                            backgroundColor: Colors.grey[300],
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.green[600]!,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              if (state is EnrollmentFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<EnrollmentBloc>().add(
                            FetchEnrollmentsEvent(token),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          );
        },
      ),
    );
  }
}
