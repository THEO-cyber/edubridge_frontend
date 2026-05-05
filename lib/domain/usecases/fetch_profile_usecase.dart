import '../repositories/profile_repository.dart';

class FetchProfileUseCase {
  final ProfileRepository repository;
  FetchProfileUseCase(this.repository);

  Future<Map<String, dynamic>> call(String token) {
    return repository.fetchProfile(token);
  }
}
