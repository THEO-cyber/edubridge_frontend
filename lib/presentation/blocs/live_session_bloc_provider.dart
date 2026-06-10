import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/live_session_remote_data_source.dart';
import '../../data/repositories/live_session_repository_impl.dart';
import '../../domain/usecases/live_sessions_usecases.dart';
import 'live_session_bloc.dart';

class LiveSessionBlocProvider extends StatelessWidget {
  final Widget child;
  const LiveSessionBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final repository = LiveSessionRepositoryImpl(LiveSessionRemoteDataSource());

    return BlocProvider(
      create: (_) => LiveSessionBloc(
        fetchAvailableSessionsUseCase: FetchAvailableLiveSessionsUseCase(repository),
        getLiveSessionDetailUseCase: GetLiveSessionDetailUseCase(repository),
        requestLiveSessionUseCase: RequestLiveSessionUseCase(repository),
        fetchMySessionRequestsUseCase: FetchMySessionRequestsUseCase(repository),
        joinLiveSessionUseCase: JoinLiveSessionUseCase(repository),
        leaveLiveSessionUseCase: LeaveLiveSessionUseCase(repository),
        fetchMyLiveSessionsUseCase: FetchMyLiveSessionsUseCase(repository),
        createLiveSessionUseCase: CreateLiveSessionUseCase(repository),
        scheduleLiveSessionUseCase: ScheduleLiveSessionUseCase(repository),
        fetchSessionRequestsUseCase: FetchSessionRequestsUseCase(repository),
        acceptSessionRequestUseCase: AcceptSessionRequestUseCase(repository),
        rejectSessionRequestUseCase: RejectSessionRequestUseCase(repository),
        endLiveSessionUseCase: EndLiveSessionUseCase(repository),
        recordAttendanceUseCase: RecordAttendanceUseCase(repository),
        fetchSessionAnalyticsUseCase: FetchSessionAnalyticsUseCase(repository),
        fetchCourseSessionsAnalyticsUseCase: FetchCourseSessionsAnalyticsUseCase(repository),
        fetchOverallAnalyticsUseCase: FetchOverallAnalyticsUseCase(repository),
        fetchSessionAttendanceUseCase: FetchSessionAttendanceUseCase(repository),
        markAttendanceUseCase: MarkAttendanceUseCase(repository),
      ),
      child: child,
    );
  }
}
