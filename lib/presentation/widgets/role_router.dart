import 'package:flutter/material.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/lecturer_dashboard_screen.dart';

class RoleRouter extends StatelessWidget {
  final String role;
  const RoleRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final normalized = role.toUpperCase();
    if (normalized == 'INSTRUCTOR' || normalized == 'LECTURER') {
      return const LecturerDashboardScreen();
    }
    if (normalized == 'SUPER_ADMIN' || normalized == 'SUPERADMIN' || normalized == 'ADMIN') {
      return const AdminDashboardScreen();
    }
    return const DashboardScreen();
  }
}
