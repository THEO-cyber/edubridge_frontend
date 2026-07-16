import 'package:edubridge/core/secure_storage.dart';
import 'package:edubridge/presentation/blocs/course_bloc_provider.dart';
import 'package:edubridge/presentation/blocs/profile_bloc_provider.dart';
import 'package:edubridge/presentation/blocs/wishlist_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> _onTabTap(int i) async {
    setState(() => _currentIndex = i);
    if (i == 2) {
      final token = await SecureStorage.getToken();
      if (mounted && token != null && token.isNotEmpty) {
        context.read<WishlistBloc>().add(LoadWishlistEvent(token));
      }
    }
  }

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
                leading: const Icon(Icons.school_outlined,
                    color: Color(0xFF1976D2)),
                title: const Text('Become an Instructor'),
                subtitle: const Text('Apply to teach on EduBridge'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Vetted onboarding: students apply; an admin approves before
                  // authoring is unlocked. (Existing instructors just log in
                  // normally — role-aware routing sends them to their dashboard.)
                  Navigator.of(this.context).pushNamed('/instructor-application');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushNamed('/settings');
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
      CourseBlocProvider(child: const CourseListScreen()),
      const WishlistScreen(),
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
        onTap: _onTabTap,
      ),
    );
  }
}
