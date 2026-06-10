import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/admin_remote_data_source.dart';

const _kNavy = Color(0xFF1A237E);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
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
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded), text: 'Instructors'),
            Tab(icon: Icon(Icons.rate_review_rounded), text: 'Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _InstructorsTab(),
          _ReviewsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Instructors tab
// ─────────────────────────────────────────────────────────────────────────────

class _InstructorsTab extends StatefulWidget {
  const _InstructorsTab();

  @override
  State<_InstructorsTab> createState() => _InstructorsTabState();
}

class _InstructorsTabState extends State<_InstructorsTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _instructors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await SecureStorage.getToken() ?? '';
      final list = await _ds.fetchInstructors(token);
      if (mounted) setState(() { _instructors = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _suspend(Map<String, dynamic> inst) async {
    final reason = await _promptText(
      context,
      title: 'Suspend Instructor',
      hint: 'Reason for suspension…',
      confirmLabel: 'Suspend',
      confirmColor: Colors.orange,
    );
    if (reason == null || reason.isEmpty) return;
    await _runAction(() async {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.suspendInstructor(inst['id'].toString(), reason, token);
    }, 'Instructor suspended');
  }

  Future<void> _warn(Map<String, dynamic> inst) async {
    final msg = await _promptText(
      context,
      title: 'Send Warning',
      hint: 'Warning message…',
      confirmLabel: 'Send Warning',
      confirmColor: Colors.amber[800]!,
    );
    if (msg == null || msg.isEmpty) return;
    await _runAction(() async {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.warnInstructor(inst['id'].toString(), msg, token);
    }, 'Warning sent');
  }

  Future<void> _delete(Map<String, dynamic> inst) async {
    final name = _instName(inst);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Instructor'),
        content: Text(
          'This will archive all courses by $name and deactivate their account. '
          'Students keep their progress. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() async {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.deleteInstructor(inst['id'].toString(), token);
    }, '$name has been removed');
    _load();
  }

  Future<void> _runAction(Future<void> Function() action, String successMsg) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _instName(Map<String, dynamic> inst) {
    final first = (inst['firstName'] ?? inst['first_name'] ?? '').toString();
    final last = (inst['lastName'] ?? inst['last_name'] ?? '').toString();
    final username = (inst['username'] ?? '').toString();
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : (username.isNotEmpty ? username : 'Instructor');
  }

  bool _isActive(Map<String, dynamic> inst) =>
      inst['isActive'] == true || inst['active'] == true;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kNavy));
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      ));
    }
    if (_instructors.isEmpty) {
      return const Center(child: Text('No instructors found.', style: TextStyle(color: Colors.black45)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _instructors.length,
        itemBuilder: (_, i) {
          final inst = _instructors[i];
          final name = _instName(inst);
          final active = _isActive(inst);
          final email = (inst['email'] ?? '').toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              leading: CircleAvatar(
                backgroundColor: active ? _kNavy : Colors.grey,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(children: [
                Expanded(child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active ? 'Active' : 'Suspended',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ]),
              subtitle: email.isNotEmpty
                  ? Text(email, style: const TextStyle(fontSize: 12, color: Colors.black54))
                  : null,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'suspend') _suspend(inst);
                  if (v == 'warn') _warn(inst);
                  if (v == 'delete') _delete(inst);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'warn', child: _MenuItem(Icons.warning_amber_rounded, 'Send Warning', Colors.amber)),
                  const PopupMenuItem(value: 'suspend', child: _MenuItem(Icons.block_rounded, 'Suspend', Colors.orange)),
                  const PopupMenuItem(value: 'delete', child: _MenuItem(Icons.delete_rounded, 'Remove Account', Colors.red)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews tab
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  String? _error;

  int? _filterRating;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await SecureStorage.getToken() ?? '';
      final list = await _ds.fetchAllReviews(token, rating: _filterRating);
      if (mounted) setState(() { _reviews = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _reviewerName(Map<String, dynamic> r) {
    final u = r['user'] as Map<String, dynamic>?;
    if (u == null) return 'Student';
    final username = (u['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;
    return '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim().isNotEmpty
        ? '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim()
        : 'Student';
  }

  String _courseTitle(Map<String, dynamic> r) {
    final c = r['course'] as Map<String, dynamic>?;
    return (c?['title'] ?? r['courseTitle'] ?? '').toString();
  }

  String _date(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter bar
      Container(
        color: const Color(0xFFF0F4FF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const Text('Filter by rating:', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterChip(label: 'All', selected: _filterRating == null,
                    onTap: () { setState(() => _filterRating = null); _load(); }),
                ...List.generate(5, (i) {
                  final star = 5 - i;
                  return _FilterChip(
                    label: '$star ★',
                    selected: _filterRating == star,
                    onTap: () { setState(() => _filterRating = star); _load(); },
                  );
                }),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kNavy))
            : _error != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]),
                  ))
                : _reviews.isEmpty
                    ? const Center(child: Text('No reviews found.', style: TextStyle(color: Colors.black45)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reviews.length,
                          itemBuilder: (_, i) {
                            final r = _reviews[i];
                            final reviewer = _reviewerName(r);
                            final course = _courseTitle(r);
                            final rating = (r['rating'] as num?)?.toInt() ?? 0;
                            final content = (r['content'] ?? r['comment'] ?? '').toString().trim();
                            final date = _date(r['createdAt']?.toString());
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(reviewer,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    Row(children: List.generate(5, (j) => Icon(
                                      j < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber, size: 13,
                                    ))),
                                    const SizedBox(width: 6),
                                    Text(date, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                                  ]),
                                  if (course.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(course, style: const TextStyle(color: _kNavy, fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                  if (content.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(content, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                                  ],
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  required Color confirmColor,
}) async {
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, ctrl.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(color: color)),
  ]);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? _kNavy : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? _kNavy : Colors.black26),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          )),
    ),
  );
}
