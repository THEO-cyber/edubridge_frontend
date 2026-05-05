import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';

class EnrollmentRemoteDataSource {
  Future<void> enrollInCourse(String courseId, String token) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.enroll),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'courseId': courseId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to enroll in course', response.statusCode);
    }
  }

  Future<void> unenrollFromCourse(String enrollmentId, String token) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.unenroll + enrollmentId),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to unenroll from course', response.statusCode);
    }
  }
}
