import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';

class EmailPreferencesScreen extends StatefulWidget {
  const EmailPreferencesScreen({super.key});

  @override
  State<EmailPreferencesScreen> createState() =>
      _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState extends State<EmailPreferencesScreen> {
  String? _token;
  bool _loading = true;
  bool _saving = false;

  final Map<String, bool> _prefs = {
    'marketingEmails': false,
    'courseUpdates': true,
    'sessionReminders': true,
    'newEnrollments': true,
    'paymentReceipts': true,
    'certificateIssued': true,
    'weeklyDigest': false,
  };

  final Map<String, String> _labels = {
    'marketingEmails': 'Marketing & Promotions',
    'courseUpdates': 'Course Updates',
    'sessionReminders': 'Live Session Reminders',
    'newEnrollments': 'New Enrollments',
    'paymentReceipts': 'Payment Receipts',
    'certificateIssued': 'Certificate Issued',
    'weeklyDigest': 'Weekly Digest',
  };

  final Map<String, String> _descriptions = {
    'marketingEmails': 'Promotions, discounts, and platform news',
    'courseUpdates': 'New content and instructor announcements',
    'sessionReminders': 'Upcoming live session notifications',
    'newEnrollments': 'When students enroll in your courses',
    'paymentReceipts': 'Payment and refund confirmations',
    'certificateIssued': 'When you earn a certificate',
    'weeklyDigest': 'Summary of your weekly activity',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _token = await SecureStorage.getToken();
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.emailPreferences),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            for (final key in _prefs.keys) {
              if (data[key] is bool) _prefs[key] = data[key];
            }
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_token == null) return;
    setState(() => _saving = true);
    try {
      final res = await http.patch(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.emailPreferences),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(_prefs),
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Preferences saved'),
              backgroundColor: Colors.green),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save preferences'),
              backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Preferences'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionHeader('Notifications'),
                ..._prefs.keys.map((key) => _buildToggle(key)),
                const SizedBox(height: 16),
                Text(
                  'You can unsubscribe from all marketing emails at any time via the link in any email we send.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.blueGrey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                letterSpacing: 0.5)),
      );

  Widget _buildToggle(String key) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        color: Colors.white,
        child: SwitchListTile(
          title: Text(_labels[key] ?? key,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14)),
          subtitle: Text(_descriptions[key] ?? '',
              style:
                  TextStyle(fontSize: 12, color: Colors.blueGrey.shade500)),
          value: _prefs[key] ?? false,
          activeThumbColor: const Color(0xFF1A237E),
          onChanged: (v) => setState(() => _prefs[key] = v),
        ),
      );
}
