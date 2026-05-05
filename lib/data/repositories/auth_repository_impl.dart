import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    final data = await remoteDataSource.login(email, password);
    return UserEntity(
      id: (data['id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      name: data['name']?.toString(),
    );
  }

  @override
  Future<UserEntity> register(
    String email,
    String password,
    String role,
    String username,
    String firstName,
    String lastName,
  ) async {
    final data = await remoteDataSource.register(email, password, role, username, firstName, lastName);
    return UserEntity(
      id: (data['id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      name: data['name']?.toString(),
    );
  }

  @override
  Future<UserEntity> getMe(String token) async {
    final data = await remoteDataSource.getMe(token);
    return UserEntity(
      id: (data['id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      name: data['name']?.toString(),
    );
  }
}
