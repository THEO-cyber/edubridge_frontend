import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/http_utils.dart';
import '../../core/secure_storage.dart';

const _kPrimary = Color(0xFF1A237E);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Submit Report'),
            Tab(text: 'My Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _SubmitTab(),
          _MyReportsTab(),
        ],
      ),
    );
  }
}

// ── Submit report tab ─────────────────────────────────────────────────────────

class _SubmitTab extends StatefulWidget {
  const _SubmitTab();

  @override
  State<_SubmitTab> createState() => _SubmitTabState();
}

class _SubmitTabState extends State<_SubmitTab> {
  final _descCtrl = TextEditingController();
  final _targetIdCtrl = TextEditingController();
  String _type = 'course';
  String _reason = 'inappropriate_content';
  bool _submitting = false;

  static const _types = [
    ('course', 'Course'),
    ('user', 'User'),
    ('review', 'Review'),
    ('instructor', 'Instructor'),
  ];

  static const _reasons = [
    ('inappropriate_content', 'Inappropriate content'),
    ('spam', 'Spam'),
    ('misleading', 'Misleading information'),
    ('copyright', 'Copyright violation'),
    ('harassment', 'Harassment'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _targetIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_targetIdCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _snack('Please fill in all required fields', Colors.orange);
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final res = await apiPost(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'targetType': _type,
          'targetId': _targetIdCtrl.text.trim(),
          'reason': _reason,
          'description': _descCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _descCtrl.clear();
        _targetIdCtrl.clear();
        _snack('Report submitted. Our team will review it shortly.', Colors.green);
      } else {
        String msg = 'Failed to submit report';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _InfoBanner(),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Report Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                    labelText: 'What are you reporting?',
                    border: OutlineInputBorder(),
                    isDense: true),
                onChanged: (v) => setState(() => _type = v!),
                items: _types
                    .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                    .toList(),
              ),
              const SizedBox(height: 14),

              // Target ID
              TextField(
                controller: _targetIdCtrl,
                decoration: InputDecoration(
                  labelText: '${_typeLabel()} ID',
                  hintText: 'Paste the ID of the ${_typeLabel().toLowerCase()} you are reporting',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),

              // Reason
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                    labelText: 'Reason', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) => setState(() => _reason = v!),
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                    .toList(),
              ),
              const SizedBox(height: 14),

              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Provide details about the issue…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Report',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  String _typeLabel() {
    return _types.firstWhere((t) => t.$1 == _type, orElse: () => ('', 'Item')).$2;
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Help keep EduBridge safe',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              const SizedBox(height: 4),
              Text(
                'Reports are reviewed by our moderation team within 24-48 hours. '
                'False reports may result in account restrictions.',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700, height: 1.4),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── My reports tab ────────────────────────────────────────────────────────────

class _MyReportsTab extends StatefulWidget {
  const _MyReportsTab();

  @override
  State<_MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends State<_MyReportsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final res = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myReports}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List
            ? data
            : (data['data'] ?? data['reports'] ?? data['items'] ?? []);
        _reports =
            List<Map<String, dynamic>>.from(list is List ? list : []);
      } else {
        throw Exception('Failed to load reports (${res.statusCode})');
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_reports.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.flag_outlined, size: 56, color: Colors.blueGrey.shade200),
          const SizedBox(height: 12),
          Text("You haven't submitted any reports",
              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Use the Submit tab to report issues',
              style: TextStyle(color: Colors.black38, fontSize: 13)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (_, i) => _ReportTile(report: _reports[i]),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final reason = _label(report['reason'] ?? '');
    final targetType = _capitalize((report['targetType'] ?? 'item').toString());
    final status = (report['status'] ?? 'open').toString().toLowerCase();
    final date = (report['createdAt'] ?? '').toString().split('T').first;
    final desc = (report['description'] ?? '').toString();
    final note = (report['resolutionNote'] ?? report['note'] ?? '').toString();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'dismissed':
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(reason,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('$targetType report${date.isNotEmpty ? ' • $date' : ''}',
              style: const TextStyle(fontSize: 11, color: Colors.black45)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc,
                style: const TextStyle(fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.admin_panel_settings, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Expanded(child: Text('Admin note: $note',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  String _label(String raw) {
    final map = {
      'inappropriate_content': 'Inappropriate Content',
      'spam': 'Spam',
      'misleading': 'Misleading Information',
      'copyright': 'Copyright Violation',
      'harassment': 'Harassment',
      'other': 'Other Issue',
    };
    return map[raw] ?? _capitalize(raw);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
}
