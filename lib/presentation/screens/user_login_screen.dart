import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/auth_bloc.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/two_fa_verification_dialog.dart';
import 'forgot_password_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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
                content: Text(state.message.replaceAll('Exception: ', '')),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is Auth2FARequired) {
            await showTwoFAVerificationDialog(
              context: context,
              tempToken: state.tempToken,
              onVerified: (ctx) async {
                await SecureStorage.saveRole('student');
                if (ctx.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      ctx, '/student-dashboard', (_) => false);
                }
              },
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
              // ── Gradient header ───────────────────────────────────
              Container(
                width: double.infinity,
                height: size.height * 0.28,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                    children: _buildLogoSpans()),
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
                                'Sign in to continue learning.',
                                style: TextStyle(
                                  color: Colors.blueGrey[500],
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
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.menu_book_rounded,
                                size: 90,
                                color: Colors.blue.shade300,
                              ),
                            ),
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
                      horizontal: 24, vertical: 28),
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
                            child: Icon(Icons.person_outline,
                                color: Colors.blue.shade600, size: 20),
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
                                  'Enter your credentials to access your courses.',
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

                      // Email
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _buildField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        hint: 'Enter your password',
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

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen()),
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
                      const SizedBox(height: 8),

                      // Login button
                      AuthGradientButton(
                        label: 'Log In',
                        isLoading: isLoading,
                        onPressed: () {
                          final email = _emailCtrl.text.trim();
                          final password = _passwordCtrl.text;
                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter email and password')),
                            );
                            return;
                          }
                          context
                              .read<AuthBloc>()
                              .add(LoginEvent(email, password));
                        },
                      ),
                      const SizedBox(height: 24),

                      // Trust badge
                      AuthTrustBadge(
                        icon: Icons.school_rounded,
                        iconColor: Colors.blue.shade600,
                        bgColor: Colors.blue.shade50,
                        circleColor: Colors.blue.shade100,
                        title: 'Thousands of learners trust EduBridge',
                        subtitle:
                            'Access world-class courses taught by expert instructors.',
                      ),
                      const SizedBox(height: 20),

                      // Google sign-in
                      const OrDivider(),
                      const GoogleSignInButton(),
                      const SizedBox(height: 20),

                      // Sign up link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                  color: Colors.blueGrey[600], fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/user-register'),
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

// ── Shared widgets (also used by register screen) ──────────────────────────

class AuthGradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthGradientButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B56F5), Color(0xFF4A33E9)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class AuthTrustBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color circleColor;
  final String title;
  final String subtitle;

  const AuthTrustBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.circleColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: circleColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.blueGrey[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.blueGrey[600],
                        fontSize: 12,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
