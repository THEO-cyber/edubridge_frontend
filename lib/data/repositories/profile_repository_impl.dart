import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    return await remoteDataSource.fetchProfile(token);
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data, String token) async {
    await remoteDataSource.updateProfile(data, token);
  }
}
