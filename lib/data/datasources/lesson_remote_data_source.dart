import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class LessonRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchLessonsForCourse(
    String courseId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.lessons + '?courseId=$courseId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException('Failed to fetch lessons', response.statusCode);
    }
  }
}
