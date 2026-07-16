import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/notification_bloc.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class NotificationScreenEnhanced extends StatefulWidget {
  final String? token;
  const NotificationScreenEnhanced({super.key, this.token});

  @override
  State<NotificationScreenEnhanced> createState() =>
      _NotificationScreenEnhancedState();
}

class _NotificationScreenEnhancedState
    extends State<NotificationScreenEnhanced> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final t = widget.token ?? await SecureStorage.getToken();
    _token = t;
    if (mounted) {
      context.read<NotificationBloc>().add(LoadNotificationsEvent(t));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unread =
                  state is NotificationLoaded ? state.unreadCount : 0;
              return IconButton(
                tooltip: 'Mark all as read',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.done_all),
                ),
                onPressed: unread == 0
                    ? null
                    : () {
                        context
                            .read<NotificationBloc>()
                            .add(MarkAllNotificationsReadEvent());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationInitial || state is NotificationLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _kNavy));
          }
          if (state is NotificationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 56, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context
                          .read<NotificationBloc>()
                          .add(LoadNotificationsEvent(_token)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kNavy,
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: _kNavy.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded,
                          size: 48, color: _kNavy),
                    ),
                    const SizedBox(height: 16),
                    const Text('No notifications yet',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                    const SizedBox(height: 6),
                    const Text('You\'re all caught up!',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: _kNavy,
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(LoadNotificationsEvent(_token));
              },
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final n = state.notifications[index];
                  return _NotificationCard(
                    notification: n,
                    token: _token ?? '',
                    onTap: () => _onTap(context, n),
                    onDelete: () {
                      context.read<NotificationBloc>().add(
                            DeleteNotificationEvent(
                                n['id'], _token ?? ''),
                          );
                    },
                    onMarkRead: () {
                      if (n['read'] == false) {
                        context.read<NotificationBloc>().add(
                              MarkAsReadEvent(n['id'], _token ?? ''),
                            );
                      }
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onTap(BuildContext context, Map<String, dynamic> n) {
    if (n['read'] == false) {
      context
          .read<NotificationBloc>()
          .add(MarkAsReadEvent(n['id'], _token ?? ''));
    }

    // Route by the notification type (backend enum values are UPPERCASE) with
    // the actionUrl as a secondary hint. Matches case-insensitively so every
    // notification opens somewhere sensible.
    final type = (n['type'] ?? '').toString().toUpperCase();
    final url = (n['actionUrl'] ?? '').toString().toLowerCase();

    String? dest;
    if (type.contains('SESSION') || url.contains('session') || url.contains('live')) {
      dest = '/live-sessions';
    } else if (type.contains('CERTIFICATE') || url.contains('certificate')) {
      dest = '/certificates';
    } else if (type.contains('CHAT') || url.contains('chat')) {
      dest = '/chat';
    } else if (type.contains('PAYOUT') ||
        type.contains('PAYMENT') ||
        url.contains('payment') ||
        url.contains('payout')) {
      dest = '/student-dashboard';
    } else if (type.contains('ENROLLMENT') ||
        type.contains('COURSE') ||
        type.contains('PROGRESS') ||
        type.contains('REVIEW') ||
        url.contains('course') ||
        url.contains('learn')) {
      dest = '/my-courses';
    }

    if (dest != null) {
      Navigator.of(context).pushNamed(dest);
    } else {
      // Generic notification with no dedicated screen — surface its content.
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(n['title']?.toString() ?? 'Notification'),
          content: Text(n['message']?.toString() ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String token;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;

  const _NotificationCard({
    required this.notification,
    required this.token,
    required this.onTap,
    required this.onDelete,
    required this.onMarkRead,
  });

  IconData get _icon {
    switch (notification['type']) {
      case 'course':
        return Icons.menu_book_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'live_session':
        return Icons.videocam_rounded;
      case 'certificate':
        return Icons.emoji_events_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'enrollment':
        return Icons.school_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (notification['type']) {
      case 'course':
        return _kBlue;
      case 'assignment':
        return Colors.orange;
      case 'live_session':
        return Colors.purple;
      case 'certificate':
        return Colors.amber[700]!;
      case 'payment':
        return Colors.green;
      case 'enrollment':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] == true;

    return Dismissible(
      key: ValueKey(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red[600],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isRead ? 1 : 3,
        color: isRead ? Colors.white : const Color(0xFFF0F4FF),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: _color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? '',
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: _kNavy,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: _kBlue, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            _formatTime(notification['time'] ?? ''),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const Spacer(),
                          if (!isRead)
                            GestureDetector(
                              onTap: onMarkRead,
                              child: const Text('Mark read',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _kBlue,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
