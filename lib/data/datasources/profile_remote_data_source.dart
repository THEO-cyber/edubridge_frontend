import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';
import '../../core/secure_storage.dart';
import '../datasources/auth_remote_data_source.dart';

class ProfileRemoteDataSource {
  final AuthRemoteDataSource authRemoteDataSource;

  ProfileRemoteDataSource(this.authRemoteDataSource);

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    print(
      '[DEBUG PROFILE FETCH] Fetching profile with token: ${token.substring(0, 20)}...',
    );
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('[DEBUG PROFILE FETCH] Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('[DEBUG PROFILE FETCH] Profile loaded successfully');
      final parsed = jsonDecode(response.body);
      return _extractProfileData(parsed);
    } else if (response.statusCode == 404 || response.statusCode == 403) {
      // Try the auth/me endpoint if profile endpoint is not available or forbidden.
      try {
        return await authRemoteDataSource.getMe(token);
      } catch (_) {
        throw ApiException(
          'Failed to fetch profile (${response.statusCode}). Response: ${response.body}',
          response.statusCode,
        );
      }
    } else {
      throw ApiException(
        'Failed to fetch profile: ${response.statusCode} ${response.body}',
        response.statusCode,
      );
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data, String token) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.updateProfile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 403) {
      // Profile update might not be available, just return without error for now
      return;
    } else {
      throw ApiException(
        'Failed to update profile: ${response.statusCode} ${response.body}',
        response.statusCode,
      );
    }
  }

  Map<String, dynamic> _extractProfileData(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return data['user'] as Map<String, dynamic>;
      }
      if (data['profile'] is Map<String, dynamic>) {
        return data['profile'] as Map<String, dynamic>;
      }
      if (data['data'] is Map<String, dynamic>) {
        return _extractProfileData(data['data']);
      }
      return data;
    }
    return <String, dynamic>{};
  }

  Future<String?> _refreshTokenAndRetry() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final refreshData = await authRemoteDataSource.refreshToken(refreshToken);
      final newToken = _extractTokenFromRefreshResponse(refreshData);
      final newRefreshToken = _extractRefreshTokenFromRefreshResponse(
        refreshData,
      );

      if (newToken != null && newToken.isNotEmpty) {
        await SecureStorage.saveToken(newToken);
      }
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await SecureStorage.saveRefreshToken(newRefreshToken);
      }

      return newToken;
    } catch (e) {
      // Refresh failed
      return null;
    }
  }

  String? _extractTokenFromRefreshResponse(Map<String, dynamic> data) {
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

  String? _extractRefreshTokenFromRefreshResponse(Map<String, dynamic> data) {
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
