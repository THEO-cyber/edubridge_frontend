import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';

class CourseRemoteDataSource {
  static String _errorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) return errors.join('\n');
        final msg = decoded['message'];
        if (msg is List && msg.isNotEmpty) return msg.join('\n');
        if (msg is String && msg.isNotEmpty) return msg;
        final err = decoded['error'];
        if (err is String && err.isNotEmpty) return err;
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
      final response = await apiGet(uri,
          headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        return extractListOf(
            jsonDecode(response.body), ['courses', 'results', 'items']);
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ApiException('Failed to fetch courses', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    try {
      final r1 = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.search}?q=$encoded&type=course'),
        headers: {'Content-Type': 'application/json'},
      );
      if (r1.statusCode == 200) {
        return extractListOf(
            jsonDecode(r1.body), ['courses', 'results', 'items']);
      }
    } catch (_) {}

    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.courses)
        .replace(queryParameters: {'search': query, 'title': query});
    try {
      final r2 = await apiGet(uri, headers: {'Content-Type': 'application/json'});
      if (r2.statusCode == 200) {
        return extractListOf(
            jsonDecode(r2.body), ['courses', 'results', 'items']);
      }
      throw ApiException(_errorMessage(r2.body, 'Failed to search courses'), r2.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchCoursesByCategory(
    String category,
  ) async {
    try {
      final response = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.courses}?category=$category'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return extractListOf(jsonDecode(response.body), ['courses', 'items']);
      }
      throw ApiException('Failed to fetch courses by category', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<Map<String, dynamic>> fetchCourseById(String id) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.courseDetails(id)),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return extractObject(jsonDecode(response.body));
      }
      if (response.statusCode == 404) throw NotFoundException('Course not found');
      throw ApiException('Failed to fetch course', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<Map<String, dynamic>> fetchCourseBySlug(String slug) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.courseBySlug(slug)),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return extractObject(jsonDecode(response.body));
      }
      throw ApiException('Failed to fetch course by slug', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchInstructorCourses(
    String token,
  ) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.instructorMyCourses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return extractListOf(jsonDecode(response.body), ['courses', 'items']);
      }
      throw ApiException('Failed to fetch instructor courses', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
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

    try {
      final response = await apiPost(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );
      debugPrint('------------ STATUS: ${response.statusCode}');
      debugPrint('------------ RESPONSE: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final body = _errorMessage(response.body, 'Failed to create course');
      throw ApiException(body, response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<Map<String, dynamic>> updateCourse(
    String courseId,
    Map<String, dynamic> courseData,
    String token,
  ) async {
    try {
      final response = await apiPatch(
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
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<void> deleteCourse(String courseId, String token) async {
    try {
      final response = await apiDelete(
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
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<Map<String, dynamic>> publishCourse(
    String courseId,
    String token,
  ) async {
    try {
      final response = await apiPost(
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
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopRatedCourses() async {
    try {
      final response = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.courses}?sort=rating&limit=10'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coursesList = data is List ? data : (data['courses'] ?? []);
        return List<Map<String, dynamic>>.from(coursesList);
      }
      throw ApiException('Failed to fetch top rated courses', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }
}
