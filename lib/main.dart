import 'package:edubridge/presentation/screens/forgot_password_screen.dart';
import 'package:edubridge/presentation/screens/lecturer/lecturer_enroll_screen.dart';
import 'package:edubridge/presentation/screens/lecturer/lecturer_login_screen.dart';
import 'package:edubridge/presentation/screens/lecturer/lecturer_register_screen.dart';
import 'package:edubridge/presentation/screens/lecturer_withdrawal_screen.dart';
import 'package:edubridge/presentation/screens/search_screen.dart';
import 'package:edubridge/presentation/screens/user_login_screen.dart';
import 'package:edubridge/presentation/screens/user_register_screen.dart';
import 'package:edubridge/presentation/screens/my_courses_screen.dart';
import 'package:edubridge/presentation/screens/student_live_sessions_screen.dart';
import 'package:edubridge/presentation/screens/certificates_screen.dart';
import 'package:edubridge/presentation/screens/support_chat_screen.dart';
import 'package:edubridge/presentation/screens/lecturer_session_management_screen.dart';
import 'package:edubridge/presentation/screens/lecture_analytics_dashboard_screen.dart';
import 'package:edubridge/presentation/blocs/live_session_bloc_provider.dart';
import 'package:edubridge/presentation/screens/lecturer_earnings_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'presentation/screens/lecturer_dashboard_screen.dart';
import 'package:edubridge/presentation/blocs/profile_bloc_provider.dart';
import 'package:edubridge/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'constants/app_config.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/blocs/auth_bloc_provider.dart';
import 'presentation/blocs/wishlist_bloc_provider.dart';
import 'presentation/blocs/notification_bloc_provider.dart';
import 'presentation/blocs/chat_bloc_provider.dart';
import 'presentation/screens/wishlist_screen.dart';
import 'presentation/screens/top_courses_page.dart';
import 'presentation/screens/enroll_teacher_screen.dart';
import 'presentation/screens/notification_screen_enhanced.dart';
import 'presentation/blocs/enrollment_bloc_provider.dart';
import 'services/notification_service.dart';
import 'presentation/screens/notes_screen.dart';
import 'presentation/screens/two_factor_setup_screen.dart';
import 'presentation/screens/email_preferences_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'presentation/screens/post_session_review_screen.dart';

// Must be a top-level function — handles FCM messages when app is terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe
  try {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  } catch (_) {}

  // Firebase + push notifications
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.init();
  } catch (_) {
    // Firebase not configured for this platform — runs without push notifications.
  }

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
      navigatorKey: AppRouter.navigatorKey,
      home: const SplashScreen(),
      routes: {
        // Auth
        '/user-login': (context) => const UserLoginScreen(),
        '/user-register': (context) => const UserRegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/lecturer-login': (context) => const LecturerLoginScreen(),
        '/lecturer-register': (context) => const LecturerRegisterScreen(),
        '/lecturer-enroll': (context) => const LecturerEnrollScreen(),
        '/enroll-teacher': (context) => const EnrollTeacherScreen(),

        // Student
        '/student-dashboard': (context) =>
            WishlistBlocProvider(child: const DashboardScreen()),
        '/my-courses': (context) =>
            EnrollmentBlocProvider(child: const MyCoursesScreen()),
        '/certificates': (context) => const CertificatesScreen(),
        '/wishlist': (context) =>
            WishlistBlocProvider(child: const WishlistScreen()),
        '/top-courses': (context) => const TopCoursesPage(),
        '/live-sessions': (context) => const StudentLiveSessionsScreen(),
        '/search': (context) => const SearchScreen(),

        // Shared
        '/profile': (context) =>
            ProfileBlocProvider(child: const ProfileScreen()),
        '/notifications': (context) => NotificationBlocProvider(
            child: const NotificationScreenEnhanced()),
        '/chat': (context) =>
            ChatBlocProvider(child: const SupportChatScreen()),

        // Lecturer
        '/lecturer-dashboard': (context) => const LecturerDashboardScreen(),
        '/lecturer-sessions': (context) => LiveSessionBlocProvider(
              child: const LecturerSessionManagementScreen(),
            ),
        '/lecture-analytics': (context) => LiveSessionBlocProvider(
              child: const LectureAnalyticsDashboardScreen(),
            ),
        '/lecturer-earnings': (context) => const LecturerEarningsScreen(),
        '/lecturer-withdrawal': (context) =>
            const LecturerWithdrawalScreen(),

        // New features
        '/2fa-setup': (context) => const TwoFactorSetupScreen(),
        '/email-preferences': (context) => const EmailPreferencesScreen(),
        '/my-notes': (context) => const NotesScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle /courses/:id/review — post-session review prompt from notification tap
        final reviewMatch =
            RegExp(r'^/courses/([^/]+)/review$').firstMatch(settings.name ?? '');
        if (reviewMatch != null) {
          final courseId = reviewMatch.group(1)!;
          return MaterialPageRoute(
            builder: (_) => PostSessionReviewScreen(courseId: courseId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
