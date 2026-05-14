import 'package:edubridge/presentation/blocs/course_bloc_provider.dart';
import 'package:edubridge/presentation/blocs/profile_bloc_provider.dart';
import 'package:edubridge/presentation/blocs/wishlist_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'course_list_screen.dart';
import '../widgets/main_nav_bar.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'landing_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _openStudentShortcuts() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Certificates'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushNamed('/certificates');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Live Sessions'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushNamed('/live-sessions');
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushNamed('/notifications');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Support Chat'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushNamed('/chat');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      LandingPage(),
      // Wrap CourseListScreen with CourseBlocProvider
      CourseBlocProvider(child: const CourseListScreen()),
      // Wrap WishlistScreen with WishlistBlocProvider
      WishlistBlocProvider(child: const WishlistScreen()),
      // Wrap ProfileScreen with ProfileBlocProvider
      ProfileBlocProvider(child: const ProfileScreen()),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStudentShortcuts,
        icon: const Icon(Icons.dashboard_customize_outlined),
        label: const Text('Shortcuts'),
      ),
      bottomNavigationBar: MainNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
