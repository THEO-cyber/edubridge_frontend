import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: 'refresh_token');
  }

  static Future<void> deleteAllTokens() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  static Future<void> clearRole() async {
    await _storage.delete(key: 'user_role');
  }

  static Future<void> saveUserName(String name) async {
    await _storage.write(key: 'user_name', value: name);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  static Future<void> clearUserName() async {
    await _storage.delete(key: 'user_name');
  }
}
