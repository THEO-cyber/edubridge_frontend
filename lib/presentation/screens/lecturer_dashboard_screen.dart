import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/secure_storage.dart';
import '../../services/notification_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/course_remote_data_source.dart';
import '../../data/datasources/live_session_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../blocs/live_session_bloc_provider.dart';
import 'lecture_analytics_dashboard_screen.dart';
import 'lecturer/lecturer_course_management_screen.dart';
import 'lecturer_earnings_screen.dart';
import 'lecturer_session_management_screen.dart';
import 'lecturer_withdrawal_screen.dart';

const _kPrimary = Color(0xFF1A237E);
const _kAccent = Color(0xFF1976D2);
const _kBg = Color(0xFFF5F6FA);

class LecturerDashboardScreen extends StatefulWidget {
  const LecturerDashboardScreen({super.key});

  @override
  State<LecturerDashboardScreen> createState() =>
      _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  int _selectedIndex = 0;

  // Shared user data loaded once and passed down
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) return;
      final ds = ProfileRemoteDataSource(AuthRemoteDataSource());
      final data = await ds.fetchProfile(token);
      if (mounted) {
        setState(() => _profile = data);
      }
    } catch (_) {}
  }

  String get _displayName {
    final first = (_profile['firstName'] ?? _profile['first_name'] ?? '')
        .toString()
        .trim();
    final last = (_profile['lastName'] ?? _profile['last_name'] ?? '')
        .toString()
        .trim();
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return (_profile['username'] ?? _profile['name'] ?? 'Instructor')
        .toString();
  }

  String get _displayEmail => (_profile['email'] ?? '').toString();

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _DashboardHome(profile: _profile, onNavTap: _onNavTap);
      case 1:
        return const LecturerCourseManagementScreen();
      case 2:
        return LiveSessionBlocProvider(
          child: const LecturerSessionManagementScreen(),
        );
      case 3:
        return LiveSessionBlocProvider(
          child: const LectureAnalyticsDashboardScreen(),
        );
      case 4:
        return _ProfilePage(profile: _profile, onSaved: _loadProfile);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      drawer: _buildDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildPage(_selectedIndex),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimary, _kAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  child: Text(
                    _displayName.isNotEmpty
                        ? _displayName[0].toUpperCase()
                        : 'I',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _displayEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Instructor',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.dashboard_outlined, 'Dashboard', 0),
                _drawerItem(Icons.menu_book_outlined, 'My Courses', 1),
                _drawerItem(Icons.video_call_outlined, 'Live Sessions', 2),
                _drawerItem(Icons.bar_chart_outlined, 'Analytics', 3),
                _drawerItem(Icons.person_outline, 'Profile', 4),
                ListTile(
                  leading: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.blueGrey[600],
                  ),
                  title: Text(
                    'Earnings',
                    style: TextStyle(color: Colors.blueGrey[800]),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LecturerEarningsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.attach_money,
                    color: Colors.blueGrey[600],
                  ),
                  title: Text(
                    'Withdraw Earnings',
                    style: TextStyle(color: Colors.blueGrey[800]),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LecturerWithdrawalScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    await NotificationService.unregisterToken();
                    await SecureStorage.deleteAllTokens();
                    await SecureStorage.clearRole();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/student-dashboard',
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    return ListTile(
      selected: selected,
      selectedTileColor: _kPrimary.withValues(alpha: 0.08),
      leading: Icon(icon, color: selected ? _kPrimary : Colors.blueGrey[600]),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? _kPrimary : Colors.blueGrey[800],
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        _onNavTap(index);
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: _kPrimary,
      unselectedItemColor: Colors.blueGrey[400],
      currentIndex: _selectedIndex,
      onTap: _onNavTap,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_call_outlined),
          activeIcon: Icon(Icons.video_call),
          label: 'Live',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Dashboard Home Tab
// ─────────────────────────────────────────────

class _DashboardHome extends StatefulWidget {
  final Map<String, dynamic> profile;
  final void Function(int) onNavTap;

  const _DashboardHome({required this.profile, required this.onNavTap});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  final _courseDs = CourseRemoteDataSource();
  final _liveDs = LiveSessionRemoteDataSource();
  late final _profileDs = ProfileRemoteDataSource(AuthRemoteDataSource());

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _sessions = [];

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
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Not authenticated';
        _loading = false;
      });
      return;
    }

    Map<String, dynamic> analytics = {};
    List<Map<String, dynamic>> courses = [];
    List<Map<String, dynamic>> sessions = [];

    try {
      analytics = await _profileDs.fetchInstructorAnalytics(token);
    } catch (_) {}

    try {
      courses = await _courseDs.fetchInstructorCourses(token);
    } catch (_) {}

    try {
      sessions = await _liveDs.fetchMyLiveSessions(token);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _analytics = analytics;
        _courses = courses;
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = widget.profile;
    final firstName = (profile['firstName'] ?? profile['first_name'] ?? '')
        .toString()
        .trim();
    final lastName = (profile['lastName'] ?? profile['last_name'] ?? '')
        .toString()
        .trim();
    final displayName = firstName.isNotEmpty || lastName.isNotEmpty
        ? '$firstName $lastName'.trim()
        : (profile['username'] ?? profile['name'] ?? 'Instructor').toString();
    final email = (profile['email'] ?? '').toString();

    final totalCourses = (_analytics['totalCourses'] ?? _courses.length)
        .toString();
    final totalStudents =
        (_analytics['totalEnrollments'] ?? _analytics['totalStudents'] ?? 0)
            .toString();
    final totalRevenue = (_analytics['totalRevenue'] ?? 0);
    final avgRating = (_analytics['averageRating'] ?? 0.0);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/notifications'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimary, _kAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white24,
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'I',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    
                    _StatCard(
                      icon: Icons.menu_book,
                      label: 'Courses',
                      value: totalCourses,
                      color: _kPrimary,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.people,
                      label: 'Students',
                      value: totalStudents,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.star,
                      label: 'Avg Rating',
                      value: avgRating is num
                          ? avgRating.toStringAsFixed(1)
                          : avgRating.toString(),
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.payments,
                      label: 'Revenue',
                      value: '₦${_formatRevenue(totalRevenue)}',
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Quick Actions'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'New Course',
                        color: _kPrimary,
                        onTap: () => widget.onNavTap(1),
                      ),
                      const SizedBox(width: 10),
                      _ActionButton(
                        icon: Icons.video_call_outlined,
                        label: 'Schedule\nSession',
                        color: Colors.teal,
                        onTap: () => widget.onNavTap(2),
                      ),
                      const SizedBox(width: 10),
                      _ActionButton(
                        icon: Icons.bar_chart_outlined,
                        label: 'Analytics',
                        color: Colors.deepOrange,
                        onTap: () => widget.onNavTap(3),
                      ),
                      const SizedBox(width: 10),
                      _ActionButton(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Earnings',
                        color: Colors.green.shade700,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LecturerEarningsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // My Courses
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('My Courses'),
                  TextButton(
                    onPressed: () => widget.onNavTap(1),
                    child: const Text(
                      'See all',
                      style: TextStyle(color: _kAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_courses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyState(
                  icon: Icons.menu_book_outlined,
                  message: 'No courses yet. Create your first course.',
                  actionLabel: 'Create Course',
                  onAction: () => widget.onNavTap(1),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) {
                    final c = _courses[i];
                    final title = (c['title'] ?? 'Untitled').toString();
                    final enrolled = (c['enrolledCount'] ?? c['students'] ?? 0)
                        .toString();
                    final status =
                        (c['status'] ??
                                (c['isPublished'] == true
                                    ? 'published'
                                    : 'draft'))
                            .toString();
                    return _CourseCard(
                      title: title,
                      enrolled: enrolled,
                      status: status,
                    );
                  },
                ),
              ),
            ),

          // Recent Live Sessions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Recent Live Sessions'),
                  TextButton(
                    onPressed: () => widget.onNavTap(2),
                    child: const Text(
                      'See all',
                      style: TextStyle(color: _kAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_sessions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyState(
                  icon: Icons.video_call_outlined,
                  message: 'No live sessions yet.',
                  actionLabel: 'Schedule Session',
                  onAction: () => widget.onNavTap(2),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final s = _sessions[i];
                final title = (s['title'] ?? 'Live Session').toString();
                final scheduledAt =
                    DateTime.tryParse(
                      (s['scheduledAt'] ?? s['date'] ?? '').toString(),
                    ) ??
                    DateTime.now();
                final status = (s['status'] ?? 'scheduled')
                    .toString()
                    .toLowerCase();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _SessionTile(
                    title: title,
                    scheduledAt: scheduledAt,
                    status: status,
                  ),
                );
              }, childCount: _sessions.take(5).length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _formatRevenue(dynamic value) {
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Color(0xFF263238),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [Colors.white, color.withValues(alpha: 0.04)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.blueGrey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[700],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final String enrolled;
  final String status;

  const _CourseCard({
    required this.title,
    required this.enrolled,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = status == 'published' || status == 'active';
    final isUnderReview = status == 'under_review';
    final statusColor = isPublished
        ? Colors.green
        : isUnderReview
        ? Colors.orange
        : Colors.blueGrey;
    final statusLabel = isPublished
        ? 'Published'
        : isUnderReview
        ? 'Under Review'
        : 'Draft';

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: _kPrimary,
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF263238),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.people, size: 12, color: Colors.blueGrey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '$enrolled enrolled',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final String title;
  final DateTime scheduledAt;
  final String status;

  const _SessionTile({
    required this.title,
    required this.scheduledAt,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = status == 'ongoing';
    final statusColor = isOngoing
        ? Colors.red
        : status == 'completed'
        ? Colors.green
        : _kAccent;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.videocam, color: statusColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DateFormat('MMM d, yyyy • HH:mm').format(scheduledAt),
            style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.blueGrey[300]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.blueGrey[500], fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPrimary),
              foregroundColor: _kPrimary,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile Tab
// ─────────────────────────────────────────────

class _ProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onSaved;

  const _ProfilePage({required this.profile, required this.onSaved});

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _educationCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _expertiseCtrl; // comma-separated
  late final TextEditingController _certificationsCtrl; // comma-separated

  @override
  void initState() {
    super.initState();
    final ip =
        widget.profile['instructorProfile'] as Map<String, dynamic>? ?? {};
    _titleCtrl = TextEditingController(text: (ip['title'] ?? '').toString());
    _experienceCtrl = TextEditingController(
      text: (ip['experience'] ?? '').toString(),
    );
    _educationCtrl = TextEditingController(
      text: (ip['education'] ?? '').toString(),
    );
    _websiteCtrl = TextEditingController(
      text: (ip['website'] ?? '').toString(),
    );
    _bioCtrl = TextEditingController(
      text: (widget.profile['bio'] ?? '').toString(),
    );
    final expertiseList = (ip['expertise'] as List?)?.cast<String>() ?? [];
    _expertiseCtrl = TextEditingController(text: expertiseList.join(', '));
    final certList = (ip['certifications'] as List?)?.cast<String>() ?? [];
    _certificationsCtrl = TextEditingController(text: certList.join(', '));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _experienceCtrl.dispose();
    _educationCtrl.dispose();
    _websiteCtrl.dispose();
    _bioCtrl.dispose();
    _expertiseCtrl.dispose();
    _certificationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final ds = ProfileRemoteDataSource(AuthRemoteDataSource());

      final expertiseList = _expertiseCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final certList = _certificationsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await ds.updateInstructorProfile({
        'title': _titleCtrl.text.trim(),
        'expertise': expertiseList,
        'experience': _experienceCtrl.text.trim(),
        'education': _educationCtrl.text.trim(),
        'certifications': certList,
        'website': _websiteCtrl.text.trim(),
      }, token);

      await ds.updateProfile({'bio': _bioCtrl.text.trim()}, token);
      await widget.onSaved();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Update failed: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final ip = (profile['instructorProfile'] as Map<String, dynamic>?) ?? {};
    final firstName = (profile['firstName'] ?? profile['first_name'] ?? '')
        .toString()
        .trim();
    final lastName = (profile['lastName'] ?? profile['last_name'] ?? '')
        .toString()
        .trim();
    final displayName = firstName.isNotEmpty || lastName.isNotEmpty
        ? '$firstName $lastName'.trim()
        : (profile['username'] ?? 'Instructor').toString();
    final email = (profile['email'] ?? '').toString();
    final role = (profile['role'] ?? 'INSTRUCTOR').toString();
    final hourlyRate = (ip['hourlyRate'] ?? 0).toString();

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            automaticallyImplyLeading: false,
            backgroundColor: _kPrimary,
            actions: [
              if (!_isSaving)
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimary, _kAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white24,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'I',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (hourlyRate != '0') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '₦$hourlyRate/hr',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact info card (read-only)
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Instructor profile card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.school,
                                color: _kPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Instructor Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildField(
                            label: 'Bio',
                            icon: Icons.info_outline,
                            controller: _bioCtrl,
                            displayValue: _bioCtrl.text.isNotEmpty
                                ? _bioCtrl.text
                                : 'Not set',
                            maxLines: 3,
                          ),
                          const Divider(height: 24),
                          _buildField(
                            label: 'Title',
                            icon: Icons.badge_outlined,
                            controller: _titleCtrl,
                            displayValue: _titleCtrl.text.isNotEmpty
                                ? _titleCtrl.text
                                : 'e.g. Dr., Prof.',
                          ),
                          const Divider(height: 24),
                          _buildField(
                            label: 'Expertise (comma separated)',
                            icon: Icons.lightbulb_outline,
                            controller: _expertiseCtrl,
                            displayValue: _expertiseCtrl.text.isNotEmpty
                                ? _expertiseCtrl.text
                                : 'e.g. Flutter, Dart, Firebase',
                          ),
                          const Divider(height: 24),
                          _buildField(
                            label: 'Experience',
                            icon: Icons.work_outline,
                            controller: _experienceCtrl,
                            displayValue: _experienceCtrl.text.isNotEmpty
                                ? _experienceCtrl.text
                                : 'Not set',
                            maxLines: 2,
                          ),
                          const Divider(height: 24),
                          _buildField(
                            label: 'Education',
                            icon: Icons.school_outlined,
                            controller: _educationCtrl,
                            displayValue: _educationCtrl.text.isNotEmpty
                                ? _educationCtrl.text
                                : 'Not set',
                          ),
                          const Divider(height: 24),
                          _buildField(
                            label: 'Certifications (comma separated)',
                            icon: Icons.verified_outlined,
                            controller: _certificationsCtrl,
                            displayValue: _certificationsCtrl.text.isNotEmpty
                                ? _certificationsCtrl.text
                                : 'Not set',
                          ),
                          const Divider(height: 24),
                          _buildField(
                            label: 'Website',
                            icon: Icons.language_outlined,
                            controller: _websiteCtrl,
                            displayValue: _websiteCtrl.text.isNotEmpty
                                ? _websiteCtrl.text
                                : 'Not set',
                            keyboardType: TextInputType.url,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await NotificationService.unregisterToken();
                          await SecureStorage.deleteAllTokens();
                          await SecureStorage.clearRole();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/student-dashboard',
                              (route) => false,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String displayValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 10),
          child: Icon(icon, color: Colors.blueGrey[400], size: 18),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 4),
              _isEditing
                  ? TextFormField(
                      controller: controller,
                      maxLines: maxLines,
                      keyboardType: keyboardType,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.blueGrey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.blueGrey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _kPrimary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: _kBg,
                      ),
                    )
                  : Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[800],
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey[400], size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.blueGrey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
