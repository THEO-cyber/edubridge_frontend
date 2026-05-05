import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/usecases/fetch_reviews_usecase.dart';
import '../../domain/usecases/post_review_usecase.dart';
import 'review_bloc.dart';

class ReviewBlocProvider extends StatelessWidget {
  final Widget child;
  const ReviewBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewBloc(
        fetchReviewsUseCase: FetchReviewsUseCase(
          ReviewRepositoryImpl(ReviewRemoteDataSource()),
        ),
        postReviewUseCase: PostReviewUseCase(
          ReviewRepositoryImpl(ReviewRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
