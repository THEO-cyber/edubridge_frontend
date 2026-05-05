import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_bloc.dart';

class AuthBlocProvider extends StatelessWidget {
  final Widget child;
  const AuthBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(
        loginUseCase: LoginUseCase(AuthRepositoryImpl(AuthRemoteDataSource())),
        registerUseCase: RegisterUseCase(
          AuthRepositoryImpl(AuthRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
