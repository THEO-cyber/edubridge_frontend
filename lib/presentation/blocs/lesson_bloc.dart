import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/cache/app_cache.dart';
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
      final key = 'lessons_${event.courseId}';

      // 1. Serve cache immediately — user sees content with zero wait
      final cached = AppCache.get<List<LessonEntity>>(key);
      if (cached != null) {
        emit(LessonLoaded(cached));
      } else {
        emit(LessonLoading()); // Skeleton only on first-ever load
      }

      // 2. Fetch fresh in background — silently updates the list
      try {
        final lessons = await fetchLessonsUseCase(event.courseId, event.token);
        AppCache.set(key, lessons);
        emit(LessonLoaded(lessons));
      } catch (e) {
        if (cached == null) emit(LessonError(e.toString()));
        // If cached data shown, swallow the error silently
      }
    });
  }
}
