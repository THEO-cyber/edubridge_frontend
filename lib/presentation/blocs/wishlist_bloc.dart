import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/fetch_wishlist_usecase.dart';
import '../../domain/usecases/add_to_wishlist_usecase.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';

abstract class WishlistEvent {}

class LoadWishlistEvent extends WishlistEvent {
  final String token;
  LoadWishlistEvent(this.token);
}

class AddToWishlistEvent extends WishlistEvent {
  final String courseId;
  final String token;
  AddToWishlistEvent(this.courseId, this.token);
}

class RemoveFromWishlistEvent extends WishlistEvent {
  final String courseId;
  final String token;
  RemoveFromWishlistEvent(this.courseId, this.token);
}

class ClearWishlistEvent extends WishlistEvent {}

abstract class WishlistState {}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<CourseEntity> wishlist;
  WishlistLoaded(this.wishlist);
}

class WishlistError extends WishlistState {
  final String message;
  WishlistError(this.message);
}

class WishlistAddSuccess extends WishlistState {}

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final FetchWishlistUseCase fetchWishlistUseCase;
  final AddToWishlistUseCase addToWishlistUseCase;
  WishlistBloc({
    required this.fetchWishlistUseCase,
    required this.addToWishlistUseCase,
  }) : super(WishlistInitial()) {
    on<LoadWishlistEvent>((event, emit) async {
      emit(WishlistLoading());
      try {
        final wishlist = await fetchWishlistUseCase(event.token);
        emit(WishlistLoaded(wishlist));
      } catch (e) {
        emit(WishlistError(e.toString()));
      }
    });
    on<AddToWishlistEvent>((event, emit) async {
      emit(WishlistLoading());
      try {
        await addToWishlistUseCase(event.courseId, event.token);
        emit(WishlistAddSuccess());
        final wishlist = await fetchWishlistUseCase(event.token);
        emit(WishlistLoaded(wishlist));
      } catch (e) {
        emit(WishlistError(e.toString()));
      }
    });
    on<RemoveFromWishlistEvent>((event, emit) async {
      emit(WishlistLoading());
      try {
        await WishlistRemoteDataSource().removeFromWishlist(
          event.courseId,
          event.token,
        );
        final wishlist = await fetchWishlistUseCase(event.token);
        emit(WishlistLoaded(wishlist));
      } catch (e) {
        emit(WishlistError(e.toString()));
      }
    });
    on<ClearWishlistEvent>((event, emit) => emit(WishlistInitial()));
  }
}
