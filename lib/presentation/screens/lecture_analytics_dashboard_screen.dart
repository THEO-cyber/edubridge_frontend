import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/secure_storage.dart';
import '../../data/datasources/live_session_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);
const _kBg = Color(0xFFF5F6FA);

class LectureAnalyticsDashboardScreen extends StatefulWidget {
  const LectureAnalyticsDashboardScreen({super.key});

  @override
  State<LectureAnalyticsDashboardScreen> createState() =>
      _LectureAnalyticsDashboardScreenState();
}

class _LectureAnalyticsDashboardScreenState
    extends State<LectureAnalyticsDashboardScreen> {
  final _liveDs = LiveSessionRemoteDataSource();

  bool _loading = true;
  String? _analyticsError;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _analyticsError = null; });
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await Future.wait<void>([
      _loadAnalytics(token),
      _loadSessions(token),
      _loadRequests(token),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAnalytics(String token) async {
    try {
      final ds = ProfileRemoteDataSource(AuthRemoteDataSource());
      _analytics = await ds.fetchInstructorAnalytics(token);
    } catch (e) {
      _analytics = {};
      _analyticsError = e.toString()
          .replaceFirst('ApiException: ', '')
          .replaceFirst('Exception: ', '');
    }
  }

  Future<void> _loadSessions(String token) async {
    try {
      _sessions = await _liveDs.fetchMyLiveSessions(token);
    } catch (_) {
      _sessions = [];
    }
  }

  Future<void> _loadRequests(String token) async {
    try {
      _requests = await _liveDs.fetchInstructorRequests(token);
    } catch (_) {
      _requests = [];
    }
  }

  // ── Computed metrics ────────────────────────────────────────────────────
  int get _totalSessions =>
      (_analytics['totalSessions'] as num?)?.toInt() ?? _sessions.length;

  int get _scheduledCount =>
      (_analytics['scheduledSessions'] as num?)?.toInt() ??
      _sessions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'scheduled').length;

  int get _ongoingCount =>
      (_analytics['ongoingSessions'] as num?)?.toInt() ??
      _sessions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'ongoing').length;

  int get _completedCount =>
      (_analytics['completedSessions'] as num?)?.toInt() ??
      _sessions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'completed').length;

  int get _totalRequests => _requests.length;

  int get _acceptedRequests => _requests
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'accepted')
      .length;

  int get _rejectedRequests => _requests
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'rejected')
      .length;

  int get _pendingRequests => _requests
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending')
      .length;

  double get _acceptanceRate {
    final total = _totalRequests;
    if (total == 0) return 0;
    return (_acceptedRequests / total) * 100;
  }

  double get _avgAttendance =>
      (_analytics['avgAttendance'] as num?)?.toDouble() ??
      (_analytics['averageAttendance'] as num?)?.toDouble() ??
      0.0;

  int get _totalStudents =>
      (_analytics['totalEnrollments'] as num?)?.toInt() ??
      (_analytics['totalStudents'] as num?)?.toInt() ??
      0;

  double get _totalHours {
    final fromApi = (_analytics['totalHours'] as num?)?.toDouble();
    if (fromApi != null) return fromApi;
    double hours = 0;
    for (final s in _sessions) {
      final dur = (s['duration'] as num?)?.toDouble();
      if (dur != null) hours += dur / 60.0;
    }
    return hours;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kNavy)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        color: _kNavy,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: _kNavy,
              title: const Text(
                'Session Analytics',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bar_chart_rounded,
                      color: Colors.white),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kNavy, _kBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 54, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 15),
                          const Text(
                            'Your Teaching Impact',
                            style: TextStyle(
                              color: Color.fromARGB(255, 232, 229, 229),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sessions · Students · Attendance · Hours',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Hero stats row
                          Row(
                            children: [
                              _HeroStat(
                                  value: _totalSessions.toString(),
                                  label: 'Sessions',
                                  icon: Icons.videocam_rounded),
                              const SizedBox(width: 10),
                              _HeroStat(
                                  value: _totalStudents.toString(),
                                  label: 'Students',
                                  icon: Icons.people_outline_rounded),
                              const SizedBox(width: 10),
                              _HeroStat(
                                  value:
                                      '${_avgAttendance.toStringAsFixed(0)}%',
                                  label: 'Avg Att.',
                                  icon: Icons.how_to_reg_rounded),
                              const SizedBox(width: 10),
                              _HeroStat(
                                  value:
                                      '${_totalHours.toStringAsFixed(1)}h',
                                  label: 'Hours',
                                  icon: Icons.timer_outlined),
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Analytics error banner ────────────────────────
                    if (_analyticsError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Analytics unavailable: $_analyticsError',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // ── Session Status Breakdown ──────────────────────
                    _SectionTitle('Session Status'),
                    const SizedBox(height: 12),
                    _SessionStatusCard(
                      scheduled: _scheduledCount,
                      ongoing: _ongoingCount,
                      completed: _completedCount,
                      total: _totalSessions,
                    ),
                    const SizedBox(height: 20),

                    // ── Request Statistics ────────────────────────────
                    _SectionTitle('Request Statistics'),
                    const SizedBox(height: 12),
                    _RequestStatsCard(
                      total: _totalRequests,
                      accepted: _acceptedRequests,
                      rejected: _rejectedRequests,
                      pending: _pendingRequests,
                      acceptanceRate: _acceptanceRate,
                    ),
                    const SizedBox(height: 20),

                    // ── Quick Insights ────────────────────────────────
                    _SectionTitle('Quick Insights'),
                    const SizedBox(height: 12),
                    _InsightsRow(
                      sessions: _totalSessions,
                      completed: _completedCount,
                      acceptanceRate: _acceptanceRate,
                      avgAttendance: _avgAttendance,
                    ),
                    const SizedBox(height: 20),

                    // ── Recent Sessions ───────────────────────────────
                    if (_sessions.isNotEmpty) ...[
                      _SectionTitle('Recent Sessions'),
                      const SizedBox(height: 12),
                      ..._sessions.take(5).map((s) => _SessionRow(session: s)),
                    ] else
                      _EmptySessionsCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero stat pill (inside header) ─────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  const _HeroStat({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(height: 3),
            ],
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kNavy, _kBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF263238),
          ),
        ),
      ],
    );
  }
}

// ── Session status card ─────────────────────────────────────────────────────

class _SessionStatusCard extends StatelessWidget {
  final int scheduled;
  final int ongoing;
  final int completed;
  final int total;

  const _SessionStatusCard({
    required this.scheduled,
    required this.ongoing,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final t = total == 0 ? 1 : total;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _StatusRow(
            label: 'Scheduled',
            value: scheduled,
            total: t,
            color: _kBlue,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 14),
          _StatusRow(
            label: 'Ongoing',
            value: ongoing,
            total: t,
            color: Colors.orange[700]!,
            icon: Icons.videocam_rounded,
          ),
          const SizedBox(height: 14),
          _StatusRow(
            label: 'Completed',
            value: completed,
            total: t,
            color: Colors.green[700]!,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value / total;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(
                    '$value (${(pct * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Request stats card ──────────────────────────────────────────────────────

class _RequestStatsCard extends StatelessWidget {
  final int total;
  final int accepted;
  final int rejected;
  final int pending;
  final double acceptanceRate;

  const _RequestStatsCard({
    required this.total,
    required this.accepted,
    required this.rejected,
    required this.pending,
    required this.acceptanceRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total requests header
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, color: _kNavy, size: 20),
              const SizedBox(width: 8),
              const Text('Total Requests',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const Spacer(),
              Text(
                total.toString(),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kNavy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Acceptance rate ring + breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (acceptanceRate / 100).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                    ),
                    Text(
                      '${acceptanceRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Breakdown
              Expanded(
                child: Column(
                  children: [
                    _ReqRow(
                        label: 'Accepted',
                        value: accepted,
                        color: Colors.green[700]!),
                    const SizedBox(height: 8),
                    _ReqRow(
                        label: 'Pending',
                        value: pending,
                        color: Colors.orange[700]!),
                    const SizedBox(height: 8),
                    _ReqRow(
                        label: 'Rejected',
                        value: rejected,
                        color: Colors.red[700]!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReqRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ReqRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        Text(
          value.toString(),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: color),
        ),
      ],
    );
  }
}

// ── Quick Insights row ──────────────────────────────────────────────────────

class _InsightsRow extends StatelessWidget {
  final int sessions;
  final int completed;
  final double acceptanceRate;
  final double avgAttendance;

  const _InsightsRow({
    required this.sessions,
    required this.completed,
    required this.acceptanceRate,
    required this.avgAttendance,
  });

  double get _completionRate =>
      sessions == 0 ? 0 : (completed / sessions) * 100;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            icon: Icons.trending_up_rounded,
            label: 'Completion Rate',
            value: '${_completionRate.toStringAsFixed(0)}%',
            color: Colors.teal[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: Icons.how_to_reg_rounded,
            label: 'Avg Attendance',
            value: '${avgAttendance.toStringAsFixed(0)}%',
            color: Colors.purple[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Acceptance',
            value: '${acceptanceRate.toStringAsFixed(0)}%',
            color: Colors.green[700]!,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ── Recent session row ──────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final title = (session['title'] ?? 'Live Session').toString();
    final status =
        (session['status'] ?? 'scheduled').toString().toLowerCase();
    final scheduled = DateTime.tryParse(
          (session['scheduledAt'] ?? session['date'] ?? '').toString(),
        ) ??
        DateTime.now();

    final statusColor = status == 'ongoing'
        ? Colors.orange[700]!
        : status == 'completed'
            ? Colors.green[700]!
            : _kBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.videocam_rounded, color: statusColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: _kNavy),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            DateFormat('MMM d, yyyy • HH:mm').format(scheduled),
            style:
                const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptySessionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined,
              size: 52, color: Colors.blueGrey[200]),
          const SizedBox(height: 12),
          const Text(
            'No sessions yet',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black54),
          ),
          const SizedBox(height: 6),
          const Text(
            'Analytics will appear once you create\nyour first live session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
