import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'progress_bloc.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/datasources/progress_remote_data_source.dart';

class ProgressBlocProvider extends StatelessWidget {
  final Widget child;

  const ProgressBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final progressRepository = ProgressRepositoryImpl(
      ProgressRemoteDataSource(),
    );
    return BlocProvider(
      create: (context) => ProgressBloc(progressRepository: progressRepository),
      child: child,
    );
  }
}
