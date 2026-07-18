import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

enum _Step { email, otp, password, done }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.email;

  // Step 1 — email
  final _emailCtrl = TextEditingController();

  // Step 2 — OTP
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());

  // Step 3 — password
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  String _resetToken = '';
  bool _loading = false;
  String? _error;

  late final AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  static const _kNavy = Color(0xFF1A237E);
  static const _kBlue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0.18, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _animateTo(_Step next) {
    _slideCtrl.reset();
    setState(() {
      _step = next;
      _error = null;
    });
    _slideCtrl.forward();
  }

  // ── Step 1: request OTP ───────────────────────────────────────────────────
  Future<void> _requestCode() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = ApiConstants.baseUrl + ApiConstants.forgotPassword;
      final body = jsonEncode({'email': email});
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _animateTo(_Step.otp);
      } else {
        String msg = 'Could not send code';
        try {
          final b = jsonDecode(res.body);
          if (b is Map) {
            final raw = b['message'] ?? b['error'];
            if (raw is List) {
              msg = raw.first.toString();
            } else if (raw != null) {
              msg = raw.toString();
            }
          }
        } catch (_) {}
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Step 2: verify OTP with backend, receive resetToken ───────────────────
  Future<void> _confirmOtp() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _error = 'Enter all 6 digits of the code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.verifyResetOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final token = (body['resetToken'] ?? '').toString();
        if (token.isEmpty) {
          setState(() => _error = 'Verification failed: no token received');
          return;
        }
        _resetToken = token;
        _animateTo(_Step.password);
      } else {
        String msg = 'Invalid or expired code';
        try {
          final b = jsonDecode(res.body);
          if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
        } catch (_) {}
        setState(() => _error = msg);
      }
    } catch (_) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Step 3: submit reset ───────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'resetToken': _resetToken,
          'newPassword': password,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _animateTo(_Step.done);
      } else {
        String msg = 'Failed to reset password';
        try {
          final b = jsonDecode(res.body);
          if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
        } catch (_) {}
        setState(() => _error = msg);
      }
    } catch (_) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── OTP box handler ────────────────────────────────────────────────────────
  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste — distribute across boxes
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _otpCtrls[i].text = digits[i];
      }
      final next = (digits.length < 6 ? digits.length : 5);
      _otpNodes[next].requestFocus();
      setState(() {});
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _otpNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onOtpBackspace(int index) {
    if (_otpCtrls[index].text.isEmpty && index > 0) {
      _otpNodes[index - 1].requestFocus();
      _otpCtrls[index - 1].clear();
      setState(() {});
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: _step == _Step.done
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (_step == _Step.otp) {
                    _animateTo(_Step.email);
                  } else if (_step == _Step.password) {
                    _animateTo(_Step.otp);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _Step.email:
        return _buildEmailStep();
      case _Step.otp:
        return _buildOtpStep();
      case _Step.password:
        return _buildPasswordStep();
      case _Step.done:
        return _buildDoneStep();
    }
  }

  // ── Step 1 UI ──────────────────────────────────────────────────────────────
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          icon: Icons.email_rounded,
          title: 'Forgot your password?',
          subtitle:
              "Enter your account email and we'll send a 6-digit code to reset your password.",
        ),
        const SizedBox(height: 32),
        const _Label('Email address'),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          autofocus: true,
          decoration: _inputDec(
            hint: 'you@example.com',
            prefix: const Icon(Icons.alternate_email_rounded, color: _kNavy),
          ),
          onSubmitted: (_) => _loading ? null : _requestCode(),
        ),
        _errorBox(),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Send Code',
          icon: Icons.send_rounded,
          onPressed: _requestCode,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Login',
                style: TextStyle(color: _kNavy, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Step 2 UI ──────────────────────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _header(
          icon: Icons.lock_open_rounded,
          title: 'Enter the code',
          subtitle:
              'A 6-digit code was sent to\n${_emailCtrl.text.trim()}\nIt expires in 30 seconds.',
        ),
        const SizedBox(height: 36),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = _otpCtrls[i].text.isNotEmpty;
            return Container(
              width: 46,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: filled ? _kNavy.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filled ? _kNavy : const Color(0xFFDDE1EF),
                  width: filled ? 2 : 1.5,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: _kNavy.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  if (event is RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      _otpCtrls[i].text.isEmpty) {
                    _onOtpBackspace(i);
                  }
                },
                child: TextField(
                  controller: _otpCtrls[i],
                  focusNode: _otpNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _kNavy,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _onOtpChanged(i, v),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Paste button
        TextButton.icon(
          onPressed: () async {
            final data = await Clipboard.getData('text/plain');
            if (data?.text != null) {
              _onOtpChanged(0, data!.text!.replaceAll(RegExp(r'\D'), ''));
            }
          },
          icon: const Icon(Icons.content_paste_rounded, size: 16),
          label: const Text('Paste code'),
          style: TextButton.styleFrom(foregroundColor: _kBlue),
        ),

        _errorBox(),
        const SizedBox(height: 24),

        _primaryButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: () { _confirmOtp(); },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Didn't receive it? ",
                style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13)),
            GestureDetector(
              onTap: _loading ? null : _requestCode,
              child: const Text(
                'Resend code',
                style: TextStyle(
                    color: _kBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3 UI ──────────────────────────────────────────────────────────────
  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          icon: Icons.lock_reset_rounded,
          title: 'Create new password',
          subtitle:
              'Your code was accepted. Choose a strong password for your account.',
        ),
        const SizedBox(height: 32),
        const _Label('New Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePass,
          autofocus: true,
          decoration: _inputDec(
            hint: 'Min 8 chars, 1 uppercase, 1 number, 1 special',
            prefix: const Icon(Icons.lock_outline_rounded, color: _kNavy),
            suffix: IconButton(
              icon: Icon(
                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                  color: Colors.blueGrey),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _Label('Confirm Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          decoration: _inputDec(
            hint: 'Re-enter your new password',
            prefix:
                const Icon(Icons.lock_outline_rounded, color: _kNavy),
            suffix: IconButton(
              icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: Colors.blueGrey),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          onSubmitted: (_) => _loading ? null : _resetPassword(),
        ),
        _errorBox(),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Reset Password',
          icon: Icons.check_circle_rounded,
          onPressed: _resetPassword,
        ),
      ],
    );
  }

  // ── Done UI ────────────────────────────────────────────────────────────────
  Widget _buildDoneStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, size: 64, color: Colors.white),
        ),
        const SizedBox(height: 32),
        const Text(
          'Password Reset!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your password has been updated successfully.\nYou can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.blueGrey.shade500, height: 1.6, fontSize: 15),
        ),
        const SizedBox(height: 40),
        _primaryButton(
          label: 'Go to Login',
          icon: Icons.login_rounded,
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/user-login', (_) => false),
        ),
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _header({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kNavy, _kBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kNavy.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey.shade500,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _errorBox() {
    if (_error == null) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 16, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style:
                    TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kNavy.withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE1EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE1EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kNavy, width: 2),
      ),
    );
  }
}

// ── Step indicator ─────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final _Step step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    if (step == _Step.done) return const SizedBox.shrink();
    final index = step.index; // 0, 1, 2
    const labels = ['Email', 'Verify Code', 'New Password'];
    return Container(
      color: const Color(0xFF1A237E),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == index;
          final done = i < index;
          return Expanded(
            child: Row(
              children: [
                // Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? Colors.green
                        : active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                    border: active
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: active
                                  ? const Color(0xFF1A237E)
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                // Label + connector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      if (i < 2)
                        Container(
                          height: 2,
                          margin: const EdgeInsets.only(top: 4, right: 8),
                          decoration: BoxDecoration(
                            color: done
                                ? Colors.green
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF1A237E),
      ),
    );
  }
}
