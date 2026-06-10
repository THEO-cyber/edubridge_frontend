import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/secure_storage.dart';
import '../../domain/entities/live_session_entity.dart';
import '../blocs/live_session_bloc.dart';
import '../blocs/live_session_bloc_provider.dart';
import 'live_session_room_screen.dart';

/// Wraps the screen in its own BLoC provider so it can be used standalone.
class LiveSessionScreenEnhanced extends StatelessWidget {
  const LiveSessionScreenEnhanced({super.key});

  @override
  Widget build(BuildContext context) {
    return LiveSessionBlocProvider(
      child: const _LiveSessionScreenEnhancedInner(),
    );
  }
}

class _LiveSessionScreenEnhancedInner extends StatefulWidget {
  const _LiveSessionScreenEnhancedInner();

  @override
  State<_LiveSessionScreenEnhancedInner> createState() =>
      _LiveSessionScreenEnhancedInnerState();
}

class _LiveSessionScreenEnhancedInnerState
    extends State<_LiveSessionScreenEnhancedInner> {
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty && mounted) {
      context
          .read<LiveSessionBloc>()
          .add(FetchAvailableLiveSessionsEvent(token));
    }
  }

  Future<void> _requestSession(String sessionId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty || !mounted) return;
    context.read<LiveSessionBloc>().add(
          RequestLiveSessionEvent(token, sessionId, ''),
        );
  }

  Future<void> _joinSession(LiveSessionEntity session) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty || !mounted) return;

    // Notify backend
    context
        .read<LiveSessionBloc>()
        .add(JoinLiveSessionEvent(session.id, token));

    // Navigate to the actual video room
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveSessionBlocProvider(
          child: LiveSessionRoomScreen(
            sessionId: session.id,
            sessionTitle: session.title,
            isInstructor: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Live Sessions'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: BlocConsumer<LiveSessionBloc, LiveSessionState>(
        listener: (context, state) {
          if (state is LiveSessionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is LiveSessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LiveSessionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            );
          }

          if (state is LiveSessionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSessions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is LiveSessionLoaded) {
            return _buildSessionList(state.sessions);
          }

          // Initial state — trigger load
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A237E)),
          );
        },
      ),
    );
  }

  Widget _buildSessionList(List<LiveSessionEntity> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call_outlined,
                size: 72, color: Colors.blueGrey.shade300),
            const SizedBox(height: 16),
            const Text('No live sessions available',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Check back later for upcoming sessions.',
              style: TextStyle(color: Colors.blueGrey.shade500),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final liveSessions =
        sessions.where((s) => s.status == 'ongoing').toList();
    final upcoming =
        sessions.where((s) => s.status == 'scheduled').toList();
    final completed =
        sessions.where((s) => s.status == 'completed').toList();

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: CustomScrollView(
        slivers: [
          // Live now banner
          if (liveSessions.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SectionHeader(
                    icon: Icons.circle, label: 'LIVE NOW', color: Colors.red),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _LiveSessionCard(
                    session: liveSessions[i],
                    onJoin: () => _joinSession(liveSessions[i]),
                  ),
                ),
                childCount: liveSessions.length,
              ),
            ),
          ],

          // Upcoming sessions
          if (upcoming.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: _SectionHeader(
                    icon: Icons.schedule,
                    label: 'Upcoming Sessions',
                    color: Color(0xFF1A237E)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _UpcomingSessionCard(
                    session: upcoming[i],
                    onRequest: () => _requestSession(upcoming[i].id),
                  ),
                ),
                childCount: upcoming.length,
              ),
            ),
          ],

          // Completed sessions
          if (completed.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: _SectionHeader(
                    icon: Icons.check_circle_outline,
                    label: 'Past Sessions',
                    color: Colors.grey),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _CompletedSessionCard(session: completed[i]),
                ),
                childCount: completed.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
            letterSpacing: label == label.toUpperCase() ? 0.8 : 0,
          ),
        ),
      ],
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  final LiveSessionEntity session;
  final VoidCallback onJoin;

  const _LiveSessionCard({required this.session, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.red, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PulseDot(),
                const SizedBox(width: 8),
                const Text(
                  'LIVE NOW',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people,
                          size: 12, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${session.currentParticipants}/${session.maxStudents}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              session.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'By ${session.instructorName}',
              style: TextStyle(
                  color: Colors.blueGrey.shade600, fontSize: 13),
            ),
            if (session.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                session.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.blueGrey.shade500, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.video_call, size: 18),
                label: const Text('Join Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration:
            const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

class _UpcomingSessionCard extends StatelessWidget {
  final LiveSessionEntity session;
  final VoidCallback onRequest;

  const _UpcomingSessionCard(
      {required this.session, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final scheduled =
        DateFormat('EEE, MMM d • HH:mm').format(session.scheduledAt);
    final spotsLeft = session.maxStudents - session.currentParticipants;

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text('By ${session.instructorName}',
                style: TextStyle(
                    color: Colors.blueGrey.shade600, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                _pill(Icons.access_time, scheduled,
                    const Color(0xFF1A237E)),
                const SizedBox(width: 8),
                _pill(
                  Icons.people_outline,
                  '$spotsLeft spots left',
                  spotsLeft < 5 ? Colors.orange : Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Request to Join'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _CompletedSessionCard extends StatelessWidget {
  final LiveSessionEntity session;

  const _CompletedSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.grey.shade50,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.videocam_off,
              color: Colors.grey, size: 20),
        ),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy • HH:mm').format(session.scheduledAt),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Ended',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ),
    );
  }
}
