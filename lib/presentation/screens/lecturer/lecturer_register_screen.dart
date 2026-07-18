import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/secure_storage.dart';
import '../../blocs/auth_bloc.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

/// Instructor sign-up. Kept consistent with the web `/teach/register` screen:
/// the same fields (name, email, password, confirm), the same live password
/// checklist, and the same vetted "step 1 of 2" framing — a learner account is
/// created, then the new user is routed into the instructor application form.
class LecturerRegisterScreen extends StatefulWidget {
  const LecturerRegisterScreen({super.key});

  @override
  State<LecturerRegisterScreen> createState() => _LecturerRegisterScreenState();
}

class _LecturerRegisterScreenState extends State<LecturerRegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Mirrors the API's password policy, shown live so an applicant sees what is
  // required while typing rather than discovering it from a rejection.
  static final List<({String label, bool Function(String) test})> _rules = [
    (label: '8+ characters', test: (p) => p.length >= 8),
    (label: 'A capital letter', test: (p) => RegExp(r'[A-Z]').hasMatch(p)),
    (label: 'A lowercase letter', test: (p) => RegExp(r'[a-z]').hasMatch(p)),
    (label: 'A number', test: (p) => RegExp(r'\d').hasMatch(p)),
    (label: 'A symbol (!@#…)', test: (p) => RegExp(r'[\W_]').hasMatch(p)),
  ];

  bool get _passwordOk =>
      _rules.every((r) => r.test(passwordController.text));
  bool get _matches =>
      passwordController.text == confirmPasswordController.text;

  String _generateUsername(String email) {
    final base = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    final safe = base.isEmpty ? 'user' : base;
    return '$safe${1000 + Random().nextInt(9000)}';
  }

  void _submit() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      _snack('Please fill in your name and email.');
      return;
    }
    if (!_passwordOk) {
      _snack('Please choose a stronger password.');
      return;
    }
    if (!_matches) {
      _snack('Both passwords must be the same.');
      return;
    }

    context.read<AuthBloc>().add(
          RegisterEvent(
            email,
            password,
            'INSTRUCTOR',
            _generateUsername(email),
            firstName,
            lastName,
          ),
        );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthSuccess) {
            final normalizedRole = state.user.role.toLowerCase();
            final alreadyInstructor = normalizedRole == 'lecturer' ||
                normalizedRole == 'teacher' ||
                normalizedRole == 'instructor' ||
                normalizedRole == 'admin';
            if (alreadyInstructor) {
              await SecureStorage.saveRole('instructor');
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/lecturer-dashboard', (_) => false);
              }
            } else {
              // Vetted onboarding: signing up creates a learner account. To
              // teach, the new user submits an instructor application that an
              // admin reviews — so send them straight to that form.
              await SecureStorage.saveRole('student');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Account created! Tell us about your teaching to apply.'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                    context, '/student-dashboard', (_) => false);
                Navigator.pushNamed(context, '/instructor-application');
              }
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kNavy, _kBlue],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Teach on EduBridge',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Create your instructor account',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set up your account, then complete a short application. '
                          'Every instructor is vetted to keep quality high — once '
                          'approved you can create courses and earn in FCFA via '
                          'MoMo & Orange Money.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.45),
                        ),
                      ],
                    ),
                  ),

                  // ── Form ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sign up to teach',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Step 1 of 2 — create your account.',
                            style: TextStyle(
                                color: Colors.blueGrey.shade500, fontSize: 13)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _field(firstNameController, 'First Name',
                                  hint: 'Ada',
                                  icon: Icons.person_outline,
                                  cap: TextCapitalization.words),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(lastNameController, 'Last Name',
                                  hint: 'Lovelace',
                                  icon: Icons.person_outline,
                                  cap: TextCapitalization.words),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _field(emailController, 'Email Address',
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _passwordField(
                          passwordController,
                          'Password',
                          hint: 'Create a strong password',
                          obscure: obscurePassword,
                          onToggle: () => setState(
                              () => obscurePassword = !obscurePassword),
                        ),
                        const SizedBox(height: 12),
                        _passwordChecklist(),
                        const SizedBox(height: 16),
                        _passwordField(
                          confirmPasswordController,
                          'Confirm Password',
                          hint: 'Type it again',
                          obscure: obscureConfirmPassword,
                          onToggle: () => setState(() =>
                              obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                        if (confirmPasswordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                  _matches
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  size: 15,
                                  color: _matches
                                      ? Colors.green
                                      : Colors.red.shade400),
                              const SizedBox(width: 6),
                              Text(
                                _matches
                                    ? 'Passwords match'
                                    : "Passwords don't match yet",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _matches
                                        ? Colors.green
                                        : Colors.red.shade400),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                (isLoading || !_passwordOk || !_matches)
                                    ? null
                                    : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kNavy,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _kNavy.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Create account & continue',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ',
                                  style: TextStyle(
                                      color: Colors.blueGrey.shade600,
                                      fontSize: 14)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/lecturer-login'),
                                child: const Text('Log in',
                                    style: TextStyle(
                                        color: _kNavy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _passwordChecklist() {
    final pw = passwordController.text;
    if (pw.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: _rules.map((r) {
        final ok = r.test(pw);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14, color: ok ? Colors.green : Colors.blueGrey.shade300),
            const SizedBox(width: 5),
            Text(r.label,
                style: TextStyle(
                    fontSize: 12,
                    color: ok ? Colors.green : Colors.blueGrey.shade500)),
          ],
        );
      }).toList(),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {String? hint,
      IconData? icon,
      TextInputType keyboard = TextInputType.text,
      TextCapitalization cap = TextCapitalization.none}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: cap,
      decoration: _decoration(label, hint, icon),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label,
      {String? hint, required bool obscure, required VoidCallback onToggle}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      decoration: _decoration(label, hint, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.blueGrey.shade400),
          onPressed: onToggle,
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String? hint, IconData? icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _kBlue),
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
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
    );
  }
}
