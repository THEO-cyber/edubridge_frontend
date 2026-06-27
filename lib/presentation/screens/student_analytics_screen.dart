import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class StudentAnalyticsScreen extends StatefulWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  late final ProfileRemoteDataSource _ds;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _ds = ProfileRemoteDataSource(AuthRemoteDataSource());
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
      final data = await _ds.fetchStudentAnalytics(token);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kNavy))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _data.isEmpty
                  ? _EmptyState()
                  : _AnalyticsBody(data: _data),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnalyticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalEnrollments = (data['totalEnrollments'] ?? 0) as num;
    final completedCourses = (data['completedCourses'] ?? 0) as num;
    final certificates = (data['certificatesEarned'] ?? 0) as num;
    final totalWatchSecs = (data['totalWatchTime'] ?? 0) as num;
    final completionRate = (data['completionRate'] ?? 0) as num;
    final courseProgress =
        (data['courseProgress'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary header card ────────────────────────────────────────────
        _SummaryCard(
          totalEnrollments: totalEnrollments.toInt(),
          completedCourses: completedCourses.toInt(),
          certificates: certificates.toInt(),
          watchSeconds: totalWatchSecs.toInt(),
          completionRate: completionRate.toDouble(),
        ),
        const SizedBox(height: 20),

        // ── Overall completion ring ────────────────────────────────────────
        _CompletionRing(
          completionRate: completionRate.toDouble(),
          completed: completedCourses.toInt(),
          total: totalEnrollments.toInt(),
        ),
        const SizedBox(height: 20),

        // ── Course list ────────────────────────────────────────────────────
        if (courseProgress.isEmpty)
          _EmptyState()
        else ...[
          Text(
            'ENROLLED COURSES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade400,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ...courseProgress.map((cp) => _CourseProgressCard(course: cp)),
        ],
      ],
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int totalEnrollments;
  final int completedCourses;
  final int certificates;
  final int watchSeconds;
  final double completionRate;

  const _SummaryCard({
    required this.totalEnrollments,
    required this.completedCourses,
    required this.certificates,
    required this.watchSeconds,
    required this.completionRate,
  });

  String get _watchTimeLabel {
    if (watchSeconds <= 0) return '0 min';
    final hours = watchSeconds ~/ 3600;
    final mins = (watchSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Learning Overview',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: '$totalEnrollments',
                  label: 'Enrolled',
                  icon: Icons.school_outlined,
                ),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                  value: '$completedCourses',
                  label: 'Completed',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                  value: '$certificates',
                  label: 'Certificates',
                  icon: Icons.emoji_events_outlined,
                ),
              ),
              _Divider(),
              Expanded(
                child: _StatItem(
                  value: _watchTimeLabel,
                  label: 'Watch Time',
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: Colors.white24);
}

// ── Completion ring ────────────────────────────────────────────────────────────

class _CompletionRing extends StatelessWidget {
  final double completionRate;
  final int completed;
  final int total;

  const _CompletionRing({
    required this.completionRate,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = completionRate.clamp(0.0, 100.0);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.blueGrey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _kNavy),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Completion',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _kNavy),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$completed of $total courses completed',
                    style: TextStyle(
                        fontSize: 13, color: Colors.blueGrey.shade500),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.blueGrey.shade100,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_kBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Course progress card ───────────────────────────────────────────────────────

class _CourseProgressCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseProgressCard({required this.course});

  double get _pct {
    final raw = course['progressPercentage'] ?? 0;
    return (raw as num).toDouble().clamp(0.0, 100.0);
  }

  bool get _isDone => course['completedAt'] != null;

  String get _enrolledDate {
    try {
      final raw = course['enrolledAt'] ?? '';
      if (raw.toString().isEmpty) return '';
      final dt = DateTime.parse(raw.toString()).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return 'Enrolled ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String get _watchTime {
    final secs = (course['watchedDuration'] ?? course['timeSpent'] ?? 0) as num;
    final s = secs.toInt();
    if (s <= 0) return '0 min watched';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m watched';
    return '$m min watched';
  }

  @override
  Widget build(BuildContext context) {
    final completed = (course['completedLessons'] ?? 0) as num;
    final total = (course['totalLessons'] ?? 0) as num;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Thumbnail placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: Colors.blueGrey.shade100,
                    child: Icon(Icons.play_lesson_outlined,
                        color: Colors.blueGrey.shade400, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (course['courseTitle'] ?? 'Course').toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _enrolledDate,
                        style: TextStyle(
                            fontSize: 11, color: Colors.blueGrey.shade400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _isDone
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade600, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _pct / 100,
                minHeight: 6,
                backgroundColor: Colors.blueGrey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _isDone ? Colors.green : _kBlue),
              ),
            ),
            const SizedBox(height: 8),

            // Stats row
            Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 13, color: Colors.blueGrey.shade400),
                const SizedBox(width: 4),
                Text(
                  '$completed / $total lessons',
                  style: TextStyle(
                      fontSize: 12, color: Colors.blueGrey.shade500),
                ),
                const Spacer(),
                Icon(Icons.play_circle_outline,
                    size: 13, color: Colors.blueGrey.shade400),
                const SizedBox(width: 4),
                Text(
                  _watchTime,
                  style: TextStyle(
                      fontSize: 12, color: Colors.blueGrey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error states ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 72, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            const Text('No courses yet',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Enroll in a course to start tracking your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade400)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: _kNavy),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
