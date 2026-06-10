import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  String? _token;
  bool _loading = true;
  bool _twoFaEnabled = false;

  // Enable flow
  String? _secret;
  String? _otpAuthUri;
  final _codeCtrl = TextEditingController();
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _token = await SecureStorage.getToken();
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }
    // Check current 2FA status from profile
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.me),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final user = jsonDecode(res.body);
        _twoFaEnabled = user['twoFactorEnabled'] ?? false;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startEnable() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.twoFaEnable),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _secret = data['secret'];
          _otpAuthUri = data['otpAuthUri'];
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _confirmEnable() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code from your app')),
      );
      return;
    }
    setState(() => _confirming = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.twoFaConfirm),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'totpCode': code}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _twoFaEnabled = true;
          _secret = null;
          _otpAuthUri = null;
          _codeCtrl.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('2FA enabled successfully'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid code. Please try again.'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _confirming = false);
  }

  Future<void> _disable() async {
    final codeCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your current authenticator code to disable 2FA.'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: '6-digit code',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.twoFaDisable),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'totpCode': codeCtrl.text.trim()}),
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        setState(() => _twoFaEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA disabled')),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _twoFaEnabled
                  ? _buildEnabledView()
                  : _secret != null
                      ? _buildSetupView()
                      : _buildDisabledView(),
            ),
    );
  }

  Widget _buildDisabledView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security, size: 56, color: Color(0xFF1A237E)),
          const SizedBox(height: 20),
          const Text('Secure your account',
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Two-factor authentication adds an extra layer of security to your account. '
            'After enabling, you will need a code from your authenticator app each time you log in.',
            style:
                TextStyle(color: Colors.blueGrey.shade600, height: 1.6),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startEnable,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enable 2FA',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );

  Widget _buildSetupView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set up authenticator',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
              '1. Install Google Authenticator or Authy on your phone.\n'
              '2. Scan the QR code or manually enter the secret key.\n'
              '3. Enter the 6-digit code to confirm.'),
          const SizedBox(height: 24),
          if (_secret != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manual entry key:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_secret!,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                letterSpacing: 2)),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _secret!));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                  if (_otpAuthUri != null) ...[
                    const SizedBox(height: 8),
                    Text(_otpAuthUri!,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade400),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '6-digit verification code',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirming ? null : _confirmEnable,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _confirming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Enable',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );

  Widget _buildEnabledView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user,
                    color: Colors.green, size: 36),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2FA is Active',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Your account is protected',
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Two-factor authentication is currently enabled. '
            'You will be asked for a code from your authenticator app on each login.',
            style:
                TextStyle(color: Colors.blueGrey.shade600, height: 1.6),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _disable,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Disable 2FA',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );
}
