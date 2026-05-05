import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc.dart';
import '../lecturer_dashboard_screen.dart';

class LecturerLoginScreen extends StatefulWidget {
  const LecturerLoginScreen({Key? key}) : super(key: key);

  @override
  State<LecturerLoginScreen> createState() => _LecturerLoginScreenState();
}

class _LecturerLoginScreenState extends State<LecturerLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // bool isLoading = false; // handled by Bloc
  bool obscurePassword = true;

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
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  // Always show a user-friendly message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invalid email or password. Please try again.',
                      ),
                    ),
                  );
                } else if (state is AuthSuccess) {
                  // Only allow lecturers to access dashboard
                  if (state.user.role == 'lecturer') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LecturerDashboardScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Access denied: Not a lecturer account'),
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo or Illustration
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
                      'Lecturer Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 22 : 28,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your lecturer account',
                      style: TextStyle(
                        color: Colors.blueGrey[400],
                        fontSize: isSmall ? 13 : 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter email and password',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                context.read<AuthBloc>().add(
                                  LoginEvent(email, password),
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
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have a lecturer account?",
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/lecturer-enroll');
                          },
                          child: const Text(
                            'Enroll as Lecturer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
