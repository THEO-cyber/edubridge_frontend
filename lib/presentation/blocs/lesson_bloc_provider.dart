import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/lesson_remote_data_source.dart';
import '../../data/repositories/lesson_repository_impl.dart';
import '../../domain/usecases/fetch_lessons_usecase.dart';
import 'lesson_bloc.dart';

class LessonBlocProvider extends StatelessWidget {
  final Widget child;
  const LessonBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LessonBloc(
        fetchLessonsUseCase: FetchLessonsUseCase(
          LessonRepositoryImpl(LessonRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
