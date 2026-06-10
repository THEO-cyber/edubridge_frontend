import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import 'course_announcements_screen.dart';
import 'course_discussions_screen.dart';

class EnhancedCourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic>? courseData;
  final bool isInstructor;

  const EnhancedCourseDetailScreen({
    super.key,
    required this.courseId,
    this.courseData,
    this.isInstructor = false,
  });

  @override
  State<EnhancedCourseDetailScreen> createState() =>
      _EnhancedCourseDetailScreenState();
}

class _EnhancedCourseDetailScreenState
    extends State<EnhancedCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.courseData ?? {};
    final title = course['title'] ?? course['courseTitle'] ?? 'Course';
    final instructor =
        course['instructorName'] ?? 'Unknown Instructor';
    final description = course['description'] ?? '';
    final image = course['image'] ?? course['courseImage'];
    final rating = (course['rating'] ?? 0.0).toDouble();
    final lessonsCount = course['lessonsCount'] ?? 0;
    final studentsCount = course['studentsCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Announcements'),
            Tab(text: 'Q&A'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(
              title, instructor, description, image, rating,
              lessonsCount, studentsCount),
          FutureBuilder<String?>(
            future: SecureStorage.getToken(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.data == null) {
                return const Center(child: Text('Sign in to view announcements'));
              }
              return CourseAnnouncementsScreen(
                courseId: widget.courseId,
                isInstructor: widget.isInstructor,
              );
            },
          ),
          FutureBuilder<String?>(
            future: SecureStorage.getToken(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.data == null) {
                return const Center(child: Text('Sign in to view discussions'));
              }
              return CourseDiscussionsScreen(courseId: widget.courseId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    String title,
    String instructor,
    String description,
    dynamic image,
    double rating,
    int lessonsCount,
    int studentsCount,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            Image.network(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.blueGrey.shade100,
                child: Icon(Icons.school,
                    size: 80, color: Colors.blueGrey.shade400),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 6),
                Text('by $instructor',
                    style: TextStyle(
                        color: Colors.blueGrey.shade600, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < rating.toInt()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('$rating / 5.0',
                        style: const TextStyle(fontSize: 12)),
                    if (studentsCount > 0) ...[
                      const SizedBox(width: 12),
                      Text('$studentsCount students',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade600)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                          Icons.video_library, '$lessonsCount lessons'),
                      _statItem(Icons.timer, 'Self-paced'),
                      _statItem(Icons.workspace_premium, 'Certificate'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('About This Course',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    description,
                    maxLines: _isExpanded ? null : 3,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 14,
                        height: 1.5),
                  ),
                ),
                if (description.length > 120)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _isExpanded ? 'Show less' : 'Show more',
                        style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text('Course Includes',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...[
                  'Video lessons',
                  'Quizzes & assessments',
                  'Downloadable resources',
                  'Q&A with instructor',
                  'Certificate of completion',
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade600, size: 18),
                        const SizedBox(width: 10),
                        Text(item),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) => Column(
        children: [
          Icon(icon, color: Colors.blueGrey.shade700),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
