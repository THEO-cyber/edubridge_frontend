import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/cache/app_cache.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/fetch_courses_usecase.dart';
import '../../data/repositories/course_repository_impl.dart';

abstract class CourseEvent {}

class LoadCoursesEvent extends CourseEvent {}

class SearchCoursesEvent extends CourseEvent {
  final String query;
  SearchCoursesEvent(this.query);
}

class FetchCoursesByCategoryEvent extends CourseEvent {
  final String category;
  FetchCoursesByCategoryEvent(this.category);
}

class FetchTopRatedCoursesEvent extends CourseEvent {}

class FetchCourseDetailEvent extends CourseEvent {
  final String courseId;
  FetchCourseDetailEvent(this.courseId);
}

abstract class CourseState {}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final List<CourseEntity> courses;
  CourseLoaded(this.courses);
}

class CourseDetailLoaded extends CourseState {
  final CourseEntity course;
  CourseDetailLoaded(this.course);
}

class CourseError extends CourseState {
  final String message;
  CourseError(this.message);
}

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final FetchCoursesUseCase fetchCoursesUseCase;
  final CourseRepositoryImpl courseRepository;

  CourseBloc({
    required this.fetchCoursesUseCase,
    required this.courseRepository,
  }) : super(CourseInitial()) {
    on<LoadCoursesEvent>((event, emit) async {
      const key = 'courses_all';
      final cached = AppCache.get<List<CourseEntity>>(key);
      if (cached != null) {
        emit(CourseLoaded(cached));
      } else {
        emit(CourseLoading());
      }
      try {
        final courses = await fetchCoursesUseCase();
        AppCache.set(key, courses, ttl: const Duration(minutes: 3));
        emit(CourseLoaded(courses));
      } catch (e) {
        if (cached == null) emit(CourseError(e.toString()));
      }
    });

    on<SearchCoursesEvent>((event, emit) async {
      final key = 'courses_search_${event.query}';
      final cached = AppCache.get<List<CourseEntity>>(key);
      if (cached != null) {
        emit(CourseLoaded(cached));
      } else {
        emit(CourseLoading());
      }
      try {
        final courses = await courseRepository.searchCourses(event.query);
        AppCache.set(key, courses, ttl: const Duration(minutes: 2));
        emit(CourseLoaded(courses));
      } catch (e) {
        if (cached == null) emit(CourseError(e.toString()));
      }
    });

    on<FetchCoursesByCategoryEvent>((event, emit) async {
      final key = 'courses_cat_${event.category}';
      final cached = AppCache.get<List<CourseEntity>>(key);
      if (cached != null) {
        emit(CourseLoaded(cached));
      } else {
        emit(CourseLoading());
      }
      try {
        final courses =
            await courseRepository.fetchCoursesByCategory(event.category);
        AppCache.set(key, courses, ttl: const Duration(minutes: 3));
        emit(CourseLoaded(courses));
      } catch (e) {
        if (cached == null) emit(CourseError(e.toString()));
      }
    });

    on<FetchTopRatedCoursesEvent>((event, emit) async {
      const key = 'courses_top_rated';
      final cached = AppCache.get<List<CourseEntity>>(key);
      if (cached != null) {
        emit(CourseLoaded(cached));
      } else {
        emit(CourseLoading());
      }
      try {
        final courses = await courseRepository.fetchTopRatedCourses();
        AppCache.set(key, courses, ttl: const Duration(minutes: 5));
        emit(CourseLoaded(courses));
      } catch (e) {
        if (cached == null) emit(CourseError(e.toString()));
      }
    });

    on<FetchCourseDetailEvent>((event, emit) async {
      final key = 'course_detail_${event.courseId}';
      final cached = AppCache.get<CourseEntity>(key);
      if (cached != null) {
        emit(CourseDetailLoaded(cached));
      } else {
        emit(CourseLoading());
      }
      try {
        final course = await courseRepository.fetchCourseById(event.courseId);
        AppCache.set(key, course, ttl: const Duration(minutes: 2));
        emit(CourseDetailLoaded(course));
      } catch (e) {
        if (cached == null) emit(CourseError(e.toString()));
      }
    });
  }
}
