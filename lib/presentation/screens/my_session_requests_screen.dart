import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../presentation/blocs/live_session_bloc.dart';
import '../../presentation/blocs/live_session_bloc_provider.dart';
import '../../core/secure_storage.dart';
import 'live_session_room_screen.dart';

class MySessionRequestsScreen extends StatefulWidget {
  const MySessionRequestsScreen({super.key});

  @override
  State<MySessionRequestsScreen> createState() =>
      _MySessionRequestsScreenState();
}

class _MySessionRequestsScreenState extends State<MySessionRequestsScreen> {
  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() async {
    final token = await SecureStorage.getToken();
    if (token != null && mounted) {
      context.read<LiveSessionBloc>().add(FetchMySessionRequestsEvent(token));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Session Requests'),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: BlocBuilder<LiveSessionBloc, LiveSessionState>(
        builder: (context, state) {
          if (state is LiveSessionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SessionRequestsLoaded) {
            if (state.requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No requests yet',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Request access to live sessions to get started',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadRequests(),
              child: ListView.builder(
                itemCount: state.requests.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final request = state.requests[index];
                  final statusColor = _getStatusColor(request.status);
                  final statusIcon = _getStatusIcon(request.status);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: Icon(statusIcon, color: statusColor),
                      title: Text(request.studentName),
                      subtitle: Text('Requested: ${request.status}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          request.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Request date
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Requested: ${DateFormat('MMM d, yyyy HH:mm').format(request.requestedAt)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Feedback if any
                              if (request.feedback != null) ...[
                                Text(
                                  'Feedback',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(request.feedback!),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Rejection reason if rejected
                              if (request.status == 'rejected' &&
                                  request.rejectionReason != null) ...[
                                Text(
                                  'Reason for Rejection',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Text(request.rejectionReason!),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Status badge
                              if (request.status == 'accepted') ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('You have been accepted!'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final token = await SecureStorage.getToken();
                                      if (token == null || !context.mounted) return;
                                      // Notify backend
                                      context.read<LiveSessionBloc>().add(
                                        JoinLiveSessionEvent(request.sessionId, token),
                                      );
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LiveSessionBlocProvider(
                                            child: LiveSessionRoomScreen(
                                              sessionId: request.sessionId,
                                              sessionTitle: 'Live Session',
                                              isInstructor: false,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A237E),
                                    ),
                                    icon: const Icon(Icons.video_call,
                                        color: Colors.white),
                                    label: const Text(
                                      'Join Live Session',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          } else if (state is LiveSessionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text('Error loading requests'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadRequests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
