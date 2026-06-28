import '../../core/error_handling.dart';
import '../../core/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    final data = await remoteDataSource.login(email, password);
    print('---------- [AuthRepo] Raw login response keys: ${data.keys.toList()}');
    print('---------- [AuthRepo] Raw login response: $data');

    if (data['requires2FA'] == true) {
      final tempToken = (data['tempToken'] ?? '').toString();
      print('---------- [AuthRepo] 2FA required, tempToken length: ${tempToken.length}');
      throw Requires2FAException(tempToken);
    }

    final userData = _extractUserData(data);

    // Extract and save tokens
    final token = _extractToken(data);
    final refreshToken = _extractRefreshToken(data);

    print('---------- [AuthRepo] Extracted token: $token');
    print('---------- [AuthRepo] Extracted refreshToken: $refreshToken');

    if (token != null && token.isNotEmpty) {
      await SecureStorage.saveToken(token);
      print('---------- [AuthRepo] Token SAVED to SecureStorage');
    } else {
      print('---------- [AuthRepo] WARNING: token is null/empty — NOT saved');
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }

    var entity = UserEntity(
      id: (userData['id'] ?? userData['userId'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
      role: _extractRole(userData),
      name: _extractUserName(userData),
      createdAt: _parseCreatedAt(
        userData['createdAt'] ?? userData['created_at'],
      ),
    );

    // If role didn't parse from the login response, fetch it from /auth/me
    if (entity.role.isEmpty && token != null && token.isNotEmpty) {
      try {
        entity = await getMe(token);
      } catch (_) {}
    }

    final entityName = entity.name;
    if (entityName != null && entityName.isNotEmpty) {
      await SecureStorage.saveUserName(entityName);
    }
    return entity;
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
    final data = await remoteDataSource.register(
      email,
      password,
      role,
      username,
      firstName,
      lastName,
    );
    final userData = _extractUserData(data);

    // Extract and save tokens
    final token = _extractToken(data);
    final refreshToken = _extractRefreshToken(data);

    if (token != null && token.isNotEmpty) {
      await SecureStorage.saveToken(token);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }

    final regName = _extractUserName(userData);
    if (regName.isNotEmpty) await SecureStorage.saveUserName(regName);

    return UserEntity(
      id: (userData['id'] ?? userData['userId'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
      role: _extractRole(userData),
      name: regName,
      createdAt: _parseCreatedAt(
        userData['createdAt'] ?? userData['created_at'],
      ),
    );
  }

  Map<String, dynamic> _extractUserData(Map<String, dynamic> data) {
    if (data.containsKey('id') && data.containsKey('email')) {
      return data;
    }
    final dataNode = data['data'];
    if (dataNode is Map<String, dynamic>) {
      if (dataNode.containsKey('id') && dataNode.containsKey('email')) {
        return dataNode;
      }
      if (dataNode['user'] is Map<String, dynamic>) {
        return dataNode['user'] as Map<String, dynamic>;
      }
    }
    if (data['user'] is Map<String, dynamic>) {
      return data['user'] as Map<String, dynamic>;
    }
    return data;
  }

  String _extractRole(Map<String, dynamic> data) {
    final raw = data['role'] ?? data['userRole'] ?? data['roles'];
    if (raw == null) return '';
    String result;
    if (raw is String) {
      result = raw;
    } else if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      result = first is Map ? (first['name'] ?? first['role'] ?? first).toString() : first.toString();
    } else {
      result = raw.toString();
    }
    return result.trim();
  }

  String _extractUserName(Map<String, dynamic> data) {
    if (data['name'] is String && (data['name'] as String).isNotEmpty) {
      return data['name'] as String;
    }
    final firstName = data['firstName'] ?? data['first_name'] ?? '';
    final lastName = data['lastName'] ?? data['last_name'] ?? '';
    if (firstName != null && lastName != null) {
      return '${firstName.toString().trim()} ${lastName.toString().trim()}'
          .trim();
    }
    if (data['username'] is String) {
      return data['username'] as String;
    }
    return '';
  }

  @override
  Future<UserEntity> getMe(String token) async {
    final raw = await remoteDataSource.getMe(token);
    final data = _extractUserData(raw);
    return UserEntity(
      id: (data['id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: _extractRole(data),
      name: _extractUserName(data),
      createdAt: _parseCreatedAt(data['createdAt'] ?? data['created_at']),
    );
  }

  @override
  Future<void> refreshToken() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    final data = await remoteDataSource.refreshToken(refreshToken);
    final newToken = _extractToken(data);
    final newRefreshToken = _extractRefreshToken(data);

    if (newToken == null || newToken.isEmpty) {
      throw Exception('Failed to refresh token');
    }

    await SecureStorage.saveToken(newToken);
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(newRefreshToken);
    }
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

  DateTime _parseCreatedAt(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
