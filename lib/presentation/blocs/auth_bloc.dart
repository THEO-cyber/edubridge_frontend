import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  LoginEvent(this.email, this.password);
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final String username;
  final String firstName;
  final String lastName;
  RegisterEvent(this.email, this.password, this.role, this.username, this.firstName, this.lastName);
}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;
  AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthBloc({required this.loginUseCase, required this.registerUseCase})
    : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await loginUseCase(event.email, event.password);
        emit(AuthSuccess(user));
      } catch (e) {
        // Print backend error to terminal for debugging
        // ignore: avoid_print
        print('[AUTH_BLOC LOGIN ERROR] ${e.toString()}');
        emit(AuthFailure('Invalid email or password. Please try again.'));
      }
    });
    on<RegisterEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await registerUseCase(
          event.email,
          event.password,
          event.role,
          event.username,
          event.firstName,
          event.lastName,
        );
        emit(AuthSuccess(user));
      } catch (e) {
        // Print backend error to terminal for debugging
        // ignore: avoid_print
        print('[AUTH_BLOC REGISTER ERROR] ${e.toString()}');
        emit(AuthFailure('Registration failed. Please try again.'));
      }
    });
  }
}
