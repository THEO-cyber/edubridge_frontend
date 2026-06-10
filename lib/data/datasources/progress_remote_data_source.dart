import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';

class ProgressRemoteDataSource {
  Future<Map<String, dynamic>> fetchProgress(
    String enrollmentId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/enrollments/$enrollmentId/progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Failed to fetch progress', response.statusCode);
    }
  }

  Future<void> updateLessonProgress(
    String enrollmentId,
    String lessonId,
    int watchedDuration,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.lessonProgress(lessonId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'enrollmentId': enrollmentId,
        'lessonId': lessonId,
        'watchedDuration': watchedDuration,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to update progress', response.statusCode);
    }
  }

  Future<void> markLessonComplete(
    String enrollmentId,
    String lessonId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/enrollments/$enrollmentId/lessons/$lessonId/complete',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to mark lesson complete', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchEnrolledCourses(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.enroll),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coursesList = data is List ? data : (data['courses'] ?? data['enrollments'] ?? data['data'] ?? []);
      return List<Map<String, dynamic>>.from(coursesList);
    } else {
      throw ApiException(
        'Failed to fetch enrolled courses',
        response.statusCode,
      );
    }
  }
}
