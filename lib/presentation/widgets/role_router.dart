import 'package:flutter/material.dart';
import '../screens/student_dashboard.dart';
import '../screens/teacher_dashboard.dart';

class RoleRouter extends StatelessWidget {
  final String role;
  const RoleRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == 'teacher') {
      return const TeacherDashboard();
    }
    return const StudentDashboard();
  }
}
