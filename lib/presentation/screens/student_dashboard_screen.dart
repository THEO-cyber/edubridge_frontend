import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/progress_bloc.dart';
import '../blocs/profile_bloc.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late String _token;
  int _certCount = 0;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await SecureStorage.getToken() ?? '';
    if (mounted && _token.isNotEmpty) {
      context.read<ProgressBloc>().add(FetchEnrolledCoursesEvent(_token));
      _fetchCertCount();
    }
  }

  Future<void> _fetchCertCount() async {
    try {
      final ds = ProfileRemoteDataSource(AuthRemoteDataSource());
      final analytics = await ds.fetchInstructorAnalytics(_token);
      // For students use enrollment endpoint
      final count = analytics['totalCertificates'] ?? 0;
      if (mounted) setState(() => _certCount = count as int);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Learning'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Continue Learning Section
            _buildContinueLearningSection(),
            const SizedBox(height: 24),

            // Stats Section
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        String userName = 'Student';
        if (state is ProfileLoaded) {
          userName = state.profile['name'] ?? 'Student';
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $userName! 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep learning and growing',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueLearningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continue Learning',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BlocBuilder<ProgressBloc, ProgressState>(
          builder: (context, state) {
            if (state is ProgressLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is EnrolledCoursesLoaded) {
              if (state.courses.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No enrolled courses yet'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.courses.take(3).length,
                itemBuilder: (context, index) {
                  final course = state.courses[index];
                  return _buildCourseProgressCard(
                    course.courseId,
                    'Course ${index + 1}',
                    course.progressPercentage,
                  );
                },
              );
            } else if (state is ProgressError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildCourseProgressCard(
    String courseId,
    String title,
    double progress,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.toStringAsFixed(1)}% complete',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        int courseCount = 0;
        int completedCount = 0;
        double totalHours = 0;
        if (state is EnrolledCoursesLoaded) {
          courseCount = state.courses.length;
          completedCount =
              state.courses.where((c) => c.progressPercentage >= 100).length;
          totalHours = state.courses.fold(
              0.0, (sum, c) => sum + (c.progressPercentage / 100 * 2));
        }
        return Row(
          children: [
            _buildStatCard('Courses', '$courseCount'),
            const SizedBox(width: 12),
            _buildStatCard(
                'Certificates', '${_certCount > 0 ? _certCount : completedCount}'),
            const SizedBox(width: 12),
            _buildStatCard('Hours', totalHours.toStringAsFixed(1)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BlocBuilder<ProgressBloc, ProgressState>(
          builder: (context, state) {
            if (state is EnrolledCoursesLoaded && state.courses.isNotEmpty) {
              return Column(
                children: state.courses.take(3).map((c) {
                  final pct = c.progressPercentage;
                  final label = pct >= 100
                      ? 'Completed course'
                      : 'In progress (${pct.toStringAsFixed(0)}%)';
                  return _buildActivityItem(
                      '$label: ${c.courseId}', 'Enrolled');
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[400], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    time,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
