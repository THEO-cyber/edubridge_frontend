import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handling.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../services/notification_service.dart';
import '../../core/secure_storage.dart';

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
  RegisterEvent(
    this.email,
    this.password,
    this.role,
    this.username,
    this.firstName,
    this.lastName,
  );
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

class Auth2FARequired extends AuthState {
  final String tempToken;
  Auth2FARequired(this.tempToken);
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
        final token = await SecureStorage.getToken();
        if (token != null) NotificationService.registerToken(token);
      } catch (e) {
        if (e is Requires2FAException) {
          emit(Auth2FARequired(e.tempToken));
          return;
        }
        final message = e.toString().replaceFirst('Exception: ', '');
        emit(
          AuthFailure(
            message.isNotEmpty
                ? message
                : 'Invalid email or password. Please try again.',
          ),
        );
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
        final token = await SecureStorage.getToken();
        if (token != null) NotificationService.registerToken(token);
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        emit(
          AuthFailure(
            message.isNotEmpty
                ? message
                : 'Registration failed. Please try again.',
          ),
        );
      }
    });
  }
}
