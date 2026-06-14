import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../core/http_utils.dart';

class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      String errorMsg = 'Invalid email or password';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          if (body['message'] is String && body['message'].toString().isNotEmpty) {
            errorMsg = body['message'] as String;
          } else if (body['error'] is String && body['error'].toString().isNotEmpty) {
            errorMsg = body['error'] as String;
          }
        }
      } catch (_) {}
      throw Exception(errorMsg);
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception(networkErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String role,
    String username,
    String firstName,
    String lastName,
  ) async {
    final bodyMap = {
      'email': email,
      'password': password,
      'role': role.toUpperCase(),
      'username': username,
      'name': '$firstName $lastName',
      'firstName': firstName,
      'lastName': lastName,
      'first_name': firstName,
      'last_name': lastName,
    };
    try {
      final response = await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      String errorMsg = 'Failed to register';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) {
          if (b['message'] is String && b['message'].toString().isNotEmpty) {
            errorMsg = b['message'] as String;
          } else if (b['error'] is String && b['error'].toString().isNotEmpty) {
            errorMsg = b['error'] as String;
          } else if (b['errors'] is List && (b['errors'] as List).isNotEmpty) {
            errorMsg = (b['errors'] as List).join(', ');
          }
        }
      } catch (_) {}
      throw Exception(errorMsg);
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception(networkErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.me),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch user profile');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception(networkErrorMessage(e));
    }
  }

  Future<void> registerFcmToken(String authToken, String fcmToken) async {
    try {
      await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.registerFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.refresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to refresh token');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception(networkErrorMessage(e));
    }
  }
}
