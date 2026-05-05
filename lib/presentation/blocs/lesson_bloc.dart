import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/usecases/fetch_lessons_usecase.dart';

abstract class LessonEvent {}

class LoadLessonsEvent extends LessonEvent {
  final String courseId;
  final String token;
  LoadLessonsEvent(this.courseId, this.token);
}

abstract class LessonState {}

class LessonInitial extends LessonState {}

class LessonLoading extends LessonState {}

class LessonLoaded extends LessonState {
  final List<LessonEntity> lessons;
  LessonLoaded(this.lessons);
}

class LessonError extends LessonState {
  final String message;
  LessonError(this.message);
}

class LessonBloc extends Bloc<LessonEvent, LessonState> {
  final FetchLessonsUseCase fetchLessonsUseCase;
  LessonBloc({required this.fetchLessonsUseCase}) : super(LessonInitial()) {
    on<LoadLessonsEvent>((event, emit) async {
      emit(LessonLoading());
      try {
        final lessons = await fetchLessonsUseCase(event.courseId, event.token);
        emit(LessonLoaded(lessons));
      } catch (e) {
        emit(LessonError(e.toString()));
      }
    });
  }
}
