import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(CourseLoading());
      try {
        final courses = await fetchCoursesUseCase();
        emit(CourseLoaded(courses));
      } catch (e) {
        emit(CourseError(e.toString()));
      }
    });

    on<SearchCoursesEvent>((event, emit) async {
      emit(CourseLoading());
      try {
        final courses = await courseRepository.searchCourses(event.query);
        emit(CourseLoaded(courses));
      } catch (e) {
        emit(CourseError(e.toString()));
      }
    });

    on<FetchCoursesByCategoryEvent>((event, emit) async {
      emit(CourseLoading());
      try {
        final courses = await courseRepository.fetchCoursesByCategory(
          event.category,
        );
        emit(CourseLoaded(courses));
      } catch (e) {
        emit(CourseError(e.toString()));
      }
    });

    on<FetchTopRatedCoursesEvent>((event, emit) async {
      emit(CourseLoading());
      try {
        final courses = await courseRepository.fetchTopRatedCourses();
        emit(CourseLoaded(courses));
      } catch (e) {
        emit(CourseError(e.toString()));
      }
    });

    on<FetchCourseDetailEvent>((event, emit) async {
      emit(CourseLoading());
      try {
        final course = await courseRepository.fetchCourseById(event.courseId);
        emit(CourseDetailLoaded(course));
      } catch (e) {
        emit(CourseError(e.toString()));
      }
    });
  }
}
