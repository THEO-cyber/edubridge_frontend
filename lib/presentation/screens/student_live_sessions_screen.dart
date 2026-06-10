import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/live_session_remote_data_source.dart';
import 'live_classroom_screen.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);
const _kBg = Color(0xFFF5F6FA);

class StudentLiveSessionsScreen extends StatefulWidget {
  const StudentLiveSessionsScreen({super.key});

  @override
  State<StudentLiveSessionsScreen> createState() =>
      _StudentLiveSessionsScreenState();
}

class _StudentLiveSessionsScreenState
    extends State<StudentLiveSessionsScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String? _error;

  // Track which sessions the student has already applied to (local state).
  // Key: sessionId, Value: status string
  final Map<String, String> _appliedStatus = {};
  final Set<String> _applying = {};

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
      if (token == null || token.isEmpty) throw Exception('Not logged in');
      final ds = LiveSessionRemoteDataSource();

      // Load upcoming sessions + my own sessions (accepted/ongoing ones may
      // drop off the upcoming list once they go ONGOING).
      final results = await Future.wait([
        ds.fetchUpcomingSessions(token),
        ds.fetchMyLiveSessions(token).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final upcoming = results[0];
      final mine = results[1];

      // Track which session IDs came from "my sessions" (student is accepted)
      final mySessionIds = <String>{};
      for (final s in mine) {
        final id = (s['id'] ?? s['_id'] ?? '').toString();
        if (id.isNotEmpty) mySessionIds.add(id);
      }

      // Merge, deduplicate by id — mine takes precedence (fresher status)
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final s in [...mine, ...upcoming]) {
        final id = (s['id'] ?? s['_id'] ?? '').toString();
        if (id.isNotEmpty && seen.add(id)) merged.add(s);
      }

      if (!mounted) return;
      setState(() {
        _sessions = merged;
        _loading = false;
        for (final s in merged) {
          final id = (s['id'] ?? s['_id'] ?? '').toString();
          final myApp = s['myApplication'];
          if (myApp is Map) {
            _appliedStatus[id] =
                (myApp['status'] ?? 'pending').toString().toLowerCase();
          } else if (mySessionIds.contains(id)) {
            // Session came from /my-sessions — student is accepted
            _appliedStatus[id] = 'accepted';
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _apply(String sessionId) async {
    if (_applying.contains(sessionId)) return;
    setState(() => _applying.add(sessionId));
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;
      await LiveSessionRemoteDataSource().applyToSession(sessionId, token);
      if (!mounted) return;
      setState(() {
        _appliedStatus[sessionId] = 'pending';
        _applying.remove(sessionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Application sent! Wait for the instructor to accept.'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying.remove(sessionId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _join(String sessionId, String sessionTitle) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;
      final credentials =
          await LiveSessionRemoteDataSource().joinLiveSession(sessionId, token);
      if (!mounted) return;

      final livekitUrl = (credentials['livekitUrl'] ?? '').toString();
      final accessToken = (credentials['accessToken'] ?? '').toString();
      final roomId = (credentials['roomId'] ?? sessionId).toString();

      if (livekitUrl.isEmpty || accessToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Session is not yet live — please wait.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LiveClassroomScreen(
          roomId: roomId,
          accessToken: accessToken,
          livekitUrl: livekitUrl,
          sessionTitle: sessionTitle,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Sessions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Browse and apply to upcoming sessions',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kNavy));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 52, color: Colors.blueGrey[200]),
              const SizedBox(height: 14),
              const Text('Could not load sessions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45, fontSize: 13)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kNavy,
                  side: const BorderSide(color: _kNavy),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kNavy.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_outlined,
                  size: 56, color: _kNavy),
            ),
            const SizedBox(height: 20),
            const Text('No upcoming sessions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kNavy)),
            const SizedBox(height: 8),
            const Text(
              'Check back later — instructors\nwill post new sessions soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kNavy,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _sessions.length,
        itemBuilder: (_, i) => _SessionCard(
          session: _sessions[i],
          appliedStatus: _appliedStatus[
              (_sessions[i]['id'] ?? _sessions[i]['_id'] ?? '').toString()],
          applying: _applying.contains(
              (_sessions[i]['id'] ?? _sessions[i]['_id'] ?? '').toString()),
          onApply: () => _apply(
              (_sessions[i]['id'] ?? _sessions[i]['_id'] ?? '').toString()),
          onJoin: () => _join(
              (_sessions[i]['id'] ?? _sessions[i]['_id'] ?? '').toString(),
              (_sessions[i]['title'] ?? 'Live Session').toString()),
        ),
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final String? appliedStatus;
  final bool applying;
  final VoidCallback onApply;
  final VoidCallback onJoin;

  const _SessionCard({
    required this.session,
    required this.appliedStatus,
    required this.applying,
    required this.onApply,
    required this.onJoin,
  });

  bool get _isAccepted =>
      appliedStatus == 'accepted' || appliedStatus == 'in_progress';
  bool get _isPending => appliedStatus == 'pending';
  bool get _isRejected => appliedStatus == 'rejected';

  bool _isJoinable() {
    if (!_isAccepted) return false;
    final status = (session['status'] ?? '').toString().toLowerCase();
    // Always joinable if the session is currently ongoing
    if (status == 'ongoing') return true;
    final raw = session['scheduledAt']?.toString();
    if (raw == null) return false;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return false;
    final now = DateTime.now().toUtc();
    final diff = dt.toUtc().difference(now).inMinutes;
    // Allow join from 15 min before up to 60 min after scheduled time
    return diff <= 15 && diff >= -60;
  }

  String _instructorName() {
    final inst = session['instructor'];
    if (inst is Map) {
      final first =
          (inst['firstName'] ?? inst['first_name'] ?? '').toString();
      final last = (inst['lastName'] ?? inst['last_name'] ?? '').toString();
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      return (inst['name'] ?? inst['username'] ?? '').toString();
    }
    return (session['instructorName'] ?? 'Instructor').toString();
  }

  String _courseName() {
    final c = session['course'];
    if (c is Map) return (c['title'] ?? '').toString();
    return (session['courseTitle'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final title = (session['title'] ?? 'Untitled Session').toString();
    final instructor = _instructorName();
    final course = _courseName();
    final rawAt = session['scheduledAt']?.toString();
    final scheduledAt =
        rawAt != null ? DateTime.tryParse(rawAt)?.toLocal() : null;
    final duration =
        (session['durationMinutes'] as num?)?.toInt() ?? 0;
    final maxStudents =
        (session['maxStudents'] as num?)?.toInt() ?? 0;
    final accepted =
        (session['acceptedCount'] ?? session['currentParticipants'] ?? 0)
            as num;
    final seatsLeft = maxStudents - accepted.toInt();
    final status = (session['status'] ?? 'scheduled').toString().toLowerCase();
    final isOngoing = status == 'ongoing';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                  width: 5,
                  color: isOngoing ? Colors.orange[700] : _kBlue),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kNavy,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOngoing) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.orange.withValues(
                                        alpha: 0.4)),
                              ),
                              child: const Text('LIVE',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Instructor
                      Row(children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 13, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(instructor,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500)),
                        if (course.isNotEmpty) ...[
                          const Text('  ·  ',
                              style: TextStyle(
                                  color: Colors.black26, fontSize: 12)),
                          Expanded(
                            child: Text(course,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black38)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      // Date + duration + seats
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          if (scheduledAt != null)
                            _Chip(
                              icon: Icons.calendar_today_outlined,
                              label: DateFormat('MMM d, yyyy · HH:mm')
                                  .format(scheduledAt),
                            ),
                          if (duration > 0)
                            _Chip(
                                icon: Icons.timer_outlined,
                                label: '$duration min'),
                          if (maxStudents > 0)
                            _Chip(
                              icon: Icons.people_outline_rounded,
                              label: seatsLeft > 0
                                  ? '$seatsLeft seats left'
                                  : 'Full',
                              color: seatsLeft <= 3
                                  ? Colors.red[400]
                                  : null,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Action button
                      _buildActionButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isJoinable()) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onJoin,
          icon: const Icon(Icons.videocam_rounded, size: 16),
          label: const Text('Join Now',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );
    }
    if (_isAccepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 15, color: Colors.green[700]),
          const SizedBox(width: 6),
          Text('Accepted — join when the session starts',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500)),
        ]),
      );
    }
    if (_isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_top_rounded, size: 15, color: Colors.amber[700]),
          const SizedBox(width: 6),
          Text('Application pending — awaiting instructor',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber[700],
                  fontWeight: FontWeight.w500)),
        ]),
      );
    }
    if (_isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cancel_outlined, size: 15, color: Colors.red[400]),
          const SizedBox(width: 6),
          Text('Application not accepted',
              style: TextStyle(fontSize: 12, color: Colors.red[400])),
        ]),
      );
    }
    // Not yet applied
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: applying ? null : onApply,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: applying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Apply',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black45;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 12, color: c)),
    ]);
  }
}
