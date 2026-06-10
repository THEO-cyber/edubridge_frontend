import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/auth_bloc.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({Key? key}) : super(key: key);

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final horizontalPadding = isSmall ? 18.0 : 32.0;
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 32,
            ),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) async {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                } else if (state is AuthSuccess) {
                  await SecureStorage.saveRole('student');
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, '/student-dashboard', (_) => false);
                  }
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: isSmall ? 38 : 54,
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        Icons.person,
                        size: isSmall ? 38 : 54,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 22 : 28,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to EduBridge as a user',
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontSize: isSmall ? 13 : 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 18),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => obscureConfirmPassword =
                                !obscureConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                final confirmPassword =
                                    confirmPasswordController.text;
                                if (name.isEmpty ||
                                    email.isEmpty ||
                                    password.isEmpty ||
                                    confirmPassword.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill all fields'),
                                    ),
                                  );
                                  return;
                                }
                                if (password != confirmPassword) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match'),
                                    ),
                                  );
                                  return;
                                }
                                // Split name into firstName, lastName
                                final parts = name.split(' ');
                                final firstName = parts.first;
                                final lastName = parts.length > 1
                                    ? parts.sublist(1).join(' ')
                                    : '';
                                // Username from email prefix, no spaces
                                final username = email
                                    .split('@')
                                    .first
                                    .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
                                context.read<AuthBloc>().add(
                                  RegisterEvent(
                                    email,
                                    password,
                                    'STUDENT',
                                    username,
                                    firstName,
                                    lastName,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
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
                                'Create Account',
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
                          "Already have an account?",
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/user-login',
                            );
                          },
                          child: const Text(
                            'Login',
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
