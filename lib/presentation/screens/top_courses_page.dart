import 'package:flutter/material.dart';

class TopCoursesPage extends StatelessWidget {
  const TopCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock top courses
    final courses = [
      {
        'title': 'Python for Everybody',
        'instructor': 'Dr. Charles Severance',
        'image': null,
      },
      {
        'title': 'Machine Learning A-Z',
        'instructor': 'Kirill Eremenko',
        'image': null,
      },
      {
        'title': 'The Web Developer Bootcamp',
        'instructor': 'Colt Steele',
        'image': null,
      },
      {
        'title': 'Flutter & Dart - The Complete Guide',
        'instructor': 'Jane Doe',
        'image': null,
      },
      {
        'title': 'Business Fundamentals',
        'instructor': 'John Smith',
        'image': null,
      },
      {
        'title': 'UI/UX Design Masterclass',
        'instructor': 'Emily White',
        'image': null,
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Top Courses')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: ListTile(
              leading: course['image'] == null
                  ? const Icon(Icons.menu_book, size: 40, color: Colors.blue)
                  : Image.network(
                      course['image'] as String? ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
              title: Text(
                course['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('By ${course['instructor'] ?? ''}'),
              onTap: () {
                // TODO: Navigate to course detail
              },
            ),
          );
        },
      ),
    );
  }
}
