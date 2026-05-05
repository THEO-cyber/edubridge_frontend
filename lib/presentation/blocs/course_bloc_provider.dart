import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/course_remote_data_source.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/usecases/fetch_courses_usecase.dart';
import 'course_bloc.dart';

class CourseBlocProvider extends StatelessWidget {
  final Widget child;
  const CourseBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CourseBloc(
        fetchCoursesUseCase: FetchCoursesUseCase(
          CourseRepositoryImpl(CourseRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
