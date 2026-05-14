import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NotificationEvent {}

class LoadNotificationsEvent extends NotificationEvent {
  final String? token;
  LoadNotificationsEvent(this.token);
}

class MarkAllNotificationsReadEvent extends NotificationEvent {}

class MarkAsReadEvent extends NotificationEvent {
  final String notificationId;
  final String token;
  MarkAsReadEvent(this.notificationId, this.token);
}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;
  final String token;
  DeleteNotificationEvent(this.notificationId, this.token);
}

class ReceiveNotificationEvent extends NotificationEvent {
  final Map<String, dynamic> notification;
  ReceiveNotificationEvent(this.notification);
}

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  NotificationLoaded(this.notifications, this.unreadCount);
}

class NotificationReceived extends NotificationState {
  final Map<String, dynamic> notification;
  NotificationReceived(this.notification);
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  List<Map<String, dynamic>> _notifications = [];

  NotificationBloc() : super(NotificationInitial()) {
    on<LoadNotificationsEvent>((event, emit) async {
      emit(NotificationLoading());
      try {
        _notifications = _seedNotifications();
        emit(
          NotificationLoaded(List.unmodifiable(_notifications), _unreadCount),
        );
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    });

    on<MarkAsReadEvent>((event, emit) async {
      try {
        _notifications = _notifications.map((notification) {
          if (notification['id'] == event.notificationId) {
            return {...notification, 'read': true};
          }
          return notification;
        }).toList();
        emit(
          NotificationLoaded(List.unmodifiable(_notifications), _unreadCount),
        );
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    });

    on<MarkAllNotificationsReadEvent>((event, emit) async {
      try {
        _notifications = _notifications
            .map((notification) => {...notification, 'read': true})
            .toList();
        emit(
          NotificationLoaded(List.unmodifiable(_notifications), _unreadCount),
        );
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    });

    on<DeleteNotificationEvent>((event, emit) async {
      try {
        _notifications = _notifications
            .where((notification) => notification['id'] != event.notificationId)
            .toList();
        emit(
          NotificationLoaded(List.unmodifiable(_notifications), _unreadCount),
        );
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    });

    on<ReceiveNotificationEvent>((event, emit) async {
      _notifications = [event.notification, ..._notifications];
      emit(NotificationReceived(event.notification));
      emit(NotificationLoaded(List.unmodifiable(_notifications), _unreadCount));
    });
  }

  int get _unreadCount => _notifications
      .where((notification) => notification['read'] == false)
      .length;

  List<Map<String, dynamic>> _seedNotifications() {
    return const [
      {
        'id': '1',
        'title': 'Course Started',
        'message': 'Your course "Flutter Masterclass" has started',
        'type': 'course',
        'read': false,
        'time': '2 hours ago',
      },
      {
        'id': '2',
        'title': 'New Assignment',
        'message': 'New assignment in "Advanced Dart"',
        'type': 'assignment',
        'read': false,
        'time': '4 hours ago',
      },
      {
        'id': '3',
        'title': 'Live Session Reminder',
        'message': 'Your live session starts in 1 hour',
        'type': 'live_session',
        'read': true,
        'time': '1 day ago',
      },
      {
        'id': '4',
        'title': 'Certificate Ready',
        'message': 'Your certificate for "Web Development" is ready',
        'type': 'certificate',
        'read': true,
        'time': '2 days ago',
      },
    ];
  }
}
