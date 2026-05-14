import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/usecases/fetch_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'profile_bloc.dart';

class ProfileBlocProvider extends StatelessWidget {
  final Widget child;
  const ProfileBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authRemoteDataSource = AuthRemoteDataSource();
    return BlocProvider(
      create: (_) => ProfileBloc(
        fetchProfileUseCase: FetchProfileUseCase(
          ProfileRepositoryImpl(ProfileRemoteDataSource(authRemoteDataSource)),
        ),
        updateProfileUseCase: UpdateProfileUseCase(
          ProfileRepositoryImpl(ProfileRemoteDataSource(authRemoteDataSource)),
        ),
      ),
      child: child,
    );
  }
}
