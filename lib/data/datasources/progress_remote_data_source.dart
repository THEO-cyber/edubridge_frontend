import '../../core/http_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';

class ProgressRemoteDataSource {
  /// POST /enrollments/lessons/:lessonId/progress
  /// { watchedSeconds, totalSeconds, completed }
  Future<void> saveLessonProgress(
    String lessonId,
    int watchedSeconds,
    int totalSeconds,
    bool completed,
    String token,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.lessonProgress(lessonId)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'watchedSeconds': watchedSeconds,
            'totalSeconds': totalSeconds,
            'completed': completed,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to save progress', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> fetchProgress(
    String courseId,
    String token,
  ) async {
    final response = await http
        .get(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.enrollmentProgress(courseId)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException('Failed to fetch progress', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchEnrolledCourses(String token) async {
    final response = await http
        .get(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.enroll),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List
          ? data
          : (data['courses'] ?? data['enrollments'] ?? data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list as List);
    } else {
      throw ApiException('Failed to fetch enrolled courses', response.statusCode);
    }
  }
}
