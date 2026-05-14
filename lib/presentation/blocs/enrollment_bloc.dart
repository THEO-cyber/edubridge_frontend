import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/enroll_in_course_usecase.dart';
import '../../domain/usecases/fetch_enrollments_usecase.dart';

abstract class EnrollmentEvent {}

class EnrollEvent extends EnrollmentEvent {
  final String courseId;
  final String token;
  EnrollEvent(this.courseId, this.token);
}

class FetchEnrollmentsEvent extends EnrollmentEvent {
  final String token;
  FetchEnrollmentsEvent(this.token);
}

abstract class EnrollmentState {}

class EnrollmentInitial extends EnrollmentState {}

class EnrollmentLoading extends EnrollmentState {}

class EnrollmentsLoaded extends EnrollmentState {
  final List<Map<String, dynamic>> enrollments;
  EnrollmentsLoaded(this.enrollments);
}

class EnrollmentSuccess extends EnrollmentState {}

class EnrollmentFailure extends EnrollmentState {
  final String message;
  EnrollmentFailure(this.message);
}

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final EnrollInCourseUseCase enrollInCourseUseCase;
  final FetchEnrollmentsUseCase fetchEnrollmentsUseCase;
  EnrollmentBloc({
    required this.enrollInCourseUseCase,
    required this.fetchEnrollmentsUseCase,
  }) : super(EnrollmentInitial()) {
    on<EnrollEvent>((event, emit) async {
      emit(EnrollmentLoading());
      try {
        await enrollInCourseUseCase(event.courseId, event.token);
        emit(EnrollmentSuccess());
      } catch (e) {
        emit(EnrollmentFailure(e.toString()));
      }
    });
    on<FetchEnrollmentsEvent>((event, emit) async {
      emit(EnrollmentLoading());
      try {
        final enrollments = await fetchEnrollmentsUseCase(event.token);
        emit(EnrollmentsLoaded(enrollments));
      } catch (e) {
        emit(EnrollmentFailure(e.toString()));
      }
    });
  }
}
