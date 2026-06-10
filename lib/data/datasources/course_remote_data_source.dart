import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';

class CourseRemoteDataSource {
  static String _errorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        // This backend puts detailed errors in 'errors' array
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) return errors.join('\n');
        final msg = decoded['message'];
        if (msg is List && msg.isNotEmpty) return msg.join('\n');
        if (msg is String && msg.isNotEmpty) return msg;
        final err = decoded['error'];
        if (err is String && err.isNotEmpty) return err;
        return fallback;
      }
    } catch (_) {}
    return body.isNotEmpty ? body : fallback;
  }

  Future<List<Map<String, dynamic>>> fetchCourses({
    Map<String, String>? filters,
  }) async {
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.courses).replace(
      queryParameters: filters == null || filters.isEmpty ? null : filters,
    );
    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coursesList = data is List
            ? data
            : (data['courses'] ?? data['data'] ?? []);
        return List<Map<String, dynamic>>.from(coursesList);
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ApiException('Failed to fetch courses', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error fetching courses: $e', 0);
    }
  }

  Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    final encoded = Uri.encodeQueryComponent(query);

    // Try dedicated search endpoint first
    try {
      final r1 = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.search}?q=$encoded&type=course'),
        headers: {'Content-Type': 'application/json'},
      );
      if (r1.statusCode == 200) {
        final data = jsonDecode(r1.body);
        final list = data is List
            ? data
            : (data['courses'] ?? data['results'] ?? data['data'] ?? []);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}

    // Fallback: filter via /courses?search= or ?title=
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.courses)
        .replace(queryParameters: {'search': query, 'title': query});
    final r2 = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (r2.statusCode == 200) {
      final data = jsonDecode(r2.body);
      final list = data is List ? data : (data['courses'] ?? data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw ApiException(
        _errorMessage(r2.body, 'Failed to search courses'), r2.statusCode);
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
    final url = ApiConstants.baseUrl + ApiConstants.courses;
    final requestBody = jsonEncode(courseData);
    debugPrint('------------ CREATE COURSE REQUEST ------------');
    debugPrint('------------ URL: $url');
    debugPrint('------------ BODY: $requestBody');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    debugPrint('------------ CREATE COURSE RESPONSE ------------');
    debugPrint('------------ STATUS: ${response.statusCode}');
    debugPrint('------------ RESPONSE BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = _errorMessage(response.body, 'Failed to create course');
    throw ApiException(body, response.statusCode);
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
    final body = _errorMessage(response.body, 'Failed to update course');
    throw ApiException(body, response.statusCode);
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
      final body = _errorMessage(response.body, 'Failed to delete course');
      throw ApiException(body, response.statusCode);
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
    final body = _errorMessage(response.body, 'Failed to publish course');
    throw ApiException(body, response.statusCode);
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
