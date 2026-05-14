import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  LandingPage({super.key});

  final GlobalKey _topCoursesKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to EduBridge',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn anything, anytime, anywhere.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for courses, topics, or instructors',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                // Removed Enroll as Lecturer button from here for a cleaner header
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Popular Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _CategoryCard(title: 'Development', icon: Icons.code),
                _CategoryCard(title: 'Business', icon: Icons.business_center),
                _CategoryCard(title: 'Design', icon: Icons.design_services),
                _CategoryCard(title: 'IT & Software', icon: Icons.computer),
                _CategoryCard(
                  title: 'Personal Dev',
                  icon: Icons.self_improvement,
                ),
                _CategoryCard(title: 'Photography', icon: Icons.camera_alt),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Featured Courses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          const _FeaturedCoursesSection(),
          const SizedBox(height: 32),
          SizedBox(
            key: _topCoursesKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Top Courses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                const _TopCoursesSection(),
              ],
            ),
          ),

          const SizedBox(height: 32),
          // Suggestions Section (moved below Top Courses)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed('/lecturer-login');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'My Certificates',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'View course completions and access earned certificates.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/certificates');
                            },
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam, color: Colors.red, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Live Sessions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Check upcoming sessions and join live classes from one place.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/live-sessions');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.blue,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Notifications',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Review reminders, updates, and recent activity in one feed.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/notifications');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed('/chat');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.support_agent,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Support Chat',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Open the student support room to ask questions and get help.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/chat');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // Top Courses Section
  }
}

class _TopCoursesSection extends StatelessWidget {
  const _TopCoursesSection();

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
    ];
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _FeaturedCourseCard(
            title: course['title']!,
            instructor: course['instructor']!,
            image: course['image'],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  const _CategoryCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 3,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCoursesSection extends StatelessWidget {
  const _FeaturedCoursesSection();

  @override
  Widget build(BuildContext context) {
    // Mock featured courses
    final courses = [
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
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _FeaturedCourseCard(
            title: course['title']!,
            instructor: course['instructor']!,
            image: course['image'],
          );
        },
      ),
    );
  }
}

class _FeaturedCourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String? image;
  const _FeaturedCourseCard({
    required this.title,
    required this.instructor,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 4,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: image == null
                  ? const Icon(Icons.menu_book, size: 40, color: Colors.blue)
                  : Image.network(image!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('By $instructor', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
