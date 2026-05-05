import 'package:edubridge/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/enrollment_bloc.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String title;
  final String description;
  final String? imageUrl;
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Center(child: Image.network(imageUrl!, height: 180)),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            BlocConsumer<EnrollmentBloc, EnrollmentState>(
              listener: (context, state) {
                if (state is EnrollmentSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enrolled successfully!')),
                  );
                } else if (state is EnrollmentFailure) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is EnrollmentLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final token = await SecureStorage.getToken();
                      if (token != null) {
                        context.read<EnrollmentBloc>().add(
                          EnrollEvent(courseId, token),
                        );
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      }
                    },
                    child: const Text('Enroll'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
