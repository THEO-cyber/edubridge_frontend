import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/enrollment_bloc.dart';

class EnhancedCourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic>? courseData;

  const EnhancedCourseDetailScreen({
    super.key,
    required this.courseId,
    this.courseData,
  });

  @override
  State<EnhancedCourseDetailScreen> createState() =>
      _EnhancedCourseDetailScreenState();
}

class _EnhancedCourseDetailScreenState
    extends State<EnhancedCourseDetailScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
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
          final course = widget.courseData ?? {};
          final title =
              course['title'] ?? course['courseTitle'] ?? 'Unknown Course';
          final instructor = course['instructorName'] ?? 'Unknown Instructor';
          final description =
              course['description'] ?? 'No description available';
          final image = course['image'] ?? course['courseImage'];
          final rating = (course['rating'] ?? 0.0).toDouble();
          final price = course['price'] ?? 0;
          final lessonsCount = course['lessonsCount'] ?? 0;
          final studentsCount = course['studentsCount'] ?? 0;

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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.blueGrey[200],
                        child: Icon(
                          Icons.school,
                          size: 80,
                          color: Colors.blueGrey[400],
                        ),
                      );
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmall ? 20 : 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'by $instructor',
                        style: TextStyle(
                          color: Colors.blueGrey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating.toInt()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$rating / 5.0',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          if (studentsCount > 0)
                            Text(
                              '$studentsCount students',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.video_library,
                                  color: Colors.blueGrey[700],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$lessonsCount lessons',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.timer, color: Colors.blueGrey[700]),
                                const SizedBox(height: 4),
                                const Text(
                                  'Self-paced',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.assignment,
                                  color: Colors.blueGrey[700],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Certificate',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'About This Course',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmall ? 14 : 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Text(
                          description,
                          maxLines: _isExpanded ? null : 3,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey[700],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Course Includes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmall ? 14 : 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        'Video lessons',
                        'Downloadable resources',
                        'Q&A support',
                        'Certificate of completion',
                      ].map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(item),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (token != null && token.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Continue Learning'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              // Navigate to course content
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
