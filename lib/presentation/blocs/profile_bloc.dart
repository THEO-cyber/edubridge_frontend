import 'package:flutter_bloc/flutter_bloc.dart';
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
        emit(ProfileError(e.toString()));
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
        emit(ProfileError(e.toString()));
      }
    });
  }
}
