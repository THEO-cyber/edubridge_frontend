import 'package:edubridge/presentation/screens/lecturer/lecturer_enroll_screen.dart';
import 'package:edubridge/presentation/screens/lecturer/lecturer_login_screen.dart';
import 'package:edubridge/presentation/screens/lecturer/lecturer_register_screen.dart';
import 'package:edubridge/presentation/screens/user_login_screen.dart';
import 'package:edubridge/presentation/screens/user_register_screen.dart';

import 'presentation/screens/lecturer_dashboard_screen.dart';
import 'package:edubridge/presentation/blocs/profile_bloc_provider.dart';
import 'package:edubridge/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/blocs/auth_bloc_provider.dart';
import 'presentation/blocs/wishlist_bloc_provider.dart';
import 'presentation/blocs/certificate_bloc_provider.dart';
import 'presentation/screens/wishlist_screen.dart';
import 'presentation/screens/certificate_screen.dart';
import 'presentation/screens/top_courses_page.dart';
import 'presentation/screens/enroll_teacher_screen.dart';

void main() {
  runApp(const EduBridgeRoot());
}

class EduBridgeRoot extends StatelessWidget {
  const EduBridgeRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBlocProvider(child: const EduBridgeApp());
  }
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
      routes: {
        '/wishlist': (context) =>
            WishlistBlocProvider(child: const WishlistScreen()),
        '/certificates': (context) =>
            CertificateBlocProvider(child: const CertificateScreen()),
        '/profile': (context) =>
            ProfileBlocProvider(child: const ProfileScreen()),
        '/top-courses': (context) => const TopCoursesPage(),
        '/enroll-teacher': (context) => const EnrollTeacherScreen(),
        '/lecturer-dashboard': (context) => const LecturerDashboardScreen(),
        '/lecturer-login': (context) => const LecturerLoginScreen(),
        '/lecturer-enroll': (context) => const LecturerEnrollScreen(),
        '/lecturer-register': (context) => const LecturerRegisterScreen(),
        '/user-login': (context) => const UserLoginScreen(),
        '/user-register': (context) => const UserRegisterScreen(),
      },
    );
  }
}

// Home page and other screens will be implemented as part of the clean architecture structure.
