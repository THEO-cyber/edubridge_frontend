import '../../domain/entities/user_entity.dart';
import '../../core/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../core/error_handling.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    print('[DEBUG AUTH REPO] login() called for: $email');
    final data = await remoteDataSource.login(email, password);
    print('[DEBUG AUTH REPO] Login response received');
    final token = _extractToken(data);
    final refreshToken = _extractRefreshToken(data);
    print('[DEBUG AUTH REPO] Token extracted: ${token != null ? 'YES' : 'NO'}');
    if (token != null && token.isNotEmpty) {
      print('[DEBUG AUTH REPO] Saving token...');
      await SecureStorage.saveToken(token);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    final userData = _extractUserData(data);
    print('[DEBUG AUTH REPO] User data extracted: ${userData['email']}');
    return UserEntity(
      id: (userData['id'] ?? userData['_id'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
      role: (userData['role'] ?? '').toString(),
      name: userData['name']?.toString(),
      createdAt: DateTime.now(),
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
    print('[DEBUG AUTH REPO] register() called for: $email, role: $role');
    final data = await remoteDataSource.register(
      email,
      password,
      role,
      username,
      firstName,
      lastName,
    );
    print('[DEBUG AUTH REPO] Register response received');
    final token = _extractToken(data);
    final refreshToken = _extractRefreshToken(data);
    if (token != null && token.isNotEmpty) {
      await SecureStorage.saveToken(token);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    final userData = _extractUserData(data);
    return UserEntity(
      id: (userData['id'] ?? userData['_id'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
      role: (userData['role'] ?? '').toString(),
      name: userData['name']?.toString(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String> refreshToken() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw UnauthorizedException('No refresh token available');
    }
    final data = await remoteDataSource.refreshToken(refreshToken);
    final newToken = _extractToken(data);
    final newRefreshToken = _extractRefreshToken(data);
    if (newToken != null && newToken.isNotEmpty) {
      await SecureStorage.saveToken(newToken);
    }
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(newRefreshToken);
    }
    if (newToken == null || newToken.isEmpty) {
      throw UnauthorizedException('Failed to refresh token');
    }
    return newToken;
  }

  @override
  Future<UserEntity> getMe(String token) async {
    final data = await remoteDataSource.getMe(token);
    final userData = _extractUserData(data);
    return UserEntity(
      id: (userData['id'] ?? userData['_id'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
      role: (userData['role'] ?? '').toString(),
      name: userData['name']?.toString(),
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _extractUserData(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    final dataNode = data['data'];
    if (dataNode is Map<String, dynamic> &&
        dataNode['user'] is Map<String, dynamic>) {
      return dataNode['user'] as Map<String, dynamic>;
    }
    return data;
  }

  String? _extractToken(Map<String, dynamic> data) {
    if (data['accessToken'] is String) return data['accessToken'] as String;
    if (data['token'] is String) return data['token'] as String;
    final dataNode = data['data'];
    if (dataNode is Map<String, dynamic>) {
      if (dataNode['accessToken'] is String) {
        return dataNode['accessToken'] as String;
      }
      if (dataNode['token'] is String) return dataNode['token'] as String;
    }
    return null;
  }

  String? _extractRefreshToken(Map<String, dynamic> data) {
    if (data['refreshToken'] is String) return data['refreshToken'] as String;
    final dataNode = data['data'];
    if (dataNode is Map<String, dynamic>) {
      if (dataNode['refreshToken'] is String) {
        return dataNode['refreshToken'] as String;
      }
    }
    return null;
  }
}
