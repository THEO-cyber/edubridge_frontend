import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../constants/api_constants.dart';
import '../../../core/http_utils.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

/// Instructor application — kept consistent with the web `/teach/register`.
/// This is a single public step: the applicant provides their account details
/// AND their teaching credentials, but NO account is created here. An admin
/// reviews the application, and the account is provisioned only on approval —
/// so the database isn't filled with dormant accounts.
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
  final motivationController = TextEditingController();
  final subjectsController = TextEditingController();
  final experienceController = TextEditingController();
  final sampleController = TextEditingController();
  final linkedinController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    for (final c in [
      firstNameController,
      lastNameController,
      emailController,
      passwordController,
      confirmPasswordController,
      motivationController,
      subjectsController,
      experienceController,
      sampleController,
      linkedinController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Mirrors the API's password policy, shown live.
  static final List<({String label, bool Function(String) test})> _rules = [
    (label: '8+ characters', test: (p) => p.length >= 8),
    (label: 'A capital letter', test: (p) => RegExp(r'[A-Z]').hasMatch(p)),
    (label: 'A lowercase letter', test: (p) => RegExp(r'[a-z]').hasMatch(p)),
    (label: 'A number', test: (p) => RegExp(r'\d').hasMatch(p)),
    (label: 'A symbol (!@#…)', test: (p) => RegExp(r'[\W_]').hasMatch(p)),
  ];

  bool get _passwordOk => _rules.every((r) => r.test(passwordController.text));
  bool get _matches =>
      passwordController.text == confirmPasswordController.text;

  Future<void> _submit() async {
    final subjects = subjectsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
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
    if (motivationController.text.trim().isEmpty || subjects.isEmpty) {
      _snack('Please share your motivation and at least one subject.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await apiPost(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.instructorApplyPublic}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'password': passwordController.text,
          'motivation': motivationController.text.trim(),
          'subjectExpertise': subjects,
          if (experienceController.text.trim().isNotEmpty)
            'teachingExperience': experienceController.text.trim(),
          if (sampleController.text.trim().isNotEmpty)
            'sampleContentUrl': sampleController.text.trim(),
          if (linkedinController.text.trim().isNotEmpty)
            'linkedinUrl': linkedinController.text.trim(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) setState(() => _submitted = true);
      } else {
        _snack(apiErrorMessage(res.body, res.statusCode,
            fallback: 'Could not submit your application.'));
      }
    } catch (e) {
      _snack(networkErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _submitted ? _buildSubmitted() : _buildForm(),
      ),
    );
  }

  Widget _buildSubmitted() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.green, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Application submitted',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Thanks for applying! We review every application to keep quality '
              'high, and will email ${emailController.text.trim()} once a '
              'decision is made. If approved, just log in with the password you '
              'set here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/lecturer-login', (_) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to login',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero ──────────────────────────────────────────────────────
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                const Text('Apply to teach',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Tell us about yourself and what you\'d teach. Every instructor '
                  'is vetted — your account is created only once you\'re approved, '
                  'then you log in with the password you set here.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.45),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('YOUR ACCOUNT'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field(firstNameController, 'First Name',
                            hint: 'Ada',
                            icon: Icons.person_outline,
                            cap: TextCapitalization.words)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(lastNameController, 'Last Name',
                            hint: 'Lovelace',
                            icon: Icons.person_outline,
                            cap: TextCapitalization.words)),
                  ],
                ),
                const SizedBox(height: 16),
                _field(emailController, 'Email Address',
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _passwordField(passwordController, 'Password',
                    hint: 'Create a strong password',
                    obscure: obscurePassword,
                    onToggle: () =>
                        setState(() => obscurePassword = !obscurePassword)),
                const SizedBox(height: 12),
                _passwordChecklist(),
                const SizedBox(height: 16),
                _passwordField(confirmPasswordController, 'Confirm Password',
                    hint: 'Type it again',
                    obscure: obscureConfirmPassword,
                    onToggle: () => setState(() =>
                        obscureConfirmPassword = !obscureConfirmPassword)),
                if (confirmPasswordController.text.isNotEmpty && !_matches) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 15, color: Colors.red.shade400),
                      const SizedBox(width: 6),
                      Text("Passwords don't match yet",
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade400)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                _sectionLabel('ABOUT YOUR TEACHING'),
                const SizedBox(height: 12),
                _field(motivationController,
                    'Why do you want to teach on EduBridge?',
                    hint: 'Share your motivation…', maxLines: 4),
                const SizedBox(height: 16),
                _field(subjectsController,
                    'Subjects you can teach (comma-separated)',
                    hint: 'e.g. Web Development, Python, Design'),
                const SizedBox(height: 16),
                _field(experienceController,
                    'Teaching / work experience (optional)',
                    hint: 'Where have you worked or taught?', maxLines: 3),
                const SizedBox(height: 16),
                _field(sampleController,
                    'Sample lesson / portfolio URL (optional)',
                    hint: 'https://…'),
                const SizedBox(height: 16),
                _field(linkedinController, 'LinkedIn URL (optional)',
                    hint: 'https://linkedin.com/in/…'),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_submitting || !_passwordOk || !_matches)
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kNavy.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit application',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: TextStyle(
                              color: Colors.blueGrey.shade600, fontSize: 14)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/lecturer-login'),
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
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Colors.blueGrey.shade400));

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
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text,
      TextCapitalization cap = TextCapitalization.none}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: cap,
      maxLines: maxLines,
      decoration: _decoration(label, hint, icon, maxLines > 1),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label,
      {String? hint, required bool obscure, required VoidCallback onToggle}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      decoration:
          _decoration(label, hint, Icons.lock_outline, false).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.blueGrey.shade400),
          onPressed: onToggle,
        ),
      ),
    );
  }

  InputDecoration _decoration(
      String label, String? hint, IconData? icon, bool alignTop) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignTop,
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
