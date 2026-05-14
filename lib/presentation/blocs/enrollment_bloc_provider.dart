import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/enrollment_remote_data_source.dart';
import '../../data/repositories/enrollment_repository_impl.dart';
import '../../domain/usecases/enroll_in_course_usecase.dart';
import '../../domain/usecases/fetch_enrollments_usecase.dart';
import 'enrollment_bloc.dart';

class EnrollmentBlocProvider extends StatelessWidget {
  final Widget child;
  const EnrollmentBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EnrollmentBloc(
        enrollInCourseUseCase: EnrollInCourseUseCase(
          EnrollmentRepositoryImpl(EnrollmentRemoteDataSource()),
        ),
        fetchEnrollmentsUseCase: FetchEnrollmentsUseCase(
          EnrollmentRepositoryImpl(EnrollmentRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
