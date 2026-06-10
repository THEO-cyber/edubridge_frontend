import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';

class AdminRemoteDataSource {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Map<String, dynamic>>> fetchInstructors(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminInstructors}'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? data['instructors'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw ApiException('Failed to fetch instructors', res.statusCode);
  }

  Future<void> suspendInstructor(String id, String reason, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminSuspend(id)}'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromBody(res, 'Failed to suspend instructor');
    }
  }

  Future<void> warnInstructor(String id, String message, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminWarn(id)}'),
      headers: _headers(token),
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromBody(res, 'Failed to send warning');
    }
  }

  Future<void> deleteInstructor(String id, String token) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminDeleteInstructor(id)}'),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throwFromBody(res, 'Failed to remove instructor');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllReviews(
    String token, {
    String? courseId,
    String? instructorId,
    int? rating,
  }) async {
    final params = <String, String>{};
    if (courseId != null) params['courseId'] = courseId;
    if (instructorId != null) params['instructorId'] = instructorId;
    if (rating != null) params['rating'] = rating.toString();

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminReviews}')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? data['reviews'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw ApiException('Failed to fetch reviews', res.statusCode);
  }

  Future<List<Map<String, dynamic>>> fetchSessionReviews(
      String sessionId, String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.sessionReviews(sessionId)}'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? data['reviews'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw ApiException('Failed to fetch session reviews', res.statusCode);
  }

  void _throwFromBody(http.Response res, String fallback) {
    String msg = fallback;
    try {
      final b = jsonDecode(res.body);
      if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
    } catch (_) {}
    throw ApiException(msg, res.statusCode);
  }
}
