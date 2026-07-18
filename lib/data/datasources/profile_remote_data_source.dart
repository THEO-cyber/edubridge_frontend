import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';
import '../datasources/auth_remote_data_source.dart';

class ProfileRemoteDataSource {
  final AuthRemoteDataSource authRemoteDataSource;

  ProfileRemoteDataSource(this.authRemoteDataSource);

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
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
    final response = await apiPatch(
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

  Future<Map<String, dynamic>> fetchStudentAnalytics(String token) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.studentAnalytics),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          final inner = parsed['data'];
          if (inner is Map<String, dynamic>) return inner;
          return parsed;
        }
      }
      throw ApiException('Failed to fetch student analytics', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<Map<String, dynamic>> fetchInstructorAnalytics(String token) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.instructorAnalytics),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          final inner = parsed['data'];
          if (inner is Map<String, dynamic>) return inner;
          return parsed;
        }
      }
      throw ApiException('Failed to fetch instructor analytics', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  /// Update instructor-specific profile fields
  Future<void> updateInstructorProfile(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await apiPut(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.updateInstructorProfile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 403) {
      // Not permitted for this token
      throw ApiException('Forbidden', response.statusCode);
    } else {
      throw ApiException(
        'Failed to update instructor profile: ${response.statusCode} ${response.body}',
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
}
