import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';

class CourseRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchCourses() async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courses),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // If the API returns a map with a 'courses' key, extract it; otherwise, assume it's a list
      final coursesList = data is List ? data : (data['courses'] ?? []);
      return List<Map<String, dynamic>>.from(coursesList);
    } else {
      throw ApiException('Failed to fetch courses', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> fetchCourseById(String id) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courseById + id),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw NotFoundException('Course not found');
    } else {
      throw ApiException('Failed to fetch course', response.statusCode);
    }
  }
}
