import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';

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
  String? _cachedToken;

  NotificationBloc() : super(NotificationInitial()) {
    on<LoadNotificationsEvent>((event, emit) async {
      emit(NotificationLoading());
      try {
        final token = event.token ?? await SecureStorage.getToken();
        if (token == null || token.isEmpty) {
          _notifications = [];
          emit(NotificationLoaded(const [], 0));
          return;
        }
        _cachedToken = token;

        final response = await http.get(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.notifications),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final list = data is List
              ? data
              : (data['notifications'] ?? data['data'] ?? []);
          _notifications = List<Map<String, dynamic>>.from(
            (list as List).map(_normalize),
          );
        } else {
          _notifications = [];
        }
        emit(NotificationLoaded(
            List.unmodifiable(_notifications), _unreadCount));
      } catch (e) {
        _notifications = [];
        emit(NotificationError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<MarkAsReadEvent>((event, emit) async {
      _notifications = _notifications.map((n) {
        if (n['id'] == event.notificationId) return {...n, 'read': true};
        return n;
      }).toList();
      emit(NotificationLoaded(
          List.unmodifiable(_notifications), _unreadCount));
      try {
        await http.patch(
          Uri.parse(ApiConstants.baseUrl +
              ApiConstants.notificationRead(event.notificationId)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${event.token}',
          },
        );
      } catch (_) {}
    });

    on<MarkAllNotificationsReadEvent>((event, emit) async {
      _notifications =
          _notifications.map((n) => {...n, 'read': true}).toList();
      emit(NotificationLoaded(List.unmodifiable(_notifications), 0));
      try {
        final token = _cachedToken ?? await SecureStorage.getToken();
        if (token != null) {
          await http.patch(
            Uri.parse(
                ApiConstants.baseUrl + ApiConstants.markAllNotificationsRead),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }
      } catch (_) {}
    });

    on<DeleteNotificationEvent>((event, emit) async {
      _notifications = _notifications
          .where((n) => n['id'] != event.notificationId)
          .toList();
      emit(NotificationLoaded(
          List.unmodifiable(_notifications), _unreadCount));
      try {
        await http.delete(
          Uri.parse(ApiConstants.baseUrl +
              ApiConstants.deleteNotification(event.notificationId)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${event.token}',
          },
        );
      } catch (_) {}
    });

    on<ReceiveNotificationEvent>((event, emit) async {
      _notifications = [_normalize(event.notification), ..._notifications];
      emit(NotificationReceived(event.notification));
      emit(NotificationLoaded(
          List.unmodifiable(_notifications), _unreadCount));
    });
  }

  int get _unreadCount =>
      _notifications.where((n) => n['read'] == false).length;

  static Map<String, dynamic> _normalize(dynamic raw) {
    final n = raw is Map ? raw : <String, dynamic>{};
    return {
      'id': (n['id'] ?? n['_id'] ?? '').toString(),
      'title': (n['title'] ?? n['subject'] ?? 'Notification').toString(),
      'message':
          (n['message'] ?? n['body'] ?? n['content'] ?? '').toString(),
      'type': (n['type'] ?? 'general').toString(),
      'read': n['read'] ?? n['isRead'] ?? false,
      'time': (n['createdAt'] ?? n['time'] ?? '').toString(),
    };
  }
}
