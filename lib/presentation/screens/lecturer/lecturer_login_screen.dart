import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../constants/api_constants.dart';
import '../../../core/secure_storage.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/two_fa_verification_dialog.dart';
import '../forgot_password_screen.dart';

class LecturerLoginScreen extends StatefulWidget {
  const LecturerLoginScreen({Key? key}) : super(key: key);

  @override
  State<LecturerLoginScreen> createState() => _LecturerLoginScreenState();
}

class _LecturerLoginScreenState extends State<LecturerLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;

  Future<void> _verifyAndNavigate(BuildContext context) async {
    try {
      final token = await SecureStorage.getToken();
      print('---------- [LecturerLogin] Token read from SecureStorage: $token');
      if (token == null || token.isEmpty) {
        print('---------- [LecturerLogin] ERROR: token null/empty after AuthSuccess');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login succeeded but no token was saved. Please try again.')),
        );
        return;
      }
      print('---------- [LecturerLogin] Calling /auth/me with token...');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!context.mounted) return;

      print('---------- [LecturerLogin] /auth/me status: ${response.statusCode}');
      print('---------- [LecturerLogin] /auth/me response: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Extract role from flat or nested response
        String role = '';
        if (body is Map) {
          if (body['role'] is String) {
            role = body['role'] as String;
          } else if (body['user'] is Map && body['user']['role'] is String) {
            role = body['user']['role'] as String;
          } else if (body['data'] is Map && body['data']['role'] is String) {
            role = body['data']['role'] as String;
          }
        }
        final normalized = role.toLowerCase().trim();
        print('---------- [LecturerLogin] Role extracted: "$normalized"');
        final isInstructor = normalized.contains('instruct') ||
            normalized.contains('lect') ||
            normalized.contains('teach') ||
            normalized.contains('tutor') ||
            normalized.contains('faculty') ||
            normalized.contains('admin');

        if (isInstructor) {
          await SecureStorage.saveRole('instructor');
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
              context, '/lecturer-dashboard', (_) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                normalized.isEmpty
                    ? 'Access denied: role not found in profile. Response: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}'
                    : 'Access denied: account role "$normalized" is not an instructor role.',
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not verify role (${response.statusCode}): ${response.body.length > 150 ? response.body.substring(0, 150) : response.body}'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying role: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is Auth2FARequired) {
            await showTwoFAVerificationDialog(
              context: context,
              tempToken: state.tempToken,
              onVerified: (ctx) => _verifyAndNavigate(ctx),
            );
          } else if (state is AuthSuccess) {
            _verifyAndNavigate(context);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Column(
            children: [
              Container(
                width: double.infinity,
                height: size.height * 0.25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(children: _buildLogoText()),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Welcome back!',
                                style: TextStyle(
                                  color: Colors.blueGrey[700],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Log in to continue your journey.',
                                style: TextStyle(
                                  color: Colors.blueGrey[600],
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/images/register_illustration.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.school,
                                  size: 100,
                                  color: Colors.blueGrey.shade300,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Log in to your account',
                                    style: TextStyle(
                                      color: Colors.blueGrey[900],
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enter your credentials to access your account.',
                                    style: TextStyle(
                                      color: Colors.blueGrey[500],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.blue.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.blue.shade600,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.blueGrey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5B56F5), Color(0xFF4A33E9)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      final email = emailController.text.trim();
                                      final password = passwordController.text;
                                      if (email.isEmpty || password.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
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
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shield,
                                  color: Colors.blue.shade600,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Secure & Trusted',
                                      style: TextStyle(
                                        color: Colors.blueGrey[900],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your data is safe with us. We never share your information.',
                                      style: TextStyle(
                                        color: Colors.blueGrey[600],
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.blueGrey[600],
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/lecturer-register',
                                  );
                                },
                                child: Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<TextSpan> _buildLogoText() {
    const letters = 'eduBridge';
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
    ];

    return List<TextSpan>.generate(
      letters.length,
      (index) => TextSpan(
        text: letters[index],
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: colors[index % colors.length],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
