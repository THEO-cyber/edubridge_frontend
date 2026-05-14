import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/progress_entity.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../../data/repositories/progress_repository_impl.dart';

abstract class ProgressEvent {}

class FetchProgressEvent extends ProgressEvent {
  final String enrollmentId;
  final String token;
  FetchProgressEvent(this.enrollmentId, this.token);
}

class UpdateLessonProgressEvent extends ProgressEvent {
  final String enrollmentId;
  final String lessonId;
  final int watchedDuration;
  final String token;
  UpdateLessonProgressEvent(
    this.enrollmentId,
    this.lessonId,
    this.watchedDuration,
    this.token,
  );
}

class MarkLessonCompleteEvent extends ProgressEvent {
  final String enrollmentId;
  final String lessonId;
  final String token;
  MarkLessonCompleteEvent(this.enrollmentId, this.lessonId, this.token);
}

class FetchEnrolledCoursesEvent extends ProgressEvent {
  final String token;
  FetchEnrolledCoursesEvent(this.token);
}

abstract class ProgressState {}

class ProgressInitial extends ProgressState {}

class ProgressLoading extends ProgressState {}

class ProgressLoaded extends ProgressState {
  final ProgressEntity progress;
  ProgressLoaded(this.progress);
}

class EnrolledCoursesLoaded extends ProgressState {
  final List<EnrollmentEntity> courses;
  EnrolledCoursesLoaded(this.courses);
}

class ProgressUpdated extends ProgressState {}

class ProgressError extends ProgressState {
  final String message;
  ProgressError(this.message);
}

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressRepositoryImpl progressRepository;

  ProgressBloc({required this.progressRepository}) : super(ProgressInitial()) {
    on<FetchProgressEvent>((event, emit) async {
      emit(ProgressLoading());
      try {
        final progress = await progressRepository.fetchProgress(
          event.enrollmentId,
          event.token,
        );
        emit(ProgressLoaded(progress));
      } catch (e) {
        emit(ProgressError(e.toString()));
      }
    });

    on<UpdateLessonProgressEvent>((event, emit) async {
      try {
        await progressRepository.updateLessonProgress(
          event.enrollmentId,
          event.lessonId,
          event.watchedDuration,
          event.token,
        );
        emit(ProgressUpdated());
        final progress = await progressRepository.fetchProgress(
          event.enrollmentId,
          event.token,
        );
        emit(ProgressLoaded(progress));
      } catch (e) {
        emit(ProgressError(e.toString()));
      }
    });

    on<MarkLessonCompleteEvent>((event, emit) async {
      try {
        await progressRepository.markLessonComplete(
          event.enrollmentId,
          event.lessonId,
          event.token,
        );
        emit(ProgressUpdated());
        final progress = await progressRepository.fetchProgress(
          event.enrollmentId,
          event.token,
        );
        emit(ProgressLoaded(progress));
      } catch (e) {
        emit(ProgressError(e.toString()));
      }
    });

    on<FetchEnrolledCoursesEvent>((event, emit) async {
      emit(ProgressLoading());
      try {
        final courses = await progressRepository.fetchEnrolledCourses(
          event.token,
        );
        emit(EnrolledCoursesLoaded(courses));
      } catch (e) {
        emit(ProgressError(e.toString()));
      }
    });
  }
}
