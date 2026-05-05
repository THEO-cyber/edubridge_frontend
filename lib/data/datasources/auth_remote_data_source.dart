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
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register');
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
}
