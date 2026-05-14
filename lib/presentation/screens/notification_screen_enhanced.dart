import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/notification_bloc.dart';

class NotificationScreenEnhanced extends StatefulWidget {
  final String? token;

  const NotificationScreenEnhanced({Key? key, this.token}) : super(key: key);

  @override
  State<NotificationScreenEnhanced> createState() =>
      _NotificationScreenEnhancedState();
}

class _NotificationScreenEnhancedState
    extends State<NotificationScreenEnhanced> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotificationsEvent(widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unreadCount = state is NotificationLoaded
                  ? state.unreadCount
                  : 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.done_all),
                ),
                onPressed: unreadCount == 0
                    ? null
                    : () {
                        context.read<NotificationBloc>().add(
                          MarkAllNotificationsReadEvent(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }
            return ListView.builder(
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _buildNotificationCard(notification);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final iconData = _getIconForType(notification['type']);
    final color = _getColorForType(notification['type']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification['read'] ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(iconData, color: color),
        ),
        title: Text(
          notification['title'],
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: notification['read']
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 4),
            Text(
              notification['time'],
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: notification['read']
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (notification['read'] == false) {
            context.read<NotificationBloc>().add(
              MarkAsReadEvent(notification['id'], widget.token ?? ''),
            );
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'course':
        return Icons.school;
      case 'assignment':
        return Icons.assignment;
      case 'live_session':
        return Icons.videocam;
      case 'certificate':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'course':
        return Colors.blue;
      case 'assignment':
        return Colors.orange;
      case 'live_session':
        return Colors.purple;
      case 'certificate':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening ${notification['title']}')));
    // Navigate to relevant screen based on type
  }
}
