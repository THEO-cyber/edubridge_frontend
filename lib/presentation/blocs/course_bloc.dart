import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/fetch_courses_usecase.dart';

abstract class CourseEvent {}

class LoadCoursesEvent extends CourseEvent {}

abstract class CourseState {}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final List<CourseEntity> courses;
  CourseLoaded(this.courses);
}

class CourseError extends CourseState {
  final String message;
  CourseError(this.message);
}

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final FetchCoursesUseCase fetchCoursesUseCase;
  CourseBloc({required this.fetchCoursesUseCase}) : super(CourseInitial()) {
    on<LoadCoursesEvent>((event, emit) async {
      emit(CourseLoading());
      try {
        final courses = await fetchCoursesUseCase();
        emit(CourseLoaded(courses));
      } catch (e) {
        emit(CourseError(e.toString()));
      }
    });
  }
}
