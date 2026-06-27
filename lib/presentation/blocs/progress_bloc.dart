import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../../data/repositories/progress_repository_impl.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ProgressEvent {}

/// Save watch progress (and optionally mark complete) via
/// POST /enrollments/lessons/:lessonId/progress
class SaveLessonProgressEvent extends ProgressEvent {
  final String lessonId;
  final int watchedSeconds;
  final int totalSeconds;
  final bool completed;
  final String token;

  SaveLessonProgressEvent({
    required this.lessonId,
    required this.watchedSeconds,
    required this.totalSeconds,
    required this.completed,
    required this.token,
  });
}

class FetchEnrolledCoursesEvent extends ProgressEvent {
  final String token;
  FetchEnrolledCoursesEvent(this.token);
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ProgressState {}

class ProgressInitial extends ProgressState {}
class ProgressLoading extends ProgressState {}
class ProgressSaved extends ProgressState {}

class EnrolledCoursesLoaded extends ProgressState {
  final List<EnrollmentEntity> courses;
  EnrolledCoursesLoaded(this.courses);
}

class ProgressError extends ProgressState {
  final String message;
  ProgressError(this.message);
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressRepositoryImpl progressRepository;

  ProgressBloc({required this.progressRepository}) : super(ProgressInitial()) {
    on<SaveLessonProgressEvent>((event, emit) async {
      try {
        await progressRepository.saveLessonProgress(
          event.lessonId,
          event.watchedSeconds,
          event.totalSeconds,
          event.completed,
          event.token,
        );
        emit(ProgressSaved());
      } catch (e) {
        emit(ProgressError(e.toString()));
      }
    });

    on<FetchEnrolledCoursesEvent>((event, emit) async {
      emit(ProgressLoading());
      try {
        final courses =
            await progressRepository.fetchEnrolledCourses(event.token);
        emit(EnrolledCoursesLoaded(courses));
      } catch (e) {
        emit(ProgressError(e.toString()));
      }
    });
  }
}
