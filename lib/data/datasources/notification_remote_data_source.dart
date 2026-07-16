import '../../core/http_utils.dart';
import 'dart:convert';

import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import '../../core/error_handling.dart';

class NotificationRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchNotifications(String token) async {
    final response = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.notifications),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final notifications = data is List ? data : (data['notifications'] ?? []);
      return List<Map<String, dynamic>>.from(notifications);
    }
    throw ApiException('Failed to fetch notifications', response.statusCode);
  }
}
