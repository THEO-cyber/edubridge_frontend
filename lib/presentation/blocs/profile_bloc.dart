import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handling.dart';
import '../../core/secure_storage.dart';
import '../../domain/usecases/fetch_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';

abstract class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {
  final String token;
  LoadProfileEvent(this.token);
}

class UpdateProfileEvent extends ProfileEvent {
  final Map<String, dynamic> data;
  final String token;
  UpdateProfileEvent(this.data, this.token);
}

class ResetProfileEvent extends ProfileEvent {}

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profile;
  ProfileLoaded(this.profile);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileUpdateSuccess extends ProfileState {}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FetchProfileUseCase fetchProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  ProfileBloc({
    required this.fetchProfileUseCase,
    required this.updateProfileUseCase,
  }) : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        final profile = await fetchProfileUseCase(event.token);
        emit(ProfileLoaded(profile));
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();
        if (e is UnauthorizedException ||
            (e is ApiException && e.code == 403) ||
            errorMessage.contains('session expired') ||
            errorMessage.contains('unauthorized')) {
          await SecureStorage.deleteAllTokens();
          emit(ProfileError('Session expired. Please log in again.'));
        } else {
          emit(ProfileError('Unable to load profile. ${e.toString()}'));
        }
      }
    });
    on<UpdateProfileEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        await updateProfileUseCase(event.data, event.token);
        emit(ProfileUpdateSuccess());
        final profile = await fetchProfileUseCase(event.token);
        emit(ProfileLoaded(profile));
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();
        if (e is UnauthorizedException ||
            (e is ApiException && e.code == 403) ||
            errorMessage.contains('session expired') ||
            errorMessage.contains('unauthorized')) {
          await SecureStorage.deleteAllTokens();
          emit(ProfileError('Session expired. Please log in again.'));
        } else {
          emit(ProfileError('Unable to update profile. Please try again.'));
        }
      }
    });
    on<ResetProfileEvent>((event, emit) async {
      emit(ProfileInitial());
    });
  }
}
