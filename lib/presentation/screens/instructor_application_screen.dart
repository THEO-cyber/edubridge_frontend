import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/http_utils.dart';
import '../../core/secure_storage.dart';

const _kPrimary = Color(0xFF1A237E);

class InstructorApplicationScreen extends StatefulWidget {
  const InstructorApplicationScreen({super.key});

  @override
  State<InstructorApplicationScreen> createState() =>
      _InstructorApplicationScreenState();
}

class _InstructorApplicationScreenState
    extends State<InstructorApplicationScreen> {
  bool _loadingStatus = true;
  Map<String, dynamic>? _existingApp;
  String? _statusError;

  // Form controllers
  final _expertiseCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _category = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _expertiseCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    _linkedinCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _checkStatus() async {
    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });
    try {
      final h = await _authHeaders();
      final res = await apiGet(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.myInstructorApplication}'),
        headers: h,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final app = data is Map
            ? (data['data'] ?? data['application'] ?? data)
            : null;
        if (app is Map<String, dynamic> && app.isNotEmpty) {
          setState(() {
            _existingApp = app;
            _loadingStatus = false;
          });
          return;
        }
      }
      // 404 or empty = no application yet
      setState(() {
        _existingApp = null;
        _loadingStatus = false;
      });
    } catch (e) {
      setState(() {
        _statusError = e.toString().replaceFirst('Exception: ', '');
        _loadingStatus = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_expertiseCtrl.text.trim().isEmpty ||
        _bioCtrl.text.trim().isEmpty ||
        _experienceCtrl.text.trim().isEmpty) {
      _snack('Expertise, bio and experience are required', Colors.orange);
      return;
    }

    setState(() => _submitting = true);
    try {
      final h = await _authHeaders();
      final res = await apiPost(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.instructorApplication}'),
        headers: h,
        body: jsonEncode({
          'expertise': _expertiseCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
          'experience': _experienceCtrl.text.trim(),
          if (_category.isNotEmpty) 'category': _category,
          if (_linkedinCtrl.text.trim().isNotEmpty)
            'linkedinUrl': _linkedinCtrl.text.trim(),
          if (_websiteCtrl.text.trim().isNotEmpty)
            'websiteUrl': _websiteCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Application submitted! We will review it within 2-3 business days.', Colors.green);
        await _checkStatus();
      } else {
        String msg = 'Failed to submit application';
        try {
          final b = jsonDecode(res.body);
          if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
        } catch (_) {}
        _snack(msg, Colors.red);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Become an Instructor'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (_existingApp != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _checkStatus),
        ],
      ),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _statusError != null
              ? _ErrorView(error: _statusError!, onRetry: _checkStatus)
              : _existingApp != null
                  ? _StatusView(app: _existingApp!, onRefresh: _checkStatus)
                  : _ApplicationForm(
                      expertiseCtrl: _expertiseCtrl,
                      bioCtrl: _bioCtrl,
                      experienceCtrl: _experienceCtrl,
                      linkedinCtrl: _linkedinCtrl,
                      websiteCtrl: _websiteCtrl,
                      category: _category,
                      onCategoryChanged: (v) => setState(() => _category = v),
                      submitting: _submitting,
                      onSubmit: _submit,
                    ),
    );
  }
}

// ── Status view ───────────────────────────────────────────────────────────────

class _StatusView extends StatelessWidget {
  final Map<String, dynamic> app;
  final VoidCallback onRefresh;
  const _StatusView({required this.app, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final status = (app['status'] ?? 'pending').toString().toLowerCase();
    final submittedAt = (app['createdAt'] ?? app['submittedAt'] ?? '').toString().split('T').first;
    final reviewedAt = (app['reviewedAt'] ?? app['updatedAt'] ?? '').toString().split('T').first;
    final reason = (app['rejectionReason'] ?? app['reason'] ?? '').toString();

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusMessage;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusTitle = 'Application Approved!';
        statusMessage = 'Congratulations! Your instructor application has been approved. '
            'You can now create and publish courses.';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusTitle = 'Application Rejected';
        statusMessage = 'Unfortunately your application was not approved at this time. '
            'You may reapply after 30 days.';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        statusTitle = 'Application Under Review';
        statusMessage = 'Your application is being reviewed by our team. '
            'This typically takes 2–3 business days.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Status card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Icon(statusIcon, size: 64, color: statusColor),
              const SizedBox(height: 16),
              Text(statusTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: statusColor)),
              const SizedBox(height: 10),
              Text(statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.5)),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Reason: $reason',
                        style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
                  ]),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Timeline
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _TimelineItem(
                icon: Icons.send,
                color: Colors.blue,
                label: 'Application submitted',
                date: submittedAt,
              ),
              _TimelineItem(
                icon: status == 'pending' ? Icons.schedule : Icons.rate_review,
                color: status == 'pending' ? Colors.orange : statusColor,
                label: status == 'pending' ? 'Under review' : 'Review completed',
                date: status == 'pending' ? null : reviewedAt,
              ),
              if (status == 'approved')
                const _TimelineItem(
                  icon: Icons.school,
                  color: Colors.green,
                  label: 'Ready to create courses',
                  date: null,
                ),
            ]),
          ),
        ),

        // Application details
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Application',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _DetailRow('Expertise', app['expertise'] ?? ''),
              if ((app['category'] ?? '').toString().isNotEmpty)
                _DetailRow('Category', app['category'].toString()),
              _DetailRow('Experience', app['experience'] ?? ''),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? date;
  const _TimelineItem({required this.icon, required this.color, required this.label, this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        if (date != null && date!.isNotEmpty)
          Text(date!, style: const TextStyle(fontSize: 11, color: Colors.black38)),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

// ── Application form ──────────────────────────────────────────────────────────

class _ApplicationForm extends StatelessWidget {
  final TextEditingController expertiseCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController experienceCtrl;
  final TextEditingController linkedinCtrl;
  final TextEditingController websiteCtrl;
  final String category;
  final void Function(String) onCategoryChanged;
  final bool submitting;
  final VoidCallback onSubmit;

  const _ApplicationForm({
    required this.expertiseCtrl,
    required this.bioCtrl,
    required this.experienceCtrl,
    required this.linkedinCtrl,
    required this.websiteCtrl,
    required this.category,
    required this.onCategoryChanged,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimary, Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.school, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            const Text('Apply to Become an Instructor',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Share your knowledge and earn revenue by creating courses on EduBridge.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Form card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              _field(expertiseCtrl, 'Area of Expertise *',
                  hint: 'e.g. Machine Learning, Web Development, Photography'),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: category.isEmpty ? null : category,
                decoration: const InputDecoration(
                    labelText: 'Teaching Category',
                    border: OutlineInputBorder(),
                    isDense: true),
                onChanged: (v) => onCategoryChanged(v ?? ''),
                hint: const Text('Select a category (optional)'),
                items: const [
                  DropdownMenuItem(value: 'technology', child: Text('Technology')),
                  DropdownMenuItem(value: 'business', child: Text('Business')),
                  DropdownMenuItem(value: 'design', child: Text('Design')),
                  DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                  DropdownMenuItem(value: 'science', child: Text('Science')),
                  DropdownMenuItem(value: 'arts', child: Text('Arts & Humanities')),
                  DropdownMenuItem(value: 'language', child: Text('Language')),
                  DropdownMenuItem(value: 'health', child: Text('Health & Fitness')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
              ),
              const SizedBox(height: 14),

              _field(bioCtrl, 'Professional Bio *',
                  hint: 'Tell students about your background and achievements…',
                  maxLines: 4),
              const SizedBox(height: 14),

              _field(experienceCtrl, 'Teaching / Work Experience *',
                  hint: 'Describe your experience teaching or working in your field…',
                  maxLines: 4),
              const SizedBox(height: 14),

              _field(linkedinCtrl, 'LinkedIn Profile URL',
                  hint: 'https://linkedin.com/in/yourprofile'),
              const SizedBox(height: 14),

              _field(websiteCtrl, 'Personal / Portfolio Website',
                  hint: 'https://yourwebsite.com'),
              const SizedBox(height: 8),

              Text(
                '* Required fields',
                style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: submitting ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Application',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // What happens next
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('What happens next?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _NextStep('1', 'Submit your application with your expertise and bio'),
              _NextStep('2', 'Our team reviews your application within 2-3 business days'),
              _NextStep('3', 'You receive an email with the decision'),
              _NextStep('4', 'Approved instructors gain access to the course creation tools'),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {String? hint, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final String number;
  final String text;
  const _NextStep(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: _kPrimary,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
      ]),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
