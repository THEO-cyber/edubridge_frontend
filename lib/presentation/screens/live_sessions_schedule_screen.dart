import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class LiveSessionsScheduleScreen extends StatefulWidget {
  const LiveSessionsScheduleScreen({super.key});

  @override
  State<LiveSessionsScheduleScreen> createState() =>
      _LiveSessionsScheduleScreenState();
}

class _LiveSessionsScheduleScreenState
    extends State<LiveSessionsScheduleScreen> {
  late Future<List<Map<String, dynamic>>> _liveSessionsFuture;

  @override
  void initState() {
    super.initState();
    _liveSessionsFuture = _fetchLiveSessions();
  }

  Future<List<Map<String, dynamic>>> _fetchLiveSessions() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Not logged in');

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = _extractList(data, [
          'liveSessions',
          'sessions',
          'data',
          'results',
          'items',
        ]);
        return List<Map<String, dynamic>>.from(sessions);
      }
      if (response.statusCode == 404) {
        return [];
      }
      throw Exception(
        'Failed to load live sessions: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  List<dynamic> _extractList(dynamic data, List<String> keys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
      }
      if (data['data'] is Map<String, dynamic> || data['data'] is List) {
        return _extractList(data['data'], keys);
      }
      throw Exception(
        'Unexpected live sessions response format: ${jsonEncode(data)}',
      );
    }
    throw Exception(
      'Unexpected live sessions response type: ${data.runtimeType}',
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[dt.weekday - 1];
      final month = months[dt.month - 1];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$dayName ${dt.day} $month · $hour:$minute $ampm';
    } catch (_) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _liveSessionsFuture,
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? [];
          final liveCount = sessions
              .where((s) =>
                  s['status'] == 'live' || s['status'] == 'ongoing')
              .length;
          final upcomingCount = sessions
              .where((s) =>
                  s['status'] == 'scheduled' || s['status'] == 'upcoming')
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _liveSessionsFuture = _fetchLiveSessions();
              });
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 160,
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kNavy, _kBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'Live Sessions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (snapshot.hasData)
                                Row(
                                  children: [
                                    _StatPill(
                                      label: 'Upcoming',
                                      count: upcomingCount,
                                      color: Colors.amber.shade700,
                                    ),
                                    const SizedBox(width: 10),
                                    _StatPill(
                                      label: 'Live Now',
                                      count: liveCount,
                                      color: Colors.red.shade600,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(color: _kNavy)),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 60, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text('Error: ${snapshot.error}',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kNavy,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _liveSessionsFuture = _fetchLiveSessions();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (sessions.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No live sessions scheduled',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check back later for upcoming sessions',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _SessionCard(
                              session: sessions[index],
                              formatDateTime: _formatDateTime,
                            ),
                        childCount: sessions.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final String Function(String) formatDateTime;

  const _SessionCard({required this.session, required this.formatDateTime});

  @override
  Widget build(BuildContext context) {
    final title = session['title'] ?? 'Live Session';
    final courseName =
        session['course']?['title'] ?? session['courseName'] ?? 'Course';
    final instructorName =
        session['instructor']?['name'] ?? session['instructorName'] ?? 'Instructor';
    final scheduledTime =
        session['scheduledAt'] ?? session['scheduledTime'] ?? '';
    final status = (session['status'] ?? 'scheduled') as String;
    final capacity = session['maxStudents'] ?? session['capacity'] ?? 0;
    final enrolledCount =
        session['enrolledCount'] ?? session['studentCount'] ?? 0;

    final isLive = status == 'live' || status == 'ongoing';
    final isUpcoming = status == 'scheduled' || status == 'upcoming';

    Color statusColor;
    if (isLive) {
      statusColor = Colors.red.shade600;
    } else if (isUpcoming) {
      statusColor = Colors.amber.shade700;
    } else {
      statusColor = Colors.grey.shade600;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with live dot + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLive) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              courseName,
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13),
            ),
            const Divider(height: 20),
            // Info rows
            _InfoRow(
              icon: Icons.access_time_rounded,
              text: scheduledTime.isNotEmpty
                  ? formatDateTime(scheduledTime)
                  : 'Time TBD',
            ),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.person_outline, text: instructorName),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.group_outlined,
              text: '$enrolledCount / $capacity enrolled',
            ),
            const SizedBox(height: 14),
            // Action button
            if (isLive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Join Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {},
                ),
              )
            else if (isUpcoming)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Set Reminder'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kNavy,
                    side: const BorderSide(color: _kNavy),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder set!')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                TextStyle(color: Colors.blueGrey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
