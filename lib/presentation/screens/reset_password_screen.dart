import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;
  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenCtrl.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (token.isEmpty) {
      setState(() => _error = 'Please paste the reset token from your email link');
      return;
    }
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
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'newPassword': password, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _done = true);
      } else {
        String msg = 'Failed to reset password';
        try {
          final b = jsonDecode(response.body);
          if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
        } catch (_) {}
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Reset Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _done ? _buildDoneView(context) : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                size: 48, color: Color(0xFF1A237E)),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Create new password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Open the reset link from your email,\ncopy the token value after "token=" in the URL,\nthen paste it below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey.shade500, height: 1.5, fontSize: 13),
          ),
        ),
        const SizedBox(height: 28),

        // Token field
        const Text(
          'Reset Token',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A237E)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tokenCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Paste the token from your email link here',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Paste from clipboard',
              icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF1A237E)),
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  final pasted = data!.text!.trim();
                  // Extract token if user pasted the full URL
                  final uri = Uri.tryParse(pasted);
                  final extracted = uri?.queryParameters['token'] ?? pasted;
                  _tokenCtrl.text = extracted;
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: You can also paste the full reset link — the app will extract the token automatically.',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // New password
        const Text(
          'New Password',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A237E)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Min 8 characters',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm password
        const Text(
          'Confirm Password',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A237E)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'Re-enter your new password',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          onSubmitted: (_) => _loading ? null : _submit(),
        ),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoneView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              size: 64, color: Colors.green),
        ),
        const SizedBox(height: 24),
        const Text(
          'Password Reset!',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
        ),
        const SizedBox(height: 12),
        Text(
          'Your password has been updated successfully.\nYou can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey.shade500, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/user-login', (r) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Login',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
