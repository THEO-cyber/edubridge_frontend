import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;
  UpdateProfileUseCase(this.repository);

  Future<void> call(Map<String, dynamic> data, String token) {
    return repository.updateProfile(data, token);
  }
}
