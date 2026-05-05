import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/repositories/wishlist_repository_impl.dart';
import '../../domain/usecases/fetch_wishlist_usecase.dart';
import '../../domain/usecases/add_to_wishlist_usecase.dart';
import 'wishlist_bloc.dart';

class WishlistBlocProvider extends StatelessWidget {
  final Widget child;
  const WishlistBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WishlistBloc(
        fetchWishlistUseCase: FetchWishlistUseCase(
          WishlistRepositoryImpl(WishlistRemoteDataSource()),
        ),
        addToWishlistUseCase: AddToWishlistUseCase(
          WishlistRepositoryImpl(WishlistRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
