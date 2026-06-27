import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/course_bloc.dart';
import '../blocs/enrollment_bloc_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../widgets/shimmer_widgets.dart';
import 'course_detail_screen.dart';

const _kPrimary = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CourseBloc>().add(LoadCoursesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CourseBloc>().add(LoadCoursesEvent());
        },
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Browse Courses',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimary, _kBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 52),
                    child: Text(
                      'Discover your next course',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder<CourseBloc, CourseState>(
            builder: (context, state) {
              if (state is CourseLoading) {
                return const SliverFillRemaining(
                  child: CourseListSkeleton(),
                );
              }

              if (state is CourseError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading courses:\n${state.message}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context
                                .read<CourseBloc>()
                                .add(LoadCoursesEvent()),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (state is CourseLoaded) {
                if (state.courses.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 72,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No courses available yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CourseCard(
                        course: state.courses[index],
                      ),
                      childCount: state.courses.length,
                    ),
                  ),
                );
              }

              return const SliverFillRemaining(child: SizedBox.shrink());
            },
          ),
        ],
      ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseEntity course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EnrollmentBlocProvider(
              child: CourseDetailScreen(
                courseId: course.id,
                title: course.title,
                description: course.description,
                imageUrl: course.imageUrl,
              ),
            ),
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image banner
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: course.imageUrl != null
                    ? Image.network(
                        course.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      course.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.instructorName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By ${course.instructorName}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Rating + price row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (course.reviewCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${course.reviewCount})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (course.studentCount > 0) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.people_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          '${course.studentCount}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        course.isFree
                            ? 'Free'
                            : '₦${course.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: course.isFree ? Colors.green : _kBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Level + duration pills
                  Row(
                    children: [
                      _pill(Icons.signal_cellular_alt, course.level),
                      if (course.duration != null) ...[
                        const SizedBox(width: 8),
                        _pill(Icons.access_time, course.duration!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8EAF6), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book, color: _kPrimary, size: 48),
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blueGrey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}
