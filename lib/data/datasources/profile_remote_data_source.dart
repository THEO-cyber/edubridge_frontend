import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Failed to fetch profile', response.statusCode);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data, String token) async {
    final response = await http.put(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw ApiException('Failed to update profile', response.statusCode);
    }
  }
}
