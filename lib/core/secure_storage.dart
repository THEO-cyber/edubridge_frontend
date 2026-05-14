import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    print('[DEBUG STORAGE] Saving token: ${token.substring(0, 20)}...');
    await _storage.write(key: 'jwt_token', value: token);
    print('[DEBUG STORAGE] Token saved');
  }

  static Future<String?> getToken() async {
    final token = await _storage.read(key: 'jwt_token');
    print('[DEBUG STORAGE] Retrieved token: ${token != null ? 'YES' : 'NO'}');
    return token;
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
    print('[DEBUG STORAGE] Deleting all tokens...');
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    print('[DEBUG STORAGE] All tokens deleted');
  }
}
