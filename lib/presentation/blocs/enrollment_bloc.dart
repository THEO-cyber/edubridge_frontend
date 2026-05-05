import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/enroll_in_course_usecase.dart';

abstract class EnrollmentEvent {}

class EnrollEvent extends EnrollmentEvent {
  final String courseId;
  final String token;
  EnrollEvent(this.courseId, this.token);
}

abstract class EnrollmentState {}

class EnrollmentInitial extends EnrollmentState {}

class EnrollmentLoading extends EnrollmentState {}

class EnrollmentSuccess extends EnrollmentState {}

class EnrollmentFailure extends EnrollmentState {
  final String message;
  EnrollmentFailure(this.message);
}

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final EnrollInCourseUseCase enrollInCourseUseCase;
  EnrollmentBloc({required this.enrollInCourseUseCase})
    : super(EnrollmentInitial()) {
    on<EnrollEvent>((event, emit) async {
      emit(EnrollmentLoading());
      try {
        await enrollInCourseUseCase(event.courseId, event.token);
        emit(EnrollmentSuccess());
      } catch (e) {
        emit(EnrollmentFailure(e.toString()));
      }
    });
  }
}
