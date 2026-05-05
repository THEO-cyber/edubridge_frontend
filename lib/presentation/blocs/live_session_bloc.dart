import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/live_session_entity.dart';
import '../../domain/usecases/fetch_live_sessions_usecase.dart';

abstract class LiveSessionEvent {}

class LoadLiveSessionsEvent extends LiveSessionEvent {
  final String token;
  LoadLiveSessionsEvent(this.token);
}

abstract class LiveSessionState {}

class LiveSessionInitial extends LiveSessionState {}

class LiveSessionLoading extends LiveSessionState {}

class LiveSessionLoaded extends LiveSessionState {
  final List<LiveSessionEntity> sessions;
  LiveSessionLoaded(this.sessions);
}

class LiveSessionError extends LiveSessionState {
  final String message;
  LiveSessionError(this.message);
}

class LiveSessionBloc extends Bloc<LiveSessionEvent, LiveSessionState> {
  final FetchLiveSessionsUseCase fetchLiveSessionsUseCase;
  LiveSessionBloc({required this.fetchLiveSessionsUseCase})
    : super(LiveSessionInitial()) {
    on<LoadLiveSessionsEvent>((event, emit) async {
      emit(LiveSessionLoading());
      try {
        final sessions = await fetchLiveSessionsUseCase(event.token);
        emit(LiveSessionLoaded(sessions));
      } catch (e) {
        emit(LiveSessionError(e.toString()));
      }
    });
  }
}
