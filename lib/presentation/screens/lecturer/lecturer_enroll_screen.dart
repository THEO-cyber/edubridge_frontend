import 'package:flutter/material.dart';

class LecturerEnrollScreen extends StatelessWidget {
  const LecturerEnrollScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final horizontalPadding = isSmall ? 18.0 : 32.0;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: isSmall ? 38 : 54,
                  backgroundColor: Colors.blueGrey[50],
                  child: Icon(
                    Icons.school,
                    size: isSmall ? 38 : 54,
                    color: Colors.blueGrey[700],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Enroll as Lecturer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 22 : 28,
                    color: Colors.blueGrey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get started as a lecturer on EduBridge',
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: isSmall ? 13 : 15,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'To enroll as a lecturer, you must first login or create an account.',
                  style: TextStyle(
                    color: Colors.blueGrey[700],
                    fontSize: isSmall ? 13 : 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/lecturer-register',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
