import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/usecases/fetch_reviews_usecase.dart';
import '../../domain/usecases/post_review_usecase.dart';

abstract class ReviewEvent {}

class LoadReviewsEvent extends ReviewEvent {
  final String courseId;
  LoadReviewsEvent(this.courseId);
}

class PostReviewEvent extends ReviewEvent {
  final String courseId;
  final String review;
  final int rating;
  final String token;
  PostReviewEvent(this.courseId, this.review, this.rating, this.token);
}

abstract class ReviewState {}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<ReviewEntity> reviews;
  ReviewLoaded(this.reviews);
}

class ReviewError extends ReviewState {
  final String message;
  ReviewError(this.message);
}

class ReviewPostSuccess extends ReviewState {}

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final FetchReviewsUseCase fetchReviewsUseCase;
  final PostReviewUseCase postReviewUseCase;
  ReviewBloc({
    required this.fetchReviewsUseCase,
    required this.postReviewUseCase,
  }) : super(ReviewInitial()) {
    on<LoadReviewsEvent>((event, emit) async {
      emit(ReviewLoading());
      try {
        final reviews = await fetchReviewsUseCase(event.courseId);
        emit(ReviewLoaded(reviews));
      } catch (e) {
        emit(ReviewError(e.toString()));
      }
    });
    on<PostReviewEvent>((event, emit) async {
      emit(ReviewLoading());
      try {
        await postReviewUseCase(
          event.courseId,
          event.review,
          event.rating,
          event.token,
        );
        emit(ReviewPostSuccess());
        final reviews = await fetchReviewsUseCase(event.courseId);
        emit(ReviewLoaded(reviews));
      } catch (e) {
        emit(ReviewError(e.toString()));
      }
    });
  }
}
