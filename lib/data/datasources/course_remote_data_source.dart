import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';

class CourseRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchCourses({
    Map<String, String>? filters,
  }) async {
    print('[DEBUG COURSE FETCH] Fetching courses...');
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.courses).replace(
      queryParameters: filters == null || filters.isEmpty ? null : filters,
    );
    print('[DEBUG COURSE FETCH] URL: $uri');
    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      print('[DEBUG COURSE FETCH] Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '[DEBUG COURSE FETCH] Raw response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        );
        // If the API returns a map with a 'courses' key, extract it; otherwise, assume it's a list
        final coursesList = data is List
            ? data
            : (data['courses'] ?? data['data'] ?? []);
        print('[DEBUG COURSE FETCH] Parsed ${coursesList.length} courses');
        return List<Map<String, dynamic>>.from(coursesList);
      } else if (response.statusCode == 404) {
        print(
          '[DEBUG COURSE FETCH] 404 - Endpoint not found, returning empty list',
        );
        return [];
      } else {
        print('[DEBUG COURSE FETCH] Failed with status ${response.statusCode}');
        throw ApiException('Failed to fetch courses', response.statusCode);
      }
    } catch (e) {
      print('[DEBUG COURSE FETCH] Exception: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error fetching courses: $e', 0);
    }
  }

  Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.search}?q=$query&type=course',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coursesList = data is List ? data : (data['courses'] ?? []);
      return List<Map<String, dynamic>>.from(coursesList);
    } else {
      throw ApiException('Failed to search courses', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchCoursesByCategory(
    String category,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.courses}?category=$category',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coursesList = data is List ? data : (data['courses'] ?? []);
      return List<Map<String, dynamic>>.from(coursesList);
    } else {
      throw ApiException(
        'Failed to fetch courses by category',
        response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> fetchCourseById(String id) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courseDetails(id)),
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

  Future<Map<String, dynamic>> fetchCourseBySlug(String slug) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courseBySlug(slug)),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to fetch course by slug', response.statusCode);
  }

  Future<List<Map<String, dynamic>>> fetchInstructorCourses(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.instructorMyCourses),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coursesList = data is List ? data : (data['courses'] ?? []);
      return List<Map<String, dynamic>>.from(coursesList);
    }
    throw ApiException(
      'Failed to fetch instructor courses',
      response.statusCode,
    );
  }

  Future<Map<String, dynamic>> createCourse(
    Map<String, dynamic> courseData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courses),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(courseData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to create course', response.statusCode);
  }

  Future<Map<String, dynamic>> updateCourse(
    String courseId,
    Map<String, dynamic> courseData,
    String token,
  ) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courseDetails(courseId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(courseData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to update course', response.statusCode);
  }

  Future<void> deleteCourse(String courseId, String token) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courseDetails(courseId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to delete course', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> publishCourse(
    String courseId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.publishCourse(courseId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to publish course', response.statusCode);
  }

  Future<List<Map<String, dynamic>>> fetchTopRatedCourses() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.courses}?sort=rating&limit=10',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coursesList = data is List ? data : (data['courses'] ?? []);
      return List<Map<String, dynamic>>.from(coursesList);
    } else {
      throw ApiException(
        'Failed to fetch top rated courses',
        response.statusCode,
      );
    }
  }
}
