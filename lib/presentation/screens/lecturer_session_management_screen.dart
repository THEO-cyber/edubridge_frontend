import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../presentation/blocs/live_session_bloc.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/live_session_remote_data_source.dart';
import '../../data/datasources/course_remote_data_source.dart';
import 'live_classroom_screen.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);
const _kBg = Color(0xFFF5F6FA);

// ── Lecturer session list ────────────────────────────────────────────────────

class LecturerSessionManagementScreen extends StatefulWidget {
  const LecturerSessionManagementScreen({super.key});

  @override
  State<LecturerSessionManagementScreen> createState() =>
      _LecturerSessionManagementScreenState();
}

class _LecturerSessionManagementScreenState
    extends State<LecturerSessionManagementScreen> {
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _mySlots = [];
  bool _loadingAll = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _loadingAll = true);
    await Future.wait([_loadSessions(), _loadRequests(), _loadSlots()]);
    if (mounted) setState(() => _loadingAll = false);
  }

  Future<void> _loadSessions() async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty && mounted) {
      context.read<LiveSessionBloc>().add(FetchMyLiveSessionsEvent(token));
    }
  }

  Future<void> _loadRequests() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty || !mounted) return;
    try {
      final requests = await LiveSessionRemoteDataSource().fetchAllInstructorRequests(token);
      if (!mounted) return;
      setState(() {
        _pendingRequests = requests
            .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending')
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _confirmRequest(String requestId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) return;
    try {
      await LiveSessionRemoteDataSource().confirmLiveSessionRequest(requestId, token);
      _snack('Session confirmed!', Colors.green[700]!);
      _loadAll();
    } catch (e) {
      _snack('Failed: ${e.toString().replaceAll('Exception: ', '')}', Colors.red[700]!);
    }
  }

  Future<void> _loadSlots() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty || !mounted) return;
    try {
      final slots = await LiveSessionRemoteDataSource().fetchMyAvailabilitySlots(token);
      if (mounted) setState(() => _mySlots = slots);
    } catch (_) {}
  }

  Future<void> _deleteSlot(String slotId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) return;
    try {
      await LiveSessionRemoteDataSource().deleteAvailabilitySlot(slotId, token);
      _snack('Availability slot deleted', Colors.green[700]!);
      _loadAll();
    } catch (e) {
      _snack('Failed: ${e.toString().replaceAll('Exception: ', '')}', Colors.red[700]!);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) return;
    try {
      await LiveSessionRemoteDataSource().cancelSessionRequest(requestId, token);
      _snack('Request cancelled', Colors.orange[700]!);
      _loadAll();
    } catch (e) {
      _snack('Failed: ${e.toString().replaceAll('Exception: ', '')}', Colors.red[700]!);
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _openAvailabilitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetAvailabilitySheet(onSaved: _loadAll),
    );
  }

  void _openCreateGroupSessionSheet() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CreateGroupSessionSheet(onCreated: _loadAll, messenger: messenger),
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
            'Are you sure you want to delete this session? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final token = await SecureStorage.getToken();
      if (token == null || !mounted) return;
      await LiveSessionRemoteDataSource().deleteSession(sessionId, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Session deleted'),
        behavior: SnackBarBehavior.floating,
      ));
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _joinSession(String sessionId, String sessionTitle) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || !mounted) return;
      final credentials =
          await LiveSessionRemoteDataSource().joinLiveSession(sessionId, token);
      if (!mounted) return;
      final livekitUrl = (credentials['livekitUrl'] ?? '').toString();
      final accessToken = (credentials['accessToken'] ?? '').toString();
      final roomId = (credentials['roomId'] ?? sessionId).toString();
      if (livekitUrl.isEmpty || accessToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('LiveKit is not configured on the server yet.'),
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
          isInstructor: true,
        ),
      ));
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _openRescheduleSheet(dynamic session) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSessionSheet(
        session: session,
        messenger: messenger,
        onRescheduled: _loadAll,
      ),
    );
  }

  void _openApplicationsSheet(String sessionId, String sessionTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionApplicationsSheet(
        sessionId: sessionId,
        sessionTitle: sessionTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'avail',
            onPressed: _openAvailabilitySheet,
            backgroundColor: Colors.white,
            foregroundColor: _kNavy,
            elevation: 2,
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Availability',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _openCreateGroupSessionSheet,
            backgroundColor: _kNavy,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create Session',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: BlocBuilder<LiveSessionBloc, LiveSessionState>(
        builder: (context, state) {
          final sessions =
              state is LiveSessionLoaded ? state.sessions : <dynamic>[];
          final total = sessions.length;
          final scheduled = sessions
              .where((s) =>
                  (s.status ?? '').toString().toLowerCase() == 'scheduled')
              .length;
          final ongoing = sessions
              .where((s) =>
                  (s.status ?? '').toString().toLowerCase() == 'ongoing')
              .length;
          final completed = sessions
              .where((s) =>
                  (s.status ?? '').toString().toLowerCase() == 'completed')
              .length;

          return Column(
            children: [
              _buildGradientHeader(total, scheduled, ongoing, completed),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradientHeader(
      int total, int scheduled, int ongoing, int completed) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage your teaching sessions',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _HeaderStat(
                    label: 'Total',
                    value: total.toString(),
                    icon: Icons.layers_rounded,
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    label: 'Scheduled',
                    value: scheduled.toString(),
                    icon: Icons.calendar_today_outlined,
                    accent: Colors.lightBlueAccent,
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    label: 'Ongoing',
                    value: ongoing.toString(),
                    icon: Icons.videocam_rounded,
                    accent: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    label: 'Done',
                    value: completed.toString(),
                    icon: Icons.check_circle_outline_rounded,
                    accent: Colors.greenAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LiveSessionState state) {
    if (state is LiveSessionLoading && _pendingRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kNavy));
    }
    if (state is LiveSessionError && _pendingRequests.isEmpty) {
      return _ErrorState(message: state.message, onRetry: _loadAll);
    }

    final sessions = state is LiveSessionLoaded ? state.sessions : <dynamic>[];
    final hasContent = sessions.isNotEmpty || _pendingRequests.isNotEmpty || _mySlots.isNotEmpty;

    if (!hasContent && !_loadingAll && state is LiveSessionLoaded) {
      return _EmptySessionsState(onCreate: _openAvailabilitySheet);
    }

    return RefreshIndicator(
      color: _kNavy,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (_pendingRequests.isNotEmpty) ...[
            _SectionHeader(
                title: 'Pending Requests',
                count: _pendingRequests.length,
                color: Colors.orange[700]!),
            ..._pendingRequests.map((r) => _MapRequestCard(
                  request: r,
                  onConfirm: () => _confirmRequest(
                      (r['id'] ?? r['_id'] ?? '').toString()),
                  onCancel: () => _cancelRequest(
                      (r['id'] ?? r['_id'] ?? '').toString()),
                )),
            const SizedBox(height: 8),
          ],
          if (_mySlots.isNotEmpty) ...[
            _SectionHeader(
                title: 'My Availability Slots',
                count: _mySlots.length,
                color: Colors.teal[700]!),
            ..._mySlots.map((slot) => _AvailabilitySlotCard(
                  slot: slot,
                  onDelete: () => _deleteSlot(
                      (slot['id'] ?? slot['_id'] ?? '').toString()),
                )),
            const SizedBox(height: 8),
          ],
          if (sessions.isNotEmpty) ...[
            if (_pendingRequests.isNotEmpty || _mySlots.isNotEmpty)
              _SectionHeader(title: 'My Sessions', color: _kNavy),
            ...sessions.map((session) {
              final bloc = context.read<LiveSessionBloc>();
              return _SessionCard(
                session: session,
                onRequestsTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: SessionRequestsManagementScreen(
                          sessionId: session.id),
                    ),
                  ),
                ),
                onAnalyticsTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child:
                          SessionAnalyticsScreen(sessionId: session.id),
                    ),
                  ),
                ),
                onApplicationsTap: () =>
                    _openApplicationsSheet(session.id, session.title),
                onJoinTap: () => _joinSession(session.id, session.title),
                onRescheduleTap: () => _openRescheduleSheet(session),
                onDeleteTap: () => _deleteSession(session.id),
                onEndTap: () async {
                  final token = await SecureStorage.getToken();
                  if (token != null &&
                      token.isNotEmpty &&
                      context.mounted) {
                    context.read<LiveSessionBloc>().add(
                        EndLiveSessionEvent(session.id, token));
                    _loadAll();
                  }
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Header stat pill ─────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 15),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final dynamic session;
  final VoidCallback onRequestsTap;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onEndTap;
  final VoidCallback onApplicationsTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onRescheduleTap;
  final VoidCallback onJoinTap;

  const _SessionCard({
    required this.session,
    required this.onRequestsTap,
    required this.onAnalyticsTap,
    required this.onEndTap,
    required this.onApplicationsTap,
    required this.onDeleteTap,
    required this.onRescheduleTap,
    required this.onJoinTap,
  });

  Color get _statusColor {
    final s = (session.status ?? '').toString().toLowerCase();
    if (s == 'ongoing') return Colors.orange[700]!;
    if (s == 'completed') return Colors.green[700]!;
    return _kBlue;
  }

  String get _statusLabel {
    final s = (session.status ?? 'scheduled').toString();
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left bar
              Container(width: 5, color: _statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              session.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kNavy,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Meta row
                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: DateFormat('MMM d, yyyy')
                                .format(session.scheduledAt),
                          ),
                          const SizedBox(width: 8),
                          _MetaChip(
                            icon: Icons.access_time_rounded,
                            label: DateFormat('HH:mm').format(session.scheduledAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _MetaChip(
                        icon: Icons.people_outline_rounded,
                        label:
                            '${session.currentParticipants}/${session.maxStudents} students',
                      ),
                    ],
                  ),
                ),
              ),
              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black45),
                onSelected: (val) {
                  if (val == 'join') onJoinTap();
                  if (val == 'applications') onApplicationsTap();
                  if (val == 'requests') onRequestsTap();
                  if (val == 'analytics') onAnalyticsTap();
                  if (val == 'end') onEndTap();
                  if (val == 'reschedule') onRescheduleTap();
                  if (val == 'delete') onDeleteTap();
                },
                itemBuilder: (_) => [
                  if ((session.status ?? '').toString().toLowerCase() != 'completed')
                    const PopupMenuItem(
                      value: 'join',
                      child: Row(children: [
                        Icon(Icons.videocam_rounded, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Start / Join Session',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'applications',
                    child: Row(children: [
                      Icon(Icons.people_alt_outlined, size: 18, color: _kNavy),
                      SizedBox(width: 8),
                      Text('Manage Applications',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: _kNavy)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'analytics',
                    child: Row(children: [
                      Icon(Icons.bar_chart_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('View Analytics'),
                    ]),
                  ),
                  if ((session.status ?? '').toString().toLowerCase() !=
                      'completed')
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: Row(children: [
                        Icon(Icons.edit_calendar_rounded,
                            size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Reschedule',
                            style: TextStyle(color: Colors.teal)),
                      ]),
                    ),
                  if ((session.status ?? '').toString().toLowerCase() ==
                      'ongoing')
                    const PopupMenuItem(
                      value: 'end',
                      child: Row(children: [
                        Icon(Icons.stop_circle_outlined,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('End Session',
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Session',
                          style: TextStyle(color: Colors.red)),
                    ]),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.black45),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

// ── Empty / Error states ─────────────────────────────────────────────────────

class _EmptySessionsState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptySessionsState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const Text(
              'No live sessions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set your available time slots so\nstudents can request sessions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.schedule, color: Colors.white),
              label: const Text('Set Availability',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: Colors.blueGrey[200]),
            const SizedBox(height: 16),
            const Text('Could not load sessions',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
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
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color color;
  const _SectionHeader({required this.title, this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Map Request Card (for raw API responses) ──────────────────────────────────

class _MapRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _MapRequestCard({required this.request, required this.onConfirm, required this.onCancel});

  String _studentName() {
    final student = request['student'];
    if (student is Map) {
      final first = (student['firstName'] ?? student['first_name'] ?? '').toString();
      final last = (student['lastName'] ?? student['last_name'] ?? '').toString();
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      return (student['name'] ?? student['username'] ?? '').toString();
    }
    return (request['studentName'] ?? 'Student').toString();
  }

  String _requestedTime() {
    final raw = request['scheduledAt'] ?? request['requestedAt'] ?? request['createdAt'];
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat('MMM d, yyyy  HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final name = _studentName();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final time = _requestedTime();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 22, backgroundColor: _kNavy, child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: _kNavy, fontSize: 14)),
                      if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Set Availability Bottom Sheet ─────────────────────────────────────────────

class _SetAvailabilitySheet extends StatefulWidget {
  final Future<void> Function()? onSaved;
  const _SetAvailabilitySheet({this.onSaved});

  @override
  State<_SetAvailabilitySheet> createState() => _SetAvailabilitySheetState();
}

class _SetAvailabilitySheetState extends State<_SetAvailabilitySheet> {
  int _dayOfWeek = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  int _sessionDuration = 60;
  bool _submitting = false;
  late String _selectedTz;

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // label → IANA value. Note: backend has @MinLength(15) so short names like
  // "Africa/Lagos" (12 chars) are rejected — using equivalent ≥15-char names.
  static const _tzEntries = <Map<String, String>>[
    // ── West Africa (UTC+1) — put first ──────────────────────────────
    {'label': 'West Africa – Lagos / Accra (UTC+1)', 'value': 'Africa/Porto-Novo'},
    {'label': 'West Africa – Abuja / Dakar (UTC+1)', 'value': 'Africa/Kinshasa'},
    {'label': 'West Africa – Libreville (UTC+1)',    'value': 'Africa/Libreville'},
    // ── Rest of Africa ───────────────────────────────────────────────
    {'label': 'South Africa – Johannesburg (UTC+2)', 'value': 'Africa/Johannesburg'},
    {'label': 'East Africa – Nairobi (UTC+3)',       'value': 'Africa/Addis_Ababa'},
    {'label': 'North Africa – Cairo (UTC+2)',        'value': 'Africa/Khartoum'},
    {'label': 'North Africa – Casablanca (UTC+0)',   'value': 'Atlantic/Reykjavik'},
    // ── Europe ───────────────────────────────────────────────────────
    {'label': 'UK / Ireland – London (UTC+0)',       'value': 'Atlantic/Reykjavik'},
    {'label': 'Central Europe – Paris / Berlin (UTC+1)', 'value': 'Europe/Amsterdam'},
    {'label': 'Eastern Europe – Istanbul (UTC+3)',   'value': 'Europe/Istanbul'},
    {'label': 'Russia – Moscow (UTC+3)',             'value': 'Europe/Volgograd'},
    // ── Americas ─────────────────────────────────────────────────────
    {'label': 'Eastern US / Canada (UTC-5)',         'value': 'America/New_York'},
    {'label': 'Central US (UTC-6)',                  'value': 'America/Chicago'},
    {'label': 'Mountain US (UTC-7)',                 'value': 'America/Denver'},
    {'label': 'Pacific US (UTC-8)',                  'value': 'America/Los_Angeles'},
    {'label': 'Brazil – São Paulo (UTC-3)',          'value': 'America/Sao_Paulo'},
    // ── Asia ─────────────────────────────────────────────────────────
    {'label': 'India (UTC+5:30)',                    'value': 'Asia/Kuala_Lumpur'},
    {'label': 'Gulf – Dubai / Riyadh (UTC+4)',       'value': 'Asia/Muscat'},
    {'label': 'SE Asia – Bangkok / Jakarta (UTC+7)', 'value': 'Asia/Bangkok'},
    {'label': 'SE Asia – Singapore / KL (UTC+8)',    'value': 'Asia/Kuala_Lumpur'},
    {'label': 'China / Hong Kong (UTC+8)',           'value': 'Asia/Hong_Kong'},
    {'label': 'Japan / Korea (UTC+9)',               'value': 'Asia/Pyongyang'},
    // ── Pacific / Australia ──────────────────────────────────────────
    {'label': 'Australia – Sydney (UTC+10)',         'value': 'Australia/Sydney'},
    {'label': 'New Zealand (UTC+12)',                'value': 'Pacific/Auckland'},
    {'label': 'UTC (no offset)',                     'value': 'Atlantic/Reykjavik'},
  ];

  String _guessValue() {
    final h = DateTime.now().timeZoneOffset.inHours;
    if (h == 1) return 'Africa/Porto-Novo';
    if (h == 2) return 'Africa/Johannesburg';
    if (h == 3) return 'Africa/Addis_Ababa';
    if (h == -5) return 'America/New_York';
    if (h == -6) return 'America/Chicago';
    if (h == -8) return 'America/Los_Angeles';
    if (h == 8) return 'Asia/Kuala_Lumpur';
    return 'Africa/Porto-Novo';
  }

  @override
  void initState() {
    super.initState();
    _selectedTz = _guessValue();
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _kNavy, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) {
      setState(() => isStart ? _startTime = t : _endTime = t);
    }
  }

  Future<void> _submit() async {
    if (_startTime.hour * 60 + _startTime.minute >= _endTime.hour * 60 + _endTime.minute) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty || !mounted) { setState(() => _submitting = false); return; }
      await LiveSessionRemoteDataSource().setAvailability(token, {
        'dayOfWeek': _dayOfWeek,
        'startTime': _fmt(_startTime),
        'endTime': _fmt(_endTime),
        'timezone': _selectedTz,
        'sessionDuration': _sessionDuration,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Availability saved!'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, mq.viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _kNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.schedule, color: _kNavy, size: 22)),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Set Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _kNavy)),
              Text('Students can request sessions in these slots', style: TextStyle(color: Colors.black45, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 24),
          _FieldLabel('Day of Week'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (i) {
                final selected = _dayOfWeek == i;
                return GestureDetector(
                  onTap: () => setState(() => _dayOfWeek = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _kNavy : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_days[i], style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: selected ? Colors.white : Colors.black54,
                    )),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FieldLabel('Start Time'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _pickTime(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.access_time, color: _kBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600, color: _kNavy)),
                  ]),
                ),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FieldLabel('End Time'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _pickTime(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.access_time, color: _kBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(_endTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600, color: _kNavy)),
                  ]),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 20),
          _FieldLabel('Session Duration (minutes)'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: _kBlue, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('$_sessionDuration min',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: _kNavy)),
                ),
                _DurationBtn(icon: Icons.remove, onTap: () {
                  if (_sessionDuration > 15) setState(() => _sessionDuration -= 15);
                }),
                const SizedBox(width: 8),
                _DurationBtn(icon: Icons.add, onTap: () {
                  setState(() => _sessionDuration += 15);
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _FieldLabel('Timezone'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedTz,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.public, color: _kBlue, size: 19),
              filled: true,
              fillColor: const Color(0xFFF0F4FF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF263238)),
            items: _tzEntries.map((e) => DropdownMenuItem(
              value: e['value'],
              child: Text(e['label']!, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedTz = v); },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Availability Slot Card ────────────────────────────────────────────────────

class _AvailabilitySlotCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  final VoidCallback onDelete;
  const _AvailabilitySlotCard({required this.slot, required this.onDelete});

  static const _daysFull = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];
  static const _daysShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _dayFull() {
    final d = (slot['dayOfWeek'] as num?)?.toInt() ?? 0;
    return (d >= 0 && d < _daysFull.length) ? _daysFull[d] : 'Day $d';
  }

  String _dayShort() {
    final d = (slot['dayOfWeek'] as num?)?.toInt() ?? 0;
    return (d >= 0 && d < _daysShort.length) ? _daysShort[d] : 'D$d';
  }

  String _friendlyTz(String raw) {
    // Strip continent prefix for display: "Africa/Porto-Novo" → "Porto-Novo"
    final parts = raw.split('/');
    return parts.length > 1 ? parts.last.replaceAll('_', ' ') : raw;
  }

  @override
  Widget build(BuildContext context) {
    final dayFull = _dayFull();
    final dayShort = _dayShort();
    final start = slot['startTime']?.toString() ?? '--:--';
    final end = slot['endTime']?.toString() ?? '--:--';
    final duration = (slot['sessionDuration'] as num?)?.toInt() ?? 0;
    final tz = slot['timezone']?.toString() ?? '';
    final tzDisplay = tz.isNotEmpty ? _friendlyTz(tz) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Teal left bar
              Container(width: 5, color: Colors.teal[700]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: day badge + status chip + delete
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal[700]!.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dayShort,
                              style: TextStyle(
                                color: Colors.teal[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dayFull,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kNavy,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[700],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: Colors.red[400], size: 19),
                            onPressed: onDelete,
                            padding: const EdgeInsets.only(left: 4),
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Time range
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.black38),
                          const SizedBox(width: 5),
                          Text(
                            '$start – $end',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _kNavy,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.timer_outlined,
                              size: 14, color: Colors.black38),
                          const SizedBox(width: 5),
                          Text(
                            '$duration min / session',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      if (tzDisplay.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.public_rounded,
                                size: 14, color: Colors.black38),
                            const SizedBox(width: 5),
                            Text(
                              tzDisplay,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
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
}

// ── Reschedule Session Sheet ──────────────────────────────────────────────────

class _RescheduleSessionSheet extends StatefulWidget {
  final dynamic session;
  final ScaffoldMessengerState? messenger;
  final Future<void> Function()? onRescheduled;
  const _RescheduleSessionSheet(
      {required this.session, this.messenger, this.onRescheduled});

  @override
  State<_RescheduleSessionSheet> createState() =>
      _RescheduleSessionSheetState();
}

class _RescheduleSessionSheetState extends State<_RescheduleSessionSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final raw = widget.session?.scheduledAt;
    final dt = raw is DateTime ? raw : DateTime.tryParse(raw?.toString() ?? '');
    final local = (dt ?? DateTime.now().add(const Duration(days: 1))).toLocal();
    _date = DateTime(local.year, local.month, local.day);
    _time = TimeOfDay(hour: local.hour, minute: local.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now().add(const Duration(days: 1)) : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || !mounted) {
        setState(() => _submitting = false);
        return;
      }
      final scheduled = DateTime(
              _date.year, _date.month, _date.day, _time.hour, _time.minute)
          .toUtc();
      if (scheduled.isBefore(DateTime.now().toUtc())) {
        setState(() {
          _submitting = false;
          _error = 'Scheduled time must be in the future';
        });
        return;
      }
      await LiveSessionRemoteDataSource()
          .rescheduleSession(widget.session.id, token, scheduled);
      if (!mounted) return;
      Navigator.pop(context);
      (widget.messenger ?? ScaffoldMessenger.of(context)).showSnackBar(SnackBar(
        content: const Text('Session rescheduled successfully'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await widget.onRescheduled?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final formatted =
        '${_date.day}/${_date.month}/${_date.year}  ${_time.format(context)}';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, mq.viewInsets.bottom + 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(Icons.error_outline_rounded,
                    size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13))),
              ]),
            ),
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_calendar_rounded,
                    color: Colors.teal, size: 22)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Reschedule Session',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _kNavy)),
              Text(
                (widget.session?.title ?? '').toString(),
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ]),
          ]),
          const SizedBox(height: 24),
          const Text('New Date & Time',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black54)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: _kBlue),
                    const SizedBox(width: 8),
                    Text(
                        '${_date.day}/${_date.month}/${_date.year}',
                        style: const TextStyle(fontSize: 14)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: _kBlue),
                    const SizedBox(width: 8),
                    Text(_time.format(context),
                        style: const TextStyle(fontSize: 14)),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text('New time: $formatted',
              style:
                  const TextStyle(fontSize: 12, color: Colors.black38)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Reschedule',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Group Session Sheet ────────────────────────────────────────────────

class _CreateGroupSessionSheet extends StatefulWidget {
  final Future<void> Function()? onCreated;
  final ScaffoldMessengerState? messenger;
  const _CreateGroupSessionSheet({this.onCreated, this.messenger});

  @override
  State<_CreateGroupSessionSheet> createState() =>
      _CreateGroupSessionSheetState();
}

class _CreateGroupSessionSheetState extends State<_CreateGroupSessionSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 0);
  int _durationMinutes = 60;
  int _maxStudents = 30;
  bool _submitting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  bool _loadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;
      final response =
          await CourseRemoteDataSource().fetchInstructorCourses(token);
      if (mounted) {
        setState(() {
          _courses = response;
          _selectedCourseId = null; // instructor must explicitly pick a course
          _loadingCourses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
              primary: _kNavy, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _scheduledDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
              primary: _kNavy, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => _scheduledTime = t);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Session title is required');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || !mounted) {
        setState(() => _submitting = false);
        return;
      }
      final scheduled = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      ).toUtc();
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'scheduledAt': scheduled.toIso8601String(),
        'duration': _durationMinutes,
        'maxStudents': _maxStudents,
      };
      if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
        body['courseId'] = _selectedCourseId;
      }
      await LiveSessionRemoteDataSource().createGroupLiveSession(token, body);
      if (!mounted) return;
      Navigator.pop(context);
      (widget.messenger ?? ScaffoldMessenger.of(context)).showSnackBar(SnackBar(
        content: const Text('Session created! Students can now apply.'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await widget.onCreated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, mq.viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: Colors.red.shade400),
                    ),
                  ],
                ),
              ),
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _kNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.videocam_rounded,
                      color: _kNavy, size: 22)),
              const SizedBox(width: 12),
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Live Session',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _kNavy)),
                    Text('Students will apply and you confirm',
                        style:
                            TextStyle(color: Colors.black45, fontSize: 12)),
                  ]),
            ]),
            const SizedBox(height: 24),
            _FieldLabel('Session Title *'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Introduction to Flutter',
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Description (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What will you cover in this session?',
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            if (!_loadingCourses && _courses.isNotEmpty) ...[
              const SizedBox(height: 16),
              _FieldLabel('Course'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCourseId,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.school_outlined, color: _kBlue, size: 19),
                  filled: true,
                  fillColor: const Color(0xFFF0F4FF),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF263238)),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('— No specific course —',
                        style: TextStyle(color: Colors.black45)),
                  ),
                  ..._courses.map((c) => DropdownMenuItem<String>(
                        value: (c['id'] ?? c['_id'])?.toString(),
                        child: Text(
                            (c['title'] ?? 'Untitled').toString(),
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedCourseId = v),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Date'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: _kBlue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                                DateFormat('MMM d, yyyy')
                                    .format(_scheduledDate),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _kNavy)),
                          ]),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Time'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.access_time_rounded,
                                color: _kBlue, size: 18),
                            const SizedBox(width: 8),
                            Text(_scheduledTime.format(context),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _kNavy)),
                          ]),
                        ),
                      ),
                    ]),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Duration (min)'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.timer_outlined,
                              color: _kBlue, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text('$_durationMinutes min',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _kNavy))),
                          _DurationBtn(
                              icon: Icons.remove,
                              onTap: () {
                                if (_durationMinutes > 30)
                                  setState(() => _durationMinutes -= 15);
                              }),
                          const SizedBox(width: 6),
                          _DurationBtn(
                              icon: Icons.add,
                              onTap: () =>
                                  setState(() => _durationMinutes += 15)),
                        ]),
                      ),
                    ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Max Students'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.people_outline_rounded,
                              color: _kBlue, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text('$_maxStudents',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _kNavy))),
                          _DurationBtn(
                              icon: Icons.remove,
                              onTap: () {
                                if (_maxStudents > 5)
                                  setState(() => _maxStudents -= 5);
                              }),
                          const SizedBox(width: 6),
                          _DurationBtn(
                              icon: Icons.add,
                              onTap: () =>
                                  setState(() => _maxStudents += 5)),
                        ]),
                      ),
                    ]),
              ),
            ]),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Create Session',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black45)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session Applications Sheet ────────────────────────────────────────────────

class _SessionApplicationsSheet extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  const _SessionApplicationsSheet(
      {required this.sessionId, required this.sessionTitle});

  @override
  State<_SessionApplicationsSheet> createState() =>
      _SessionApplicationsSheetState();
}

class _SessionApplicationsSheetState
    extends State<_SessionApplicationsSheet> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String? _error;
  bool _notifying = false;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');
      final list = await LiveSessionRemoteDataSource()
          .fetchApplicationsForSession(widget.sessionId, token);
      if (mounted) setState(() {
        _applications = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _accept(String appId) async {
    final token = await SecureStorage.getToken();
    if (token == null) return;
    try {
      await LiveSessionRemoteDataSource().acceptApplication(appId, token);
      _snack('Student accepted! Notification sent.', Colors.green[700]!);
      _loadApplications();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), Colors.red[700]!);
    }
  }

  Future<void> _reject(String appId) async {
    final token = await SecureStorage.getToken();
    if (token == null) return;
    try {
      await LiveSessionRemoteDataSource().rejectApplication(appId, token);
      _snack('Application rejected.', Colors.orange[700]!);
      _loadApplications();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), Colors.red[700]!);
    }
  }

  Future<void> _notifyAll() async {
    final token = await SecureStorage.getToken();
    if (token == null) return;
    setState(() => _notifying = true);
    try {
      await LiveSessionRemoteDataSource()
          .notifyAcceptedStudents(widget.sessionId, token);
      _snack('Notification sent to all accepted students!',
          Colors.green[700]!);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), Colors.red[700]!);
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _studentName(Map<String, dynamic> app) {
    final s = app['student'];
    if (s is Map) {
      final first =
          (s['firstName'] ?? s['first_name'] ?? '').toString();
      final last = (s['lastName'] ?? s['last_name'] ?? '').toString();
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      return (s['name'] ?? s['username'] ?? '').toString();
    }
    return (app['studentName'] ?? 'Student').toString();
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _applications
        .where((a) =>
            (a['status'] ?? '').toString().toLowerCase() == 'accepted' ||
            (a['status'] ?? '').toString().toLowerCase() == 'in_progress')
        .length;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Center(
            child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: _kNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.people_alt_outlined,
                        color: _kNavy, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.sessionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kNavy)),
                        Text(
                            '${_applications.length} application(s) · $accepted accepted',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black45)),
                      ]),
                ),
                if (accepted > 0)
                  TextButton.icon(
                    onPressed: _notifying ? null : _notifyAll,
                    icon: _notifying
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.notifications_outlined, size: 16),
                    label: const Text('Notify All',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: _kNavy),
                  ),
              ],
            ),
          ),
          const Divider(height: 20),
          // Body
          Flexible(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kNavy))
                : _error != null
                    ? Center(
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red[300], size: 36),
                          const SizedBox(height: 8),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 12),
                          TextButton(
                              onPressed: _loadApplications,
                              child: const Text('Retry')),
                        ],
                      ))
                    : _applications.isEmpty
                        ? Center(
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.blueGrey[200]),
                              const SizedBox(height: 10),
                              const Text('No applications yet',
                                  style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: 14)),
                            ],
                          ))
                        : RefreshIndicator(
                            color: _kNavy,
                            onRefresh: _loadApplications,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 20),
                              itemCount: _applications.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final app = _applications[i];
                                final appId =
                                    (app['id'] ?? app['_id'] ?? '')
                                        .toString();
                                final name = _studentName(app);
                                final initial = name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?';
                                final status = (app['status'] ?? 'pending')
                                    .toString()
                                    .toLowerCase();
                                final isAccepted = status == 'accepted' ||
                                    status == 'approved' ||
                                    status == 'in_progress';
                                final isRejected = status == 'rejected' ||
                                    status == 'denied' ||
                                    status == 'declined';
                                final isPending = !isAccepted && !isRejected;
                                final statusColor = isAccepted
                                    ? Colors.green[700]!
                                    : isRejected
                                        ? Colors.red[700]!
                                        : Colors.amber[700]!;
                                final statusLabel = isAccepted
                                    ? 'Accepted'
                                    : isRejected
                                        ? 'Rejected'
                                        : 'Pending';

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                          radius: 20,
                                          backgroundColor: _kNavy,
                                          child: Text(initial,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 13)),
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(
                                                      top: 3),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                              ),
                                              child: Text(statusLabel,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: statusColor)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isPending) ...[
                                        IconButton(
                                          icon: Icon(Icons.close_rounded,
                                              color: Colors.red[400],
                                              size: 20),
                                          onPressed: () =>
                                              _reject(appId),
                                          tooltip: 'Reject',
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32),
                                        ),
                                        const SizedBox(width: 4),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _accept(appId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green[700],
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8)),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: const Text('Accept',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DurationBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DurationBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: _kNavy, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF37474F),
      ),
    );
  }
}

// ── Session Requests Management ───────────────────────────────────────────────

class SessionRequestsManagementScreen extends StatefulWidget {
  final String sessionId;
  const SessionRequestsManagementScreen({super.key, required this.sessionId});

  @override
  State<SessionRequestsManagementScreen> createState() =>
      _SessionRequestsManagementScreenState();
}

class _SessionRequestsManagementScreenState
    extends State<SessionRequestsManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty && mounted) {
      context.read<LiveSessionBloc>().add(
            FetchSessionRequestsEvent(widget.sessionId, token),
          );
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty || !mounted) return;
    context.read<LiveSessionBloc>().add(
          AcceptSessionRequestEvent(requestId, token,
              feedback: 'Welcome to the session!'),
        );
    await Future.delayed(const Duration(milliseconds: 400));
    await _loadRequests();
  }

  Future<void> _rejectRequest(String requestId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty || !mounted) return;
    context.read<LiveSessionBloc>().add(
          RejectSessionRequestEvent(
            requestId,
            token,
            'The session is full. Please try another session.',
          ),
        );
    await Future.delayed(const Duration(milliseconds: 400));
    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Student Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kNavy, _kBlue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: BlocBuilder<LiveSessionBloc, LiveSessionState>(
        builder: (context, state) {
          if (state is LiveSessionLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _kNavy));
          } else if (state is SessionRequestsLoaded) {
            if (state.requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 56, color: Colors.blueGrey[200]),
                    const SizedBox(height: 14),
                    const Text('No pending requests',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black45)),
                  ],
                ),
              );
            }

            final pending =
                state.requests.where((r) => r.status == 'pending').toList();
            final processed =
                state.requests.where((r) => r.status != 'pending').toList();

            return RefreshIndicator(
              color: _kNavy,
              onRefresh: _loadRequests,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pending.isNotEmpty) ...[
                      Text(
                        'Pending (${pending.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _kNavy),
                      ),
                      const SizedBox(height: 10),
                      ...pending.map((r) => _RequestCard(
                            request: r,
                            onAccept: () => _acceptRequest(r.id),
                            onReject: () => _rejectRequest(r.id),
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (processed.isNotEmpty) ...[
                      Text(
                        'Processed (${processed.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _kNavy),
                      ),
                      const SizedBox(height: 10),
                      ...processed.map((r) => _ProcessedCard(request: r)),
                    ],
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (request.studentName.isNotEmpty)
        ? request.studentName[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _kNavy,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _kNavy,
                              fontSize: 14)),
                      Text(request.studentEmail,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Pending',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessedCard extends StatelessWidget {
  final dynamic request;
  const _ProcessedCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isAccepted = request.status == 'accepted';
    final color = isAccepted ? Colors.green[700]! : Colors.red[700]!;
    final initial = (request.studentName.isNotEmpty)
        ? request.studentName[0].toUpperCase()
        : '?';
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
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(initial,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
        title: Text(request.studentName,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: _kNavy)),
        subtitle: Text(request.studentEmail,
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isAccepted ? 'Accepted' : 'Rejected',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}

// ── Session Analytics Screen ──────────────────────────────────────────────────

class SessionAnalyticsScreen extends StatefulWidget {
  final String sessionId;
  const SessionAnalyticsScreen({super.key, required this.sessionId});

  @override
  State<SessionAnalyticsScreen> createState() =>
      _SessionAnalyticsScreenState();
}

class _SessionAnalyticsScreenState extends State<SessionAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() async {
    final token = await SecureStorage.getToken();
    if (token != null && mounted) {
      context.read<LiveSessionBloc>().add(
            FetchSessionAnalyticsEvent(widget.sessionId, token),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: BlocBuilder<LiveSessionBloc, LiveSessionState>(
        builder: (context, state) {
          final sessionTitle = state is SessionAnalyticsLoaded
              ? state.analytics.sessionTitle
              : '';

          return CustomScrollView(
            slivers: [
              // ── Collapsing header ──────────────────────────────────────
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                expandedHeight: 130,
                backgroundColor: _kNavy,
                title: const Text(
                  'Session Analytics',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
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
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.videocam_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                sessionTitle.isNotEmpty
                                    ? sessionTitle
                                    : 'Session Analytics',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body content ───────────────────────────────────────────
              if (state is LiveSessionLoading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(color: _kNavy)),
                )
              else if (state is LiveSessionError)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 52, color: Colors.blueGrey[200]),
                          const SizedBox(height: 14),
                          const Text('Analytics unavailable',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black54)),
                          const SizedBox(height: 6),
                          Text(state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.black38, fontSize: 13)),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _loadAnalytics,
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
                  ),
                )
              else if (state is SessionAnalyticsLoaded)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _AnalyticsTile(
                              title: 'Enrolled',
                              value: state.analytics.totalStudentsEnrolled
                                  .toString(),
                              icon: Icons.people_outline_rounded,
                              color: _kBlue,
                            ),
                            _AnalyticsTile(
                              title: 'Requests',
                              value: state.analytics.totalRequestsReceived
                                  .toString(),
                              icon: Icons.mail_outline_rounded,
                              color: Colors.orange[700]!,
                            ),
                            _AnalyticsTile(
                              title: 'Accepted',
                              value:
                                  state.analytics.totalAccepted.toString(),
                              icon: Icons.check_circle_outline_rounded,
                              color: Colors.green[700]!,
                            ),
                            _AnalyticsTile(
                              title: 'Rejected',
                              value:
                                  state.analytics.totalRejected.toString(),
                              icon: Icons.cancel_outlined,
                              color: Colors.red[700]!,
                            ),
                            _AnalyticsTile(
                              title: 'Attended',
                              value:
                                  state.analytics.totalAttended.toString(),
                              icon: Icons.how_to_reg_rounded,
                              color: Colors.purple[600]!,
                            ),
                            _AnalyticsTile(
                              title: 'Attendance',
                              value:
                                  '${state.analytics.averageAttendancePercentage.toStringAsFixed(1)}%',
                              icon: Icons.assessment_outlined,
                              color: Colors.teal[600]!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _InfoTile(
                          icon: Icons.timer_outlined,
                          title: 'Session Duration',
                          value:
                              '${state.analytics.totalDuration} minutes',
                        ),
                        if (state.analytics.feedbackNotes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Feedback Notes',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kNavy),
                          ),
                          const SizedBox(height: 10),
                          ...state.analytics.feedbackNotes
                              .map((note) => Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.04),
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.note_alt_outlined,
                                            size: 16, color: _kBlue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(note,
                                                style: const TextStyle(
                                                    fontSize: 13))),
                                      ],
                                    ),
                                  )),
                        ],
                      ],
                    ),
                  ),
                )
              else
                const SliverFillRemaining(child: SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: color)),
            Text(title,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kNavy, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black45)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _kNavy)),
            ],
          ),
        ],
      ),
    );
  }
}
