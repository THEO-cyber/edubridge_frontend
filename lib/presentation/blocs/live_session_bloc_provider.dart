import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/live_session_remote_data_source.dart';
import '../../data/repositories/live_session_repository_impl.dart';
import '../../domain/usecases/fetch_live_sessions_usecase.dart';
import 'live_session_bloc.dart';

class LiveSessionBlocProvider extends StatelessWidget {
  final Widget child;
  const LiveSessionBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveSessionBloc(
        fetchLiveSessionsUseCase: FetchLiveSessionsUseCase(
          LiveSessionRepositoryImpl(LiveSessionRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
