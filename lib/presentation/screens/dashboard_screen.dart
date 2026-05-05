import 'package:edubridge/presentation/blocs/course_bloc_provider.dart';
import 'package:edubridge/presentation/blocs/profile_bloc_provider.dart';
import 'package:edubridge/presentation/blocs/wishlist_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'course_list_screen.dart';
import 'enroll_teacher_screen.dart';
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
      bottomNavigationBar: MainNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
