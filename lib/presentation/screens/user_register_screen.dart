import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/auth_bloc.dart';
import '../widgets/google_sign_in_button.dart';
import 'user_login_screen.dart' show AuthGradientButton, AuthTrustBadge;

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    final username = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    context.read<AuthBloc>().add(
          RegisterEvent(email, password, 'STUDENT', username, firstName, lastName),
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.message.replaceAll('Exception: ', '')),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
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
            children: [
              // ── Gradient header ──────────────────────────────────
              Container(
                width: double.infinity,
                height: size.height * 0.22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                            text: TextSpan(
                                children: _buildLogoSpans())),
                        const SizedBox(height: 10),
                        Text(
                          'Start learning today',
                          style: TextStyle(
                            color: Colors.blueGrey[700],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create your free student account.',
                          style: TextStyle(
                            color: Colors.blueGrey[500],
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Form section ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_add_outlined,
                                color: Colors.blue.shade600, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create your account',
                                  style: TextStyle(
                                    color: Colors.blueGrey[900],
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in your details to get started.',
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
                      const SizedBox(height: 20),

                      // First + Last name (side by side)
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _firstNameCtrl,
                              label: 'First Name',
                              hint: 'John',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _lastNameCtrl,
                              label: 'Last Name',
                              hint: 'Doe',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Email
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _buildField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        hint: 'Create a strong password (8+ chars)',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.blueGrey[400],
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Confirm password
                      _buildField(
                        controller: _confirmCtrl,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.blueGrey[400],
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Sign up button
                      AuthGradientButton(
                        label: 'Create Account',
                        isLoading: isLoading,
                        onPressed: () => _submit(context),
                      ),
                      const SizedBox(height: 20),

                      // Trust badge
                      AuthTrustBadge(
                        icon: Icons.verified_user_rounded,
                        iconColor: Colors.blue.shade600,
                        bgColor: Colors.blue.shade50,
                        circleColor: Colors.blue.shade100,
                        title: 'Secure & Trusted',
                        subtitle:
                            'Your data is safe with us. We never share your information.',
                      ),
                      const SizedBox(height: 20),

                      // Google sign-up
                      const OrDivider(),
                      const GoogleSignInButton(),
                      const SizedBox(height: 20),

                      // Login link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                  color: Colors.blueGrey[600],
                                  fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, '/user-login'),
                              child: Text(
                                'Log in',
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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
        ),
      ),
    );
  }

  List<TextSpan> _buildLogoSpans() {
    const letters = 'eduBridge';
    final colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple,
      Colors.red, Colors.teal, Colors.amber, Colors.indigo, Colors.pink,
    ];
    return List.generate(
      letters.length,
      (i) => TextSpan(
        text: letters[i],
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors[i % colors.length],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
