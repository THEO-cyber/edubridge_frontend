import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('[DEBUG AUTH] Login attempt for: $email');
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    print('[DEBUG AUTH] Login response: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('[DEBUG AUTH] Login successful');
      return jsonDecode(response.body);
    } else {
      String errorMsg = 'Failed to login';
      try {
        final body = jsonDecode(response.body);
        if (body is Map &&
            body['message'] != null &&
            body['message'] is String &&
            body['message'].toString().isNotEmpty) {
          errorMsg = body['message'] as String;
        }
      } catch (e) {
        // ignore JSON parse errors
      }
      // Print backend error to terminal for debugging
      // ignore: avoid_print
      print(
        '[LOGIN ERROR] Status: \\${response.statusCode} Body: \\${response.body}',
      );
      throw Exception(errorMsg);
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
    print('[DEBUG AUTH] Register attempt for: $email, role: $role');
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role.toUpperCase(),
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = 'Failed to register';
      try {
        final body = jsonDecode(response.body);
        if (body is Map &&
            body['message'] is String &&
            body['message'].toString().isNotEmpty) {
          errorMsg = body['message'] as String;
        }
      } catch (_) {
        // ignore JSON parse errors
      }
      // ignore: avoid_print
      print(
        '[REGISTER ERROR] Status: ${response.statusCode} Body: ${response.body}',
      );
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.refresh),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to refresh token');
  }

  Future<void> logout(String token, {String? refreshToken}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.logout),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to logout');
    }
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    print(
      '[DEBUG AUTH] getMe() called with token: ${token.substring(0, 20)}...',
    );
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.me),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('[DEBUG AUTH] getMe response: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('[DEBUG AUTH] getMe successful');
      return jsonDecode(response.body);
    } else {
      print(
        '[DEBUG AUTH] getMe failed: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to fetch user profile');
    }
  }
}
