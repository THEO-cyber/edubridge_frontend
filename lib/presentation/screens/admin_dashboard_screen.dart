import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../core/money.dart';
import '../../data/datasources/admin_remote_data_source.dart';

const _kNavy = Color(0xFF1A237E);
const _kBg = Color(0xFFF5F6FA);

// ── Shared helpers ─────────────────────────────────────────────────────────────

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  Color confirmColor = _kNavy,
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
        decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, ctrl.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

Widget _errorView(String error, VoidCallback onRetry) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );

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

// ── Root dashboard ─────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _tabDefs = [
    (Icons.dashboard_rounded, 'Stats'),
    (Icons.people_alt_rounded, 'Users'),
    (Icons.menu_book_rounded, 'Courses'),
    (Icons.category_rounded, 'Categories'),
    (Icons.school_rounded, 'Instructors'),
    (Icons.assignment_ind_rounded, 'Applications'),
    (Icons.rate_review_rounded, 'Reviews'),
    (Icons.flag_rounded, 'Reports'),
    (Icons.notifications_rounded, 'Notify'),
    (Icons.videocam_rounded, 'Videos'),
    (Icons.local_offer_rounded, 'Coupons'),
    (Icons.account_balance_wallet_rounded, 'Payouts'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabDefs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabAlignment: TabAlignment.start,
          tabs: _tabDefs
              .map((d) => Tab(icon: Icon(d.$1, size: 18), text: d.$2))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _StatsTab(),
          _UsersTab(),
          _CoursesTab(),
          _CategoriesTab(),
          _InstructorsTab(),
          _ApplicationsTab(),
          _ReviewsTab(),
          _ReportsTab(),
          _NotificationsTab(),
          _VideosTab(),
          _CouponsTab(),
          _PayoutsAdminTab(),
        ],
      ),
    );
  }
}

// ── Stats tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  final _ds = AdminRemoteDataSource();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _activity = [];

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
      final token = await SecureStorage.getToken() ?? '';
      final s = await _ds.fetchStats(token);
      final a = await _ds.fetchActivity(token);
      if (mounted) {
        setState(() {
        _stats = s;
        _activity = a;
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kNavy));
    if (_error != null) return _errorView(_error!, _load);

    final cards = [
      ('Total Users', _stats['totalUsers'] ?? _stats['users'] ?? 0, Icons.people, Colors.blue),
      ('Courses', _stats['totalCourses'] ?? _stats['courses'] ?? 0, Icons.menu_book, Colors.green),
      ('Revenue', Money.xaf(_stats['totalRevenue'] ?? 0), Icons.attach_money, Colors.orange),
      ('Enrollments', _stats['totalEnrollments'] ?? _stats['enrollments'] ?? 0, Icons.school, Colors.purple),
      ('Instructors', _stats['totalInstructors'] ?? _stats['instructors'] ?? 0, Icons.person_pin, Colors.teal),
      ('Students', _stats['totalStudents'] ?? _stats['students'] ?? 0, Icons.people_alt, Colors.indigo),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: cards.map((c) => _StatCard(
              label: c.$1,
              value: c.$2.toString(),
              icon: c.$3,
              color: c.$4,
            )).toList(),
          ),
          if (_activity.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Recent Activity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ..._activity.take(15).map((a) => _ActivityTile(item: a)),
          ],
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        ])),
      ]),
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final action = (item['action'] ?? item['type'] ?? 'Activity').toString();
    final desc = (item['description'] ?? item['detail'] ?? '').toString();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.circle, size: 8, color: _kNavy),
      title: Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: desc.isNotEmpty ? Text(desc, style: const TextStyle(fontSize: 12)) : null,
    );
  }
}

// ── Users tab ──────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _role = '';
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      _users = [];
    }
    setState(() => _loading = true);
    try {
      final token = await SecureStorage.getToken() ?? '';
      final data = await _ds.fetchUsers(token,
          page: _page, role: _role.isEmpty ? null : _role,
          search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
      final list = data['data'] ?? data['users'] ?? data['items'] ?? [];
      final items = List<Map<String, dynamic>>.from(list is List ? list : []);
      if (mounted) {
        setState(() {
        _users = reset ? items : [..._users, ...items];
        _hasMore = items.length >= 20;
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final id = (user['id'] ?? user['_id'] ?? '').toString();
    final active = user['isActive'] == true;
    try {
      final token = await SecureStorage.getToken() ?? '';
      if (active) {
        await _ds.deactivateUser(id, token);
      } else {
        await _ds.activateUser(id, token);
      }
      _snack(active ? 'User deactivated' : 'User activated', Colors.green);
      await _load(reset: true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    }
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final name = _userName(user);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      final id = (user['id'] ?? user['_id'] ?? '').toString();
      await _ds.deleteUser(id, token);
      _snack('$name deleted', Colors.green);
      await _load(reset: true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    }
  }

  String _userName(Map<String, dynamic> u) {
    final f = (u['firstName'] ?? '').toString();
    final l = (u['lastName'] ?? '').toString();
    final full = '$f $l'.trim();
    return full.isNotEmpty ? full : (u['email'] ?? 'User').toString();
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(reset: true),
              decoration: InputDecoration(
                hintText: 'Search users…',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _role.isEmpty ? null : _role,
            hint: const Text('Role'),
            onChanged: (v) {
              setState(() => _role = v ?? '');
              _load(reset: true);
            },
            items: const [
              DropdownMenuItem(value: '', child: Text('All')),
              DropdownMenuItem(value: 'student', child: Text('Student')),
              DropdownMenuItem(value: 'instructor', child: Text('Instructor')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
          ),
        ]),
      ),
      Expanded(
        child: _loading && _users.isEmpty
            ? const Center(child: CircularProgressIndicator(color: _kNavy))
            : _error != null
                ? _errorView(_error!, () => _load(reset: true))
                : _users.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : RefreshIndicator(
                        onRefresh: () => _load(reset: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _users.length + (_hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _users.length) {
                              return Center(
                                child: TextButton(
                                  onPressed: () {
                                    _page++;
                                    _load();
                                  },
                                  child: const Text('Load more'),
                                ),
                              );
                            }
                            final u = _users[i];
                            final name = _userName(u);
                            final email = (u['email'] ?? '').toString();
                            final role = (u['role'] ?? '').toString().toLowerCase();
                            final active = u['isActive'] == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: active ? _kNavy : Colors.grey,
                                  child: Text(name[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 11)),
                                  Wrap(spacing: 6, children: [
                                    _Chip(role, Colors.blue),
                                    _Chip(active ? 'Active' : 'Inactive', active ? Colors.green : Colors.red),
                                  ]),
                                ]),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'toggle') _toggleActive(u);
                                    if (v == 'delete') _delete(u);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: _MenuItem(
                                        active ? Icons.block : Icons.check_circle,
                                        active ? 'Deactivate' : 'Activate',
                                        active ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                    const PopupMenuItem(value: 'delete',
                                        child: _MenuItem(Icons.delete, 'Delete', Colors.red)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }
}

// ── Courses tab ───────────────────────────────────────────────────────────────

class _CoursesTab extends StatefulWidget {
  const _CoursesTab();

  @override
  State<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<_CoursesTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await SecureStorage.getToken() ?? '';
      final data = await _ds.fetchCourses(token, status: _status.isEmpty ? null : _status);
      final list = data['data'] ?? data['courses'] ?? data['items'] ?? [];
      if (mounted) {
        setState(() {
        _courses = List<Map<String, dynamic>>.from(list is List ? list : []);
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _approve(Map<String, dynamic> c) async {
    final id = (c['id'] ?? c['_id'] ?? '').toString();
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.approveCourse(id, token);
      _snack('Course approved', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<void> _reject(Map<String, dynamic> c) async {
    final reason = await _promptText(context, title: 'Reject Course', hint: 'Reason…', confirmLabel: 'Reject', confirmColor: Colors.red);
    if (reason == null || reason.isEmpty) return;
    final id = (c['id'] ?? c['_id'] ?? '').toString();
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.rejectCourse(id, reason, token);
      _snack('Course rejected', Colors.orange);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<void> _suspend(Map<String, dynamic> c) async {
    final reason = await _promptText(context, title: 'Suspend Course', hint: 'Reason…', confirmLabel: 'Suspend', confirmColor: Colors.orange);
    if (reason == null || reason.isEmpty) return;
    final id = (c['id'] ?? c['_id'] ?? '').toString();
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.suspendCourse(id, reason, token);
      _snack('Course suspended', Colors.orange);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _StatusFilter(
        value: _status,
        options: const ['', 'pending', 'published', 'rejected', 'suspended'],
        labels: const ['All', 'Pending', 'Published', 'Rejected', 'Suspended'],
        onChanged: (v) { setState(() => _status = v); _load(); },
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kNavy))
            : _error != null ? _errorView(_error!, _load)
            : _courses.isEmpty
                ? const Center(child: Text('No courses found.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _courses.length,
                      itemBuilder: (_, i) {
                        final c = _courses[i];
                        final title = (c['title'] ?? 'Untitled').toString();
                        final status = (c['status'] ?? '').toString().toLowerCase();
                        final inst = c['instructor'];
                        final instName = inst is Map
                            ? '${inst['firstName'] ?? ''} ${inst['lastName'] ?? ''}'.trim()
                            : '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.menu_book, color: _kNavy),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (instName.isNotEmpty) Text(instName, style: const TextStyle(fontSize: 11)),
                              _Chip(status, _statusColor(status)),
                            ]),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'approve') _approve(c);
                                if (v == 'reject') _reject(c);
                                if (v == 'suspend') _suspend(c);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'approve', child: _MenuItem(Icons.check_circle, 'Approve', Colors.green)),
                                const PopupMenuItem(value: 'reject', child: _MenuItem(Icons.cancel, 'Reject', Colors.red)),
                                const PopupMenuItem(value: 'suspend', child: _MenuItem(Icons.block, 'Suspend', Colors.orange)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    ]);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'published': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'suspended': return Colors.grey;
      default: return Colors.blue;
    }
  }
}

// ── Categories tab ─────────────────────────────────────────────────────────────

class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _cats = [];
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
      final list = await _ds.fetchCategories(token);
      if (mounted) setState(() { _cats = list; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _create() async {
    await _catDialog();
  }

  Future<void> _edit(Map<String, dynamic> cat) async {
    final id = (cat['id'] ?? cat['_id'] ?? '').toString();
    await _catDialog(cat: cat, id: id);
  }

  Future<void> _catDialog({Map<String, dynamic>? cat, String? id}) async {
    final nameCtrl = TextEditingController(text: (cat?['name'] ?? '').toString());
    final descCtrl = TextEditingController(text: (cat?['description'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cat == null ? 'Create Category' : 'Edit Category'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final token = await SecureStorage.getToken() ?? '';
      if (id != null) {
        await _ds.updateCategory(id, nameCtrl.text.trim(), descCtrl.text.trim(), token);
      } else {
        await _ds.createCategory(nameCtrl.text.trim(), descCtrl.text.trim(), token);
      }
      _snack(id != null ? 'Category updated' : 'Category created', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<void> _delete(Map<String, dynamic> cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      final id = (cat['id'] ?? cat['_id'] ?? '').toString();
      await _ds.deleteCategory(id, token);
      _snack('Category deleted', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
        onPressed: _create,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kNavy))
          : _error != null
              ? _errorView(_error!, _load)
              : _cats.isEmpty
                  ? const Center(child: Text('No categories yet.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cats.length,
                        itemBuilder: (_, i) {
                          final c = _cats[i];
                          final name = (c['name'] ?? '').toString();
                          final desc = (c['description'] ?? '').toString();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: _kNavy,
                                child: Icon(Icons.category, color: Colors.white, size: 18),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: desc.isNotEmpty ? Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _edit(c)),
                                IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _delete(c)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Instructors tab ───────────────────────────────────────────────────────────

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
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _suspend(Map<String, dynamic> inst) async {
    final reason = await _promptText(context, title: 'Suspend Instructor', hint: 'Reason…', confirmLabel: 'Suspend', confirmColor: Colors.orange);
    if (reason == null || reason.isEmpty) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.suspendInstructor((inst['id'] ?? inst['_id'] ?? '').toString(), reason, token);
      _snack('Instructor suspended', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<void> _warn(Map<String, dynamic> inst) async {
    final msg = await _promptText(context, title: 'Send Warning', hint: 'Warning message…', confirmLabel: 'Send', confirmColor: Colors.amber.shade800);
    if (msg == null || msg.isEmpty) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.warnInstructor((inst['id'] ?? inst['_id'] ?? '').toString(), msg, token);
      _snack('Warning sent', Colors.green);
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<void> _delete(Map<String, dynamic> inst) async {
    final name = _name(inst);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Instructor'),
        content: Text('Remove $name? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.deleteInstructor((inst['id'] ?? inst['_id'] ?? '').toString(), token);
      _snack('$name removed', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  String _name(Map<String, dynamic> inst) {
    final f = (inst['firstName'] ?? '').toString();
    final l = (inst['lastName'] ?? '').toString();
    final full = '$f $l'.trim();
    return full.isNotEmpty ? full : (inst['email'] ?? 'Instructor').toString();
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kNavy));
    if (_error != null) return _errorView(_error!, _load);
    if (_instructors.isEmpty) return const Center(child: Text('No instructors found.'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _instructors.length,
        itemBuilder: (_, i) {
          final inst = _instructors[i];
          final name = _name(inst);
          final active = inst['isActive'] == true;
          final email = (inst['email'] ?? '').toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: active ? _kNavy : Colors.grey,
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                _Chip(active ? 'Active' : 'Suspended', active ? Colors.green : Colors.red),
              ]),
              subtitle: email.isNotEmpty
                  ? Text(email, style: const TextStyle(fontSize: 12))
                  : null,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'warn') _warn(inst);
                  if (v == 'suspend') _suspend(inst);
                  if (v == 'delete') _delete(inst);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'warn', child: _MenuItem(Icons.warning_amber, 'Warn', Colors.amber)),
                  const PopupMenuItem(value: 'suspend', child: _MenuItem(Icons.block, 'Suspend', Colors.orange)),
                  const PopupMenuItem(value: 'delete', child: _MenuItem(Icons.delete, 'Remove', Colors.red)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Applications tab ───────────────────────────────────────────────────────────

class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;
  String? _error;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await SecureStorage.getToken() ?? '';
      final data = await _ds.fetchApplications(token, status: _status.isEmpty ? null : _status);
      final list = data['data'] ?? data['applications'] ?? data['items'] ?? [];
      if (mounted) {
        setState(() {
        _apps = List<Map<String, dynamic>>.from(list is List ? list : []);
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _review(Map<String, dynamic> app, String status) async {
    String? reason;
    if (status == 'rejected') {
      reason = await _promptText(context, title: 'Reject Application', hint: 'Reason for rejection…', confirmLabel: 'Reject', confirmColor: Colors.red);
      if (reason == null) return;
    }
    try {
      final token = await SecureStorage.getToken() ?? '';
      final id = (app['id'] ?? app['_id'] ?? '').toString();
      await _ds.reviewApplication(id, status, token, reason: reason);
      _snack('Application ${status == 'approved' ? 'approved' : 'rejected'}', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _StatusFilter(
        value: _status,
        options: const ['pending', 'approved', 'rejected', ''],
        labels: const ['Pending', 'Approved', 'Rejected', 'All'],
        onChanged: (v) { setState(() => _status = v); _load(); },
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kNavy))
            : _error != null ? _errorView(_error!, _load)
            : _apps.isEmpty
                ? const Center(child: Text('No applications found.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _apps.length,
                      itemBuilder: (_, i) {
                        final app = _apps[i];
                        final user = app['user'] as Map? ?? app['applicant'] as Map? ?? {};
                        final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
                        final email = (user['email'] ?? '').toString();
                        final status = (app['status'] ?? 'pending').toString().toLowerCase();
                        final expertise = (app['expertise'] ?? app['specialization'] ?? '').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                CircleAvatar(
                                  backgroundColor: _kNavy,
                                  child: Text((name.isNotEmpty ? name[0] : '?').toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name.isEmpty ? 'Applicant' : name,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                ])),
                                _Chip(status, _appStatusColor(status)),
                              ]),
                              if (expertise.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Expertise: $expertise', style: const TextStyle(fontSize: 12)),
                              ],
                              if (status == 'pending') ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: OutlinedButton(
                                    onPressed: () => _review(app, 'rejected'),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                    child: const Text('Reject'),
                                  )),
                                  const SizedBox(width: 10),
                                  Expanded(child: ElevatedButton(
                                    onPressed: () => _review(app, 'approved'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    child: const Text('Approve'),
                                  )),
                                ]),
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

  Color _appStatusColor(String s) {
    switch (s) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }
}

// ── Reviews tab ───────────────────────────────────────────────────────────────

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
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color(0xFFF0F4FF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _FilterChip(label: 'All', selected: _filterRating == null, onTap: () { setState(() => _filterRating = null); _load(); }),
            ...List.generate(5, (i) {
              final star = 5 - i;
              return _FilterChip(label: '$star ★', selected: _filterRating == star, onTap: () { setState(() => _filterRating = star); _load(); });
            }),
          ]),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kNavy))
            : _error != null ? _errorView(_error!, _load)
            : _reviews.isEmpty
                ? const Center(child: Text('No reviews found.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _reviews.length,
                      itemBuilder: (_, i) {
                        final r = _reviews[i];
                        final u = r['user'] as Map? ?? {};
                        final reviewer = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim().isNotEmpty
                            ? '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim()
                            : (u['email'] ?? 'Student').toString();
                        final course = (r['course'] as Map?)?['title'] ?? r['courseTitle'] ?? '';
                        final rating = (r['rating'] as num?)?.toInt() ?? 0;
                        final content = (r['content'] ?? r['comment'] ?? '').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(reviewer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Row(children: List.generate(5, (j) => Icon(
                                  j < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber, size: 13,
                                ))),
                              ]),
                              if (course.toString().isNotEmpty)
                                Text(course.toString(), style: const TextStyle(color: _kNavy, fontSize: 11, fontWeight: FontWeight.w500)),
                              if (content.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
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

// ── Reports tab ───────────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await SecureStorage.getToken() ?? '';
      final data = await _ds.fetchReports(token, status: _status.isEmpty ? null : _status);
      final list = data['data'] ?? data['reports'] ?? data['items'] ?? [];
      if (mounted) {
        setState(() {
        _reports = List<Map<String, dynamic>>.from(list is List ? list : []);
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _resolve(Map<String, dynamic> report) async {
    final note = await _promptText(context, title: 'Resolve Report', hint: 'Resolution note (optional)…', confirmLabel: 'Resolve', confirmColor: Colors.green);
    if (note == null) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      final id = (report['id'] ?? report['_id'] ?? '').toString();
      await _ds.resolveReport(id, 'resolved', token, note: note.isEmpty ? null : note);
      _snack('Report resolved', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _StatusFilter(
        value: _status,
        options: const ['open', 'resolved', ''],
        labels: const ['Open', 'Resolved', 'All'],
        onChanged: (v) { setState(() => _status = v); _load(); },
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kNavy))
            : _error != null ? _errorView(_error!, _load)
            : _reports.isEmpty
                ? const Center(child: Text('No reports found.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _reports.length,
                      itemBuilder: (_, i) {
                        final r = _reports[i];
                        final reason = (r['reason'] ?? r['type'] ?? 'Report').toString();
                        final desc = (r['description'] ?? r['detail'] ?? '').toString();
                        final status = (r['status'] ?? 'open').toString().toLowerCase();
                        final reporter = r['reporter'] as Map? ?? r['user'] as Map? ?? {};
                        final name = '${reporter['firstName'] ?? ''} ${reporter['lastName'] ?? ''}'.trim();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Icon(Icons.flag, color: status == 'open' ? Colors.red : Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(reason, style: const TextStyle(fontWeight: FontWeight.bold))),
                                _Chip(status, status == 'open' ? Colors.red : Colors.green),
                              ]),
                              if (name.isNotEmpty) Text('By: $name', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(desc, style: const TextStyle(fontSize: 12, height: 1.4)),
                              ],
                              if (status == 'open') ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => _resolve(r),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    child: const Text('Resolve'),
                                  ),
                                ),
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

// ── Notifications tab ─────────────────────────────────────────────────────────

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  final _ds = AdminRemoteDataSource();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _role = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      _snack('Title and message are required', Colors.orange);
      return;
    }
    setState(() => _sending = true);
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.broadcastNotification(_role, _titleCtrl.text.trim(), _msgCtrl.text.trim(), token,
          actionUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim());
      _titleCtrl.clear();
      _msgCtrl.clear();
      _urlCtrl.clear();
      _snack('Notification sent!', Colors.green);
    } catch (e) { _snack(e.toString(), Colors.red); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Broadcast Notification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Send to', border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => setState(() => _role = v!),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Everyone')),
                DropdownMenuItem(value: 'student', child: Text('Students only')),
                DropdownMenuItem(value: 'instructor', child: Text('Instructors only')),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(labelText: 'Action URL (optional)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(backgroundColor: _kNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Notification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Videos tab ────────────────────────────────────────────────────────────────

class _VideosTab extends StatefulWidget {
  const _VideosTab();

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _videos = [];
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
      final list = await _ds.fetchPendingVideos(token);
      if (mounted) setState(() { _videos = list; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _approve(Map<String, dynamic> v) async {
    try {
      final token = await SecureStorage.getToken() ?? '';
      final id = (v['id'] ?? v['_id'] ?? '').toString();
      await _ds.approveVideo(id, token);
      _snack('Video approved', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<void> _reject(Map<String, dynamic> v) async {
    final reason = await _promptText(context, title: 'Reject Video', hint: 'Reason…', confirmLabel: 'Reject', confirmColor: Colors.red);
    if (reason == null || reason.isEmpty) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      final id = (v['id'] ?? v['_id'] ?? '').toString();
      await _ds.rejectVideo(id, reason, token);
      _snack('Video rejected', Colors.orange);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kNavy));
    if (_error != null) return _errorView(_error!, _load);
    if (_videos.isEmpty) return const Center(child: Text('No pending videos.'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _videos.length,
        itemBuilder: (_, i) {
          final v = _videos[i];
          final title = (v['title'] ?? v['filename'] ?? 'Video').toString();
          final lesson = (v['lesson'] as Map?)?['title'] ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: _kNavy,
                child: Icon(Icons.videocam, color: Colors.white, size: 18),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: lesson.toString().isNotEmpty ? Text(lesson.toString(), style: const TextStyle(fontSize: 11)) : null,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _approve(v)),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _reject(v)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Coupons tab ───────────────────────────────────────────────────────────────

class _CouponsTab extends StatefulWidget {
  const _CouponsTab();

  @override
  State<_CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<_CouponsTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _coupons = [];
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
      final list = await _ds.fetchCoupons(token);
      if (mounted) setState(() { _coupons = list; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  Future<void> _create() async {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController(text: '100');
    String type = 'percentage';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setSt) => AlertDialog(
          title: const Text('Create Coupon'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g. SAVE20)')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                onChanged: (v) => setSt(() => type = v!),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage off')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed amount')),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: type == 'percentage' ? 'Discount %' : 'Amount off (\$)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: maxUsesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max uses'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.createCoupon({
        'code': codeCtrl.text.trim().toUpperCase(),
        'discountType': type,
        'discountValue': double.tryParse(discountCtrl.text.trim()) ?? 0,
        'maxUses': int.tryParse(maxUsesCtrl.text.trim()) ?? 100,
      }, token);
      _snack('Coupon created!', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Delete coupon "${c['code']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final token = await SecureStorage.getToken() ?? '';
      await _ds.deleteCoupon((c['id'] ?? c['_id'] ?? '').toString(), token);
      _snack('Coupon deleted', Colors.green);
      _load();
    } catch (e) { _snack(e.toString(), Colors.red); }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Coupon'),
        onPressed: _create,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kNavy))
          : _error != null ? _errorView(_error!, _load)
          : _coupons.isEmpty
              ? const Center(child: Text('No coupons yet.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _coupons.length,
                    itemBuilder: (_, i) {
                      final c = _coupons[i];
                      final code = (c['code'] ?? '').toString();
                      final type = (c['discountType'] ?? c['type'] ?? '').toString();
                      final value = c['discountValue'] ?? c['discount'] ?? 0;
                      final uses = c['currentUses'] ?? c['usageCount'] ?? 0;
                      final max = c['maxUses'] ?? c['maxUsage'] ?? '∞';
                      final active = c['isActive'] != false;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _kNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.local_offer, color: _kNavy, size: 18),
                          ),
                          title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          subtitle: Text(
                            '${type == 'percentage' ? '$value%' : Money.xaf(value is num ? value : num.tryParse('$value') ?? 0)} off • Used $uses/$max',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            _Chip(active ? 'Active' : 'Inactive', active ? Colors.green : Colors.grey),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => _delete(c),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Admin payouts tab ─────────────────────────────────────────────────────────

class _PayoutsAdminTab extends StatefulWidget {
  const _PayoutsAdminTab();

  @override
  State<_PayoutsAdminTab> createState() => _PayoutsAdminTabState();
}

class _PayoutsAdminTabState extends State<_PayoutsAdminTab> {
  final _ds = AdminRemoteDataSource();
  List<Map<String, dynamic>> _payouts = [];
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
      final data = await _ds.fetchAllPayouts(token);
      final list = data['data'] ?? data['payouts'] ?? data['items'] ?? [];
      if (mounted) {
        setState(() {
        _payouts = List<Map<String, dynamic>>.from(list is List ? list : []);
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kNavy));
    if (_error != null) return _errorView(_error!, _load);
    if (_payouts.isEmpty) return const Center(child: Text('No payouts yet.'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _payouts.length,
        itemBuilder: (_, i) {
          final p = _payouts[i];
          final amount = double.tryParse((p['amount'] ?? 0).toString()) ?? 0;
          final status = (p['status'] ?? 'pending').toString().toLowerCase();
          final inst = p['instructor'] as Map? ?? p['user'] as Map? ?? {};
          final name = '${inst['firstName'] ?? ''} ${inst['lastName'] ?? ''}'.trim();
          final date = (p['createdAt'] ?? p['requestedAt'] ?? '').toString().split('T').first;

          Color statusColor;
          switch (status) {
            case 'completed': case 'paid': statusColor = Colors.green; break;
            case 'failed': statusColor = Colors.red; break;
            default: statusColor = Colors.orange;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(Icons.payments, color: statusColor, size: 18),
              ),
              title: Text(name.isEmpty ? 'Instructor' : name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: date.isNotEmpty ? Text(date, style: const TextStyle(fontSize: 11)) : null,
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Money.xaf(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                _Chip(status, statusColor),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Shared UI widgets ─────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      );
}

class _StatusFilter extends StatelessWidget {
  final String value;
  final List<String> options;
  final List<String> labels;
  final void Function(String) onChanged;

  const _StatusFilter({
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF0F4FF),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(options.length, (i) => _FilterChip(
              label: labels[i],
              selected: value == options[i],
              onTap: () => onChanged(options[i]),
            )),
          ),
        ),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
