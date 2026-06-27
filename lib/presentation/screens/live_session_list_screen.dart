import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../../domain/entities/live_session_entity.dart';
import '../blocs/live_session_bloc.dart';
import '../widgets/shimmer_widgets.dart';

const _kNavy = Color(0xFF1A237E);

class LiveSessionListScreen extends StatefulWidget {
  const LiveSessionListScreen({super.key});

  @override
  State<LiveSessionListScreen> createState() => _LiveSessionListScreenState();
}

class _LiveSessionListScreenState extends State<LiveSessionListScreen> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await SecureStorage.getToken();
    if (!mounted) return;
    _token = token ?? '';
    context
        .read<LiveSessionBloc>()
        .add(FetchAvailableLiveSessionsEvent(_token!));
  }

  Future<void> _refresh() async {
    if (_token == null) return;
    context
        .read<LiveSessionBloc>()
        .add(FetchAvailableLiveSessionsEvent(_token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Live Sessions'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<LiveSessionBloc, LiveSessionState>(
        builder: (context, state) {
          if (state is LiveSessionLoading) {
            return const GenericListSkeleton();
          }

          if (state is LiveSessionLoaded) {
            if (state.sessions.isEmpty) {
              return const _EmptySessions();
            }
            return RefreshIndicator(
              color: _kNavy,
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.sessions.length,
                itemBuilder: (_, i) =>
                    _SessionCard(session: state.sessions[i], token: _token ?? ''),
              ),
            );
          }

          if (state is LiveSessionError) {
            return _ErrorView(message: state.message, onRetry: _refresh);
          }

          return const GenericListSkeleton();
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.videocam_off_outlined,
            size: 64, color: Colors.blueGrey.shade300),
        const SizedBox(height: 16),
        const Text('No live sessions available',
            style: TextStyle(fontSize: 16, color: Colors.black45)),
        const SizedBox(height: 6),
        const Text('Check back later',
            style: TextStyle(fontSize: 13, color: Colors.black26)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 52, color: Colors.red.shade300),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final LiveSessionEntity session;
  final String token;
  const _SessionCard({required this.session, required this.token});

  Color get _statusColor {
    switch (session.status.toUpperCase()) {
      case 'LIVE':
      case 'ONGOING':
        return Colors.green.shade600;
      case 'SCHEDULED':
        return const Color(0xFF1565C0);
      case 'ENDED':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get _statusIcon {
    switch (session.status.toUpperCase()) {
      case 'LIVE':
      case 'ONGOING':
        return Icons.fiber_manual_record;
      case 'SCHEDULED':
        return Icons.schedule_rounded;
      case 'ENDED':
        return Icons.check_circle_outline;
      default:
        return Icons.videocam_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_statusIcon, color: _statusColor, size: 22),
        ),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              'Scheduled: ${session.scheduledAt}',
              style:
                  const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.status.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right,
            color: Colors.grey.shade400, size: 20),
        onTap: () {
          // TODO: navigate to session detail / join
        },
      ),
    );
  }
}
