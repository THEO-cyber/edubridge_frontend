import 'package:flutter/material.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void navigateTo(String actionUrl) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // /courses/:id/review → post-session review screen (dynamic route via onGenerateRoute)
    final reviewMatch = RegExp(r'^/courses/([^/]+)/review$').firstMatch(actionUrl);
    if (reviewMatch != null) {
      navigator.pushNamed(actionUrl);
      return;
    }

    if (actionUrl == '/my-courses') {
      navigator.pushNamed('/my-courses');
    } else if (actionUrl.startsWith('/courses/')) {
      navigator.pushNamed('/my-courses');
    } else if (actionUrl == '/payments/history') {
      navigator.pushNamed('/student-dashboard');
    } else if (actionUrl.startsWith('/sessions/') || actionUrl == '/live-sessions') {
      navigator.pushNamed('/live-sessions');
    } else if (actionUrl == '/certificates') {
      navigator.pushNamed('/certificates');
    } else if (actionUrl.startsWith('/chat/') || actionUrl == '/chat') {
      navigator.pushNamed('/chat');
    } else {
      navigator.pushNamed('/notifications');
    }
  }
}
