import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/http_utils.dart';
import '../../core/secure_storage.dart';

const _kNavy = Color(0xFF1A237E);

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  int get _strength {
    final p = _newCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      default:
        return _strength >= 4 ? Colors.green : Colors.grey.shade300;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return _strength >= 4 ? 'Strong' : '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      _showError('You are not logged in.');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.changePassword),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': _currentCtrl.text,
          'newPassword': _newCtrl.text,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        String msg = 'Failed to change password';
        try {
          final body = jsonDecode(res.body);
          if (body['message'] is String) msg = body['message'];
        } catch (_) {}
        _showError(msg);
      }
    } catch (e) {
      if (mounted) _showError(networkErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kNavy, Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Update Password',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Use a strong, unique password',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _FieldLabel('Current Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentCtrl,
                obscureText: !_showCurrent,
                decoration: _inputDecoration(
                  hint: 'Enter your current password',
                  icon: Icons.lock_outline,
                  suffix: _toggleIcon(_showCurrent,
                      () => setState(() => _showCurrent = !_showCurrent)),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 24),

              _FieldLabel('New Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newCtrl,
                obscureText: !_showNew,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  hint: 'Enter a new password',
                  icon: Icons.lock_outline,
                  suffix: _toggleIcon(_showNew,
                      () => setState(() => _showNew = !_showNew)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),

              // Strength bar
              if (_newCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 1; i <= 4; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: i <= _strength
                                ? _strengthColor
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    if (_strengthLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(_strengthLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _strengthColor)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Use 8+ characters with uppercase, numbers & symbols',
                  style: TextStyle(
                      fontSize: 11, color: Colors.blueGrey.shade400),
                ),
              ],

              const SizedBox(height: 24),

              _FieldLabel('Confirm New Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: !_showConfirm,
                decoration: _inputDecoration(
                  hint: 'Re-enter the new password',
                  icon: Icons.lock_outline,
                  suffix: _toggleIcon(_showConfirm,
                      () => setState(() => _showConfirm = !_showConfirm)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Change Password',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/forgot-password'),
                  child: Text(
                    'Forgot your current password?',
                    style: TextStyle(color: Colors.blueGrey.shade500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.blueGrey.shade400, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }

  Widget _toggleIcon(bool visible, VoidCallback onTap) {
    return IconButton(
      icon: Icon(visible ? Icons.visibility : Icons.visibility_off,
          color: Colors.blueGrey.shade400, size: 20),
      onPressed: onTap,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF37474F)));
  }
}
