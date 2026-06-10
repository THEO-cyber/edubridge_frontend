import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = 'Failed to login';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          if (body['message'] is String &&
              body['message'].toString().isNotEmpty) {
            errorMsg = body['message'] as String;
          } else if (body['error'] is String &&
              body['error'].toString().isNotEmpty) {
            errorMsg = body['error'] as String;
          }
        }
      } catch (e) {
        // ignore JSON parse errors
      }
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
    final normalizedRole = role.toString().toUpperCase();
    final body = {
      'email': email,
      'password': password,
      'role': normalizedRole,
      'username': username,
      'name': '$firstName $lastName',
      'firstName': firstName,
      'lastName': lastName,
      'first_name': firstName,
      'last_name': lastName,
    };
    print('---------- [Register] POST body: ${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('---------- [Register] Status: ${response.statusCode}');
    print('---------- [Register] Response: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = 'Failed to register';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          if (body['message'] is String &&
              body['message'].toString().isNotEmpty) {
            errorMsg = body['message'] as String;
          } else if (body['error'] is String &&
              body['error'].toString().isNotEmpty) {
            errorMsg = body['error'] as String;
          } else if (body['errors'] is String &&
              body['errors'].toString().isNotEmpty) {
            errorMsg = body['errors'] as String;
          } else if (body['errors'] is List && body['errors'].isNotEmpty) {
            errorMsg = body['errors'].join(', ');
          }
        }
      } catch (e) {
        // ignore JSON parse errors
      }
      // Print backend error to terminal for debugging
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.me),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<void> registerFcmToken(String authToken, String fcmToken) async {
    try {
      await http.post(
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
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.refresh),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh token');
    }
  }
}
