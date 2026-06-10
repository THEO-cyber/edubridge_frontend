import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/live_session_entity.dart';
import '../../domain/usecases/live_sessions_usecases.dart';

// ============= EVENTS =============
abstract class LiveSessionEvent {}

// Student Events
class FetchAvailableLiveSessionsEvent extends LiveSessionEvent {
  final String token;
  FetchAvailableLiveSessionsEvent(this.token);
}

class FetchLiveSessionDetailEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  FetchLiveSessionDetailEvent(this.sessionId, this.token);
}

class RequestLiveSessionEvent extends LiveSessionEvent {
  final String token;
  final String sessionId;
  final String courseId;
  RequestLiveSessionEvent(this.token, this.sessionId, this.courseId);
}

class FetchMySessionRequestsEvent extends LiveSessionEvent {
  final String token;
  FetchMySessionRequestsEvent(this.token);
}

class JoinLiveSessionEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  JoinLiveSessionEvent(this.sessionId, this.token);
}

class LeaveLiveSessionEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  LeaveLiveSessionEvent(this.sessionId, this.token);
}

// Lecturer Events
class FetchMyLiveSessionsEvent extends LiveSessionEvent {
  final String token;
  FetchMyLiveSessionsEvent(this.token);
}

class CreateLiveSessionEvent extends LiveSessionEvent {
  final String token;
  final Map<String, dynamic> data;
  CreateLiveSessionEvent(this.token, this.data);
}

class ScheduleLiveSessionEvent extends LiveSessionEvent {
  final String token;
  final String sessionId;
  final Map<String, dynamic> data;
  ScheduleLiveSessionEvent(this.token, this.sessionId, this.data);
}

class FetchSessionRequestsEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  FetchSessionRequestsEvent(this.sessionId, this.token);
}

class AcceptSessionRequestEvent extends LiveSessionEvent {
  final String requestId;
  final String token;
  final String? feedback;
  AcceptSessionRequestEvent(this.requestId, this.token, {this.feedback});
}

class RejectSessionRequestEvent extends LiveSessionEvent {
  final String requestId;
  final String token;
  final String rejectionReason;
  RejectSessionRequestEvent(this.requestId, this.token, this.rejectionReason);
}

class EndLiveSessionEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  EndLiveSessionEvent(this.sessionId, this.token);
}

class RecordAttendanceEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  final List<String> attendeeIds;
  RecordAttendanceEvent(this.sessionId, this.token, this.attendeeIds);
}

// Analytics Events
class FetchSessionAnalyticsEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  FetchSessionAnalyticsEvent(this.sessionId, this.token);
}

class FetchCourseAnalyticsEvent extends LiveSessionEvent {
  final String courseId;
  final String token;
  FetchCourseAnalyticsEvent(this.courseId, this.token);
}

class FetchOverallAnalyticsEvent extends LiveSessionEvent {
  final String token;
  FetchOverallAnalyticsEvent(this.token);
}

// Attendance Events
class FetchSessionAttendanceEvent extends LiveSessionEvent {
  final String sessionId;
  final String token;
  FetchSessionAttendanceEvent(this.sessionId, this.token);
}

class MarkAttendanceEvent extends LiveSessionEvent {
  final String sessionId;
  final String studentId;
  final String token;
  MarkAttendanceEvent(this.sessionId, this.studentId, this.token);
}

// ============= STATES =============
abstract class LiveSessionState {}

class LiveSessionInitial extends LiveSessionState {}

class LiveSessionLoading extends LiveSessionState {}

class LiveSessionLoaded extends LiveSessionState {
  final List<LiveSessionEntity> sessions;
  LiveSessionLoaded(this.sessions);
}

class LiveSessionDetailLoaded extends LiveSessionState {
  final LiveSessionEntity? session;
  LiveSessionDetailLoaded(this.session);
}

class SessionRequestsLoaded extends LiveSessionState {
  final List<LiveSessionRequestEntity> requests;
  SessionRequestsLoaded(this.requests);
}

class SessionAnalyticsLoaded extends LiveSessionState {
  final SessionAnalyticsEntity analytics;
  SessionAnalyticsLoaded(this.analytics);
}

class CourseAnalyticsLoaded extends LiveSessionState {
  final List<SessionAnalyticsEntity> analytics;
  CourseAnalyticsLoaded(this.analytics);
}

class OverallAnalyticsLoaded extends LiveSessionState {
  final Map<String, dynamic> analytics;
  OverallAnalyticsLoaded(this.analytics);
}

class SessionAttendanceLoaded extends LiveSessionState {
  final List<AttendanceRecordEntity> attendance;
  SessionAttendanceLoaded(this.attendance);
}

class LiveSessionSuccess extends LiveSessionState {
  final String message;
  LiveSessionSuccess(this.message);
}

class LiveSessionError extends LiveSessionState {
  final String message;
  LiveSessionError(this.message);
}

// ============= BLoC =============
class LiveSessionBloc extends Bloc<LiveSessionEvent, LiveSessionState> {
  final FetchAvailableLiveSessionsUseCase fetchAvailableSessionsUseCase;
  final GetLiveSessionDetailUseCase getLiveSessionDetailUseCase;
  final RequestLiveSessionUseCase requestLiveSessionUseCase;
  final FetchMySessionRequestsUseCase fetchMySessionRequestsUseCase;
  final JoinLiveSessionUseCase joinLiveSessionUseCase;
  final LeaveLiveSessionUseCase leaveLiveSessionUseCase;
  final FetchMyLiveSessionsUseCase fetchMyLiveSessionsUseCase;
  final CreateLiveSessionUseCase createLiveSessionUseCase;
  final ScheduleLiveSessionUseCase scheduleLiveSessionUseCase;
  final FetchSessionRequestsUseCase fetchSessionRequestsUseCase;
  final AcceptSessionRequestUseCase acceptSessionRequestUseCase;
  final RejectSessionRequestUseCase rejectSessionRequestUseCase;
  final EndLiveSessionUseCase endLiveSessionUseCase;
  final RecordAttendanceUseCase recordAttendanceUseCase;
  final FetchSessionAnalyticsUseCase fetchSessionAnalyticsUseCase;
  final FetchCourseSessionsAnalyticsUseCase fetchCourseSessionsAnalyticsUseCase;
  final FetchOverallAnalyticsUseCase fetchOverallAnalyticsUseCase;
  final FetchSessionAttendanceUseCase fetchSessionAttendanceUseCase;
  final MarkAttendanceUseCase markAttendanceUseCase;

  LiveSessionBloc({
    required this.fetchAvailableSessionsUseCase,
    required this.getLiveSessionDetailUseCase,
    required this.requestLiveSessionUseCase,
    required this.fetchMySessionRequestsUseCase,
    required this.joinLiveSessionUseCase,
    required this.leaveLiveSessionUseCase,
    required this.fetchMyLiveSessionsUseCase,
    required this.createLiveSessionUseCase,
    required this.scheduleLiveSessionUseCase,
    required this.fetchSessionRequestsUseCase,
    required this.acceptSessionRequestUseCase,
    required this.rejectSessionRequestUseCase,
    required this.endLiveSessionUseCase,
    required this.recordAttendanceUseCase,
    required this.fetchSessionAnalyticsUseCase,
    required this.fetchCourseSessionsAnalyticsUseCase,
    required this.fetchOverallAnalyticsUseCase,
    required this.fetchSessionAttendanceUseCase,
    required this.markAttendanceUseCase,
  }) : super(LiveSessionInitial()) {
    // Student events
    on<FetchAvailableLiveSessionsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final sessions = await fetchAvailableSessionsUseCase(event.token);
        emit(LiveSessionLoaded(sessions));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<FetchLiveSessionDetailEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final session = await getLiveSessionDetailUseCase(event.sessionId, event.token);
        emit(LiveSessionDetailLoaded(session));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<RequestLiveSessionEvent>((event, emit) async {
      try {
        await requestLiveSessionUseCase(event.token, event.sessionId, event.courseId);
        emit(LiveSessionSuccess('Request sent successfully'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<FetchMySessionRequestsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final requests = await fetchMySessionRequestsUseCase(event.token);
        emit(SessionRequestsLoaded(requests));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<JoinLiveSessionEvent>((event, emit) async {
      try {
        await joinLiveSessionUseCase(event.sessionId, event.token);
        emit(LiveSessionSuccess('Joined session successfully'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<LeaveLiveSessionEvent>((event, emit) async {
      try {
        await leaveLiveSessionUseCase(event.sessionId, event.token);
        emit(LiveSessionSuccess('Left session successfully'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    // Lecturer events
    on<FetchMyLiveSessionsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final sessions = await fetchMyLiveSessionsUseCase(event.token);
        emit(LiveSessionLoaded(sessions));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<CreateLiveSessionEvent>((event, emit) async {
      try {
        await createLiveSessionUseCase(event.token, event.data);
        emit(LiveSessionSuccess('Session created successfully'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<ScheduleLiveSessionEvent>((event, emit) async {
      try {
        await scheduleLiveSessionUseCase(event.token, event.sessionId, event.data);
        emit(LiveSessionSuccess('Session scheduled successfully'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<FetchSessionRequestsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final requests = await fetchSessionRequestsUseCase(event.sessionId, event.token);
        emit(SessionRequestsLoaded(requests));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<AcceptSessionRequestEvent>((event, emit) async {
      try {
        await acceptSessionRequestUseCase(event.requestId, event.token, feedback: event.feedback);
        emit(LiveSessionSuccess('Request accepted'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<RejectSessionRequestEvent>((event, emit) async {
      try {
        await rejectSessionRequestUseCase(event.requestId, event.token, event.rejectionReason);
        emit(LiveSessionSuccess('Request rejected'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<EndLiveSessionEvent>((event, emit) async {
      try {
        await endLiveSessionUseCase(event.sessionId, event.token);
        emit(LiveSessionSuccess('Session ended'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<RecordAttendanceEvent>((event, emit) async {
      try {
        await recordAttendanceUseCase(event.sessionId, event.token, event.attendeeIds);
        emit(LiveSessionSuccess('Attendance recorded'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    // Analytics events
    on<FetchSessionAnalyticsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final analytics = await fetchSessionAnalyticsUseCase(event.sessionId, event.token);
        emit(SessionAnalyticsLoaded(analytics));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<FetchCourseAnalyticsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final analytics = await fetchCourseSessionsAnalyticsUseCase(event.courseId, event.token);
        emit(CourseAnalyticsLoaded(analytics));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<FetchOverallAnalyticsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final analytics = await fetchOverallAnalyticsUseCase(event.token);
        emit(OverallAnalyticsLoaded(analytics));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    // Attendance events
    on<FetchSessionAttendanceEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final attendance = await fetchSessionAttendanceUseCase(event.sessionId, event.token);
        emit(SessionAttendanceLoaded(attendance));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });

    on<MarkAttendanceEvent>((event, emit) async {
      try {
        await markAttendanceUseCase(event.sessionId, event.studentId, event.token);
        emit(LiveSessionSuccess('Attendance marked'));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });
  }
}
